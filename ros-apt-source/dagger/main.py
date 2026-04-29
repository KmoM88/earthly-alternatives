
import asyncio
import argparse
import sys
from typing import List

import dagger

supported_ros_platforms = [
    "ubuntu:focal",
    "ubuntu:jammy",
    "ubuntu:noble",
    "ubuntu:resolute",
    "debian:bookworm",
    "debian:buster",
    "debian:bullseye",
    "debian:trixie",
]

legacy_distros = ["ubuntu:focal", "debian:buster", "debian:bullseye"]

async def dpkgbuild(client: dagger.Client, distro: str) -> dagger.Container:
    """Sets up a Debian/Ubuntu container with debhelper and lintian to build Debian packages."""
    container = client.container().from_(distro)
    container = container.with_env_variable("DEBIAN_FRONTEND", "noninteractive")
    container = container.with_env_variable("TZ", "Etc/UTC")
    container = await add_archive_sources(container, distro)
    container = container.with_exec(["apt-get", "update"])

    if distro == "debian:buster":
        container = container.with_exec([
            "sh",
            "-c",
            'echo "deb http://archive.debian.org/debian-archive/debian buster-backports main" | tee /etc/apt/sources.list.d/backports.list > /dev/null',
        ])
        container = container.with_exec(["apt-get", "update"])
        container = container.with_exec([
            "sh",
            "-c",
            "apt-get install -y dwz/buster-backports debhelper/buster-backports>12 lintian/buster-backports",
        ])
    else:
        container = container.with_exec(["apt-get", "install", "-y", "debhelper", "lintian"])

    return container

async def add_archive_sources(container: dagger.Container, distro: str) -> dagger.Container:
    """Adds Debian archive sources for debian:buster."""
    if distro == "debian:buster":
        return container.with_exec([
            "sh",
            "-c",
            """echo "deb http://archive.debian.org/debian/ buster main non-free contrib
deb-src http://archive.debian.org/debian/ buster main non-free contrib
deb http://archive.debian.org/debian-security/ buster/updates main non-free contrib
deb-src http://archive.debian.org/debian-security/ buster/updates main non-free contrib" > /etc/apt/sources.list""",
        ])
    return container

async def build_package(
    client: dagger.Client, container: dagger.Container, package: str, target: str, data_dir: dagger.Directory
) -> dagger.Container:
    """Builds a Debian package."""
    container = container.with_directory("/tmp/pkg/data", data_dir)
    container = container.with_workdir("/tmp/pkg")
    container = container.with_exec(["cp", "-r", "data/debian", "."])
    container = container.with_exec(["cp", "-r", "data/keys", "."])
    container = container.with_exec([
        "sh",
        "-c",
        '. /etc/os-release && sed -i "s:~CODENAME:~$VERSION_CODENAME:" debian/changelog',
    ])
    container = container.with_exec([
        "sh",
        "-c",
        '. /etc/os-release && sed -i "s/\$CODENAME/$VERSION_CODENAME/" debian/changelog',
    ])
    container = container.with_exec(["cp", "data/README", "."])
    container = container.with_exec(["dpkg-buildpackage"])

    if target != "debian:bookworm":
        container = container.with_exec(["lintian"])

    container = container.with_exec([
        "sh",
        "-c",
        "cd .. && for f in *.deb; do sha256sum $f >> $f.sha256.txt; done",
    ])
    return container

async def build_ros_apt_source(client: dagger.Client, distro: str, data_dir: dagger.Directory):
    """Builds the ros-apt-source package for a given distribution."""
    pkg_build_container = await dpkgbuild(client, distro)
    
    build_container = pkg_build_container.with_exec(["mkdir", "/tmp/pkg"])
    build_container = build_container.with_workdir("/tmp/pkg")

    built_package = await build_package(client, build_container, "ros-apt-source", distro, data_dir)
    
    output_dir = client.directory()
    tmp_dir = built_package.directory("/tmp")
    for ext in ["txt", "dsc", "tar.xz", "deb"]:
        files = await tmp_dir.glob(f"*.{ext}")
        for f in files:
            output_dir = output_dir.with_file(
                f"{distro}/{f}", tmp_dir.file(f)
            )

    return output_dir


async def build_distros(client: dagger.Client, distros: List[str]):
    """Builds ros-apt-source for the given list of distributions."""
    data_dir = client.host().directory("ros-apt-source/data")
    
    build_tasks = [
        build_ros_apt_source(client, distro, data_dir)
        for distro in distros
    ]
    
    all_outputs = await asyncio.gather(*build_tasks)
    
    final_dir = client.directory()
    for output in all_outputs:
        final_dir = final_dir.with_directory(".", output)

    await final_dir.export("ros-apt-source/dagger/output")
    print("All packages built and exported to ros-apt-source/dagger/output")


async def main():
    """Builds and tests ros-apt-source debian packages using Dagger."""
    parser = argparse.ArgumentParser(
        description="Build and test ros-apt-source debian packages using Dagger."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    build_parser = subparsers.add_parser("build", help="Build debian packages.")
    build_parser.add_argument(
        "--distro",
        nargs="*",
        default=supported_ros_platforms,
        help="List of distros to build for. Defaults to all supported.",
    )

    test_parser = subparsers.add_parser("test", help="Test a debian package.")
    test_parser.add_argument("--distro", required=True, help="Distro to test on.")
    test_parser.add_argument("--repo", required=True, help="Repository to test.")
    test_parser.add_argument(
        "--version", required=False, default="", help="Version to test."
    )

    args = parser.parse_args()

    config = dagger.Config(log_output=sys.stdout)

    async with dagger.Connection(config) as client:
        if args.command == "build":
            await build_distros(client, args.distro)

if __name__ == "__main__":
    asyncio.run(main())
