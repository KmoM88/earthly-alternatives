variable "DISTRIBUTION_ROS2" {
  default = "ubuntu:jammy,ubuntu:noble,ubuntu:resolute,debian:bookworm,debian:bullseye,debian:trixie"
}

variable "REPO_ROS2" {
  default = "ros2,ros2-testing"
}

variable "DISTRIBUTION_ROS" {
  default = "ubuntu:focal,debian:buster"
}

variable "REPO_ROS" {
  default = "ros,ros-testing"
}

group "default" {
  targets = ["test-aptsource-ros2", "test-aptsource-ros"]
}

group "build-all" {
  targets = ["build-ros2", "build-ros"]
}

target "_common" {
  context = "ros-apt-source"
  dockerfile = "docker-bake/Dockerfile"
}

target "build-ros2" {
  inherits = ["_common"]
  name = "build-${replace(distro, ":", "-")}"
  matrix = {
    distro = split(",", DISTRIBUTION_ROS2)
  }
  args = {
    DISTRO = "${distro}"
  }
  target = "artifacts"
  output = ["./ros-apt-source/docker-bake/output/${distro}"]
}

target "test-aptsource-ros2" {
  inherits = ["_common"]
  name = "test-${replace(distro, ":", "-")}-${repo}"
  matrix = {
    distro = split(",", DISTRIBUTION_ROS2)
    repo   = split(",", REPO_ROS2)
  }
  args = {
    DISTRO = "${distro}"
    REPO   = "${repo}"
    VERSION = "ros2"
    LEGACY_DISTROS = "${DISTRIBUTION_ROS}"
  }
  target = "test-aptsource"
}

target "build-ros" {
  inherits = ["_common"]
  name = "build-${replace(distro, ":", "-")}"
  matrix = {
    distro = split(",", DISTRIBUTION_ROS)
  }
  args = {
    DISTRO = "${distro}"
  }
  target = "artifacts"
  output = ["./ros-apt-source/docker-bake/output/${distro}"]
}

target "test-aptsource-ros" {
  inherits = ["_common"]
  name = "test-${replace(distro, ":", "-")}-${repo}"
  matrix = {
    distro = split(",", DISTRIBUTION_ROS)
    repo   = split(",", REPO_ROS)
  }
  args = {
    DISTRO = "${distro}"
    REPO   = "${repo}"
    VERSION = "ros"
    LEGACY_DISTROS = "ubuntu:focal,debian:buster,debian:bullseye"
  }
  target = "test-aptsource"
}