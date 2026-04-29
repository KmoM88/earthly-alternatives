# --- Base (dpkgbuild & ADD_ARCHIVE_SOURCES) ---
ARG DISTRO=debian:bookworm
FROM ${DISTRO} AS base
ARG DISTRO
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN if [ "${DISTRO}" = "debian:buster" ]; then \
      echo "deb http://archive.debian.org/debian/ buster main non-free contrib\ndeb-src http://archive.debian.org/debian/ buster main non-free contrib\ndeb http://archive.debian.org/debian-security/ buster/updates main non-free contrib\ndeb-src http://archive.debian.org/debian-security/ buster/updates main non-free contrib" > /etc/apt/sources.list; \
    fi

RUN apt-get update
# Debian buster has an older version of debhelper but the backports archive has a compatible one
# Use backports version to avoid updating package logic for legacy version.
RUN if [ "${DISTRO}" = "debian:buster" ]; then \
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
COPY ../data/keys keys
COPY ../data/debian debian
RUN . /etc/os-release && sed -i "s:~CODENAME:~$VERSION_CODENAME:" debian/changelog
RUN . /etc/os-release && sed -i "s:\$CODENAME:$VERSION_CODENAME:" debian/changelog
RUN dpkg-buildpackage
# Lintian on bookworm has an issue resolved in a newer version that has not been backported to bookworm-backports
# Don't run lintian on bookworm version of the package since it fails 
# Issue: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1033894
RUN if [ "${DISTRO}" != "debian:bookworm" ]; then lintian; fi
RUN cd .. && for f in *.deb; do sha256sum $f >> $f.sha256.txt; done

# Final stage (SAVE ARTIFACT)
FROM scratch AS artifacts
COPY --from=builder /tmp/*.txt /
COPY --from=builder /tmp/*.dsc /
COPY --from=builder /tmp/*.tar.xz /
COPY --from=builder /tmp/*.deb /

# --- Test stage (test-aptsource-pkg-install) ---
FROM base AS test-aptsource
ARG DISTRO
ARG REPO=ros2
ARG VERSION=ros2
ARG LEGACY_DISTROS=ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive
COPY --from=artifacts /*.deb /tmp/
RUN apt-get update && apt-get install -y /tmp/${REPO}-apt-source*.deb
RUN cat /usr/share/ros-apt-source/${REPO}.sources
RUN if [ -f /usr/share/ros-apt-source/${REPO}.sources ] && \
      [ -e /usr/share/ros-apt-source/${REPO}.sources ] && \
      [ -s /usr/share/ros-apt-source/${REPO}.sources ] \
      ; then exit 0; else exit 1; fi;
  RUN case "$LEGACY_DISTROS" in \
    *"$DISTRO"*) \
      echo "Distro legacy detected: $DISTRO"; \
      if grep 'BEGIN PGP PUBLIC KEY BLOCK' /usr/share/ros-apt-source/${repo}.sources > /dev/null; then \
        exit 0; \
      else \
        exit 1; \
      fi \
      ;; \
    *) \
      echo "Distro moderna: $distro. Saltando check."; \
      exit 0; \
      ;; \
RUN if [ -f /usr/share/keyrings/${VERSION}-archive-keyring.gpg ] && \
      [ -e /usr/share/keyrings/${VERSION}-archive-keyring.gpg ] && \
      [ -s /usr/share/keyrings/${VERSION}-archive-keyring.gpg ] \
      ; then exit 0; else exit 1; fi; 