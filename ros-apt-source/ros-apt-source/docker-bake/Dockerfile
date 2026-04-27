# syntax=docker/dockerfile:1

# Build stage
FROM ${distro} as build
ARG distro
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN if [ "${distro}" = "debian:buster" ]; then 
       echo "deb http://archive.debian.org/debian/ buster main non-free contrib
deb-src http://archive.debian.org/debian/ buster main non-free contrib
deb http://archive.debian.org/debian-security/ buster/updates main non-free contrib
deb-src http://archive.debian.org/debian-security/ buster/updates main non-free contrib" > /etc/apt/sources.list; 
    fi;

RUN apt-get update && 
    if [ "${distro}" = "debian:buster" ]; then 
      echo "deb http://archive.debian.org/debian-archive/debian buster-backports main" | tee /etc/apt/sources.list.d/backports.list > /dev/null && 
      apt-get update && apt-get install -y dwz/buster-backports debhelper/buster-backports>12 lintian/buster-backports; 
    else 
      apt-get install -y debhelper lintian; 
    fi;

WORKDIR /tmp/pkg
COPY keys keys
COPY debian debian
COPY README .

RUN . /etc/os-release && sed -i "s:~CODENAME:~$VERSION_CODENAME:" debian/changelog && 
    sed -i "s:\$CODENAME:$VERSION_CODENAME:" debian/changelog

RUN dpkg-buildpackage

RUN if [ "${distro}" != "debian:bookworm" ]; then 
      lintian ; 
    fi;
RUN cd .. && for f in *.deb; do sha256sum $f >> $f.sha256.txt; done

# Test stage
FROM ${distro} as test
ARG distro
ARG repo=ros2
ARG version=ros2
ARG legacy_distros="ubuntu:focal debian:buster debian:bullseye"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN if [ "${distro}" = "debian:buster" ]; then 
       echo "deb http://archive.debian.org/debian/ buster main non-free contrib
deb-src http://archive.debian.org/debian/ buster main non-free contrib
deb http://archive.debian.org/debian-security/ buster/updates main non-free contrib
deb-src http://archive.debian.org/debian-security/ buster/updates main non-free contrib" > /etc/apt/sources.list; 
    fi;

COPY --from=ros-apt-source-builder /tmp/pkg/../*.deb /tmp/
RUN apt-get update && apt-get install -y /tmp/*.deb

RUN if [ -f /usr/share/ros-apt-source/${repo}.sources ] && 
          [ -e /usr/share/ros-apt-source/${repo}.sources ] && 
          [ -s /usr/share/ros-apt-source/${repo}.sources 
  ]; then exit 0; else exit 1; fi;
RUN  if [ "$legacy_distros" == *"$distro"* ]; then 
         if grep 'BEGIN PGP PUBLIC KEY BLOCK' /usr/share/ros-apt-source/${repo}.sources > /dev/null ; then 
            exit 0; 
            else exit 1; 
            fi; 
        fi;
RUN if  [ -f /usr/share/keyrings/${version}-archive-keyring.gpg ] && 
          [ -e /usr/share/keyrings/${version}-archive-keyring.gpg ] && 
          [ -s /usr/share/keyrings/${version}-archive-keyring.gpg 
  ]; then exit 0; else exit 1; fi;
RUN if  [ -h /etc/apt/sources.list.d/${version}.sources ]; then exit 0; else exit 1; fi;
