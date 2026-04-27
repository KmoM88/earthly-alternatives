variable "DISTRIBUTION" {
  default = "ubuntu:focal,ubuntu:jammy,ubuntu:noble,debian:bookworm,debian:buster,debian:bullseye"
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
    distro = split(",", DISTRIBUTION)
  }
  args = {
    DISTRO = "${distro}"
  }
  target = "artifacts"
  output = ["./output/${distro}"]
}

target "test-install" {
  inherits = ["_common"]
  args = {
    DISTRO = "ubuntu:noble"
    REPO = "ros2"
  }
  target = "test-install"
}