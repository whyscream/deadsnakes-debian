#!/bin/sh

set -e

is_inside() {
  if test -z "$INSIDE_BUILD_CONTAINER"; then
    echo ">>> Running outside container"
    return 1
  else
    echo ">>> Running inside container"
    return 0
  fi
}

start_docker_container() {
  if is_inside; then return 0; fi

  docker pull debian:buster
  docker run \
    -e INSIDE_BUILD_CONTAINER=yes \
    -v $(pwd):/deadsnakes \
    --rm \
    debian:buster \
    /deadsnakes/build.sh
}

build_python() {
  if ! is_inside; then return 0; fi

  apt-get -y -qq update
  apt-get -y -qq install devscripts git git-buildpackage
  git clone https://github.com/deadsnakes/python3.11.git /usr/src/python
  cd /usr/src/python
  git checkout 'debian/3.11.0-1+jammy1'
  apt-get install -qq quilt sharutils libreadline-dev libncursesw5-dev zlib1g-dev libbz2-dev liblzma-dev libgdbm-dev libdb-dev tk-dev blt-dev libssl-dev libexpat1-dev libbluetooth-dev locales libsqlite3-dev libffi-dev time net-tools xvfb python3-sphinx texinfo
  gbp buildpackage --git-ignore-branch || true
}

copy_packages_to_host() {
  if ! is_inside; then return 0; fi

  cp -v ../*.deb /deadsnakes/
}

main() {
  start_docker_container
  build_python
  copy_packages_to_host
}

main
