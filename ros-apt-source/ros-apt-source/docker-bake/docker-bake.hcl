variable "distro" {
  default = "ubuntu:focal"
}

group "default" {
  targets = ["test"]
}

target "build" {
  dockerfile = "Dockerfile"
  target = "build"
  args = {
    distro = "${distro}"
  }
  tags = ["ros-apt-source-builder"]
}

target "test" {
  dockerfile = "Dockerfile"
  target = "test"
  args = {
    distro = "${distro}"
  }
  depends-on = ["build"]
}
