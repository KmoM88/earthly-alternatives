variable "SUPPORTED_ROS_PLATFORMS" {
  default = [ubuntu:focal,ubuntu:jammy,ubuntu:noble,ubuntu:resolute,debian:bookworm,debian:bullseye,debian:trixie]
}

group "default" {
  targets = ["build"]
}

target "_common" {
  context = "."
  dockerfile = "Dockerfile"
}

target "build" {
  inherits = ["_common"]
  name = "build-${replace(distro, ":", "-")}"
  matrix = {
    distro = SUPPORTED_ROS_PLATFORMS
  }
  args = {
    DISTRO = "${distro}"
  }
  target = "artifacts"
  output = ["./output/${replace(distro, ":", "-")}"]
}

target "test-install" {
  inherits = ["_common"]
  args = {
    DISTRO = "ubuntu:noble"
    REPO = "ros2"
  }
  target = "test-install"
}