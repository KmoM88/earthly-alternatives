# --- Base (dpkgbuild & ADD_ARCHIVE_SOURCES) ---
ARG DISTRO=debian:bookworm
FROM ${DISTRO} AS base
ARG DISTRO
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN if [ "${DISTRO}" = "debian:buster" ]; then \
      echo "deb http://archive.debian.org/debian/ buster main non-free contrib\ndeb-src http://archive.debian.org/debian/ buster main non-free contrib\ndeb http://archive.debian.org/debian-security/ buster/updates main non-free contrib\ndeb-src http://archive.debian.org/debian-security/ buster/updates main non-free contrib" > /etc/apt/sources.list; \
    fi

RUN apt-get update && \
    if [ "${DISTRO}" = "debian:buster" ]; then \
      echo "deb http://archive.debian.org/debian-archive/debian buster-backports main" | tee /etc/apt/sources.list.d/backports.list > /dev/null && \
      apt-get update && apt-get install -y dwz/buster-backports debhelper/buster-backports>12 lintian/buster-backports; \
    else \
      apt-get install -y debhelper lintian; \
    fi

# --- Build stage (BUILD_PACKAGE) ---
FROM base AS builder
ARG DISTRO
ARG PACKAGE=ros-apt-source
WORKDIR /tmp/pkg
COPY ../data/debian debian
COPY ../data/keys keys
RUN . /etc/os-release && sed -i "s:~CODENAME:~$VERSION_CODENAME:" debian/changelog && \
    sed -i "s:\$CODENAME:$VERSION_CODENAME:" debian/changelog
RUN dpkg-buildpackage
RUN if [ "${DISTRO}" != "debian:bookworm" ]; then lintian; fi
RUN cd .. && for f in *.deb; do sha256sum $f >> $f.sha256.txt; done

# Final stage (SAVE ARTIFACT)
FROM scratch AS artifacts
COPY --from=builder /tmp/*.txt /
COPY --from=builder /tmp/*.dsc /
COPY --from=builder /tmp/*.tar.xz /
COPY --from=builder /tmp/*.deb /

# --- Test stage (test-aptsource-pkg-install) ---
FROM ${DISTRO} AS test-aptsource
ARG DISTRO
ARG REPO=ros2
ARG VERSION=ros2
ENV DEBIAN_FRONTEND=noninteractive
COPY --from=artifacts /*.deb /tmp/
RUN apt-get update && apt-get install -y /tmp/${REPO}-apt-source*.deb
RUN cat /usr/share/ros-apt-source/${REPO}.sources
RUN if [ -f /usr/share/ros-apt-source/${REPO}.sources ] && \
      [ -e /usr/share/ros-apt-source/${REPO}.sources ] && \
      [ -s /usr/share/ros-apt-source/${REPO}.sources ] \
      ; then exit 0; else exit 1; fi;
RUN if [ -f /usr/share/keyrings/${VERSION}-archive-keyring.gpg ] && \
      [ -e /usr/share/keyrings/${VERSION}-archive-keyring.gpg ] && \
      [ -s /usr/share/keyrings/${VERSION}-archive-keyring.gpg ] \
      ; then exit 0; else exit 1; fi; 