#!/bin/bash

: ${SERVICE:=sslh}
: ${CPU:=100}
: ${MEMORY:=100M}
: ${DISK:=5G}
: ${SSLH_PORT:=0.0.0.0:443}

set -e -u

if [ "$(whoami)" != 'root' ]; then
  echo 'this script must run as root.' >&2
  exit 1
fi

docker_build() {
  docker build --tag="${SERVICE}" .
}

docker_run() {
  local docker_flags=("${DOCKER_FLAGS[@]}")
  docker_flags+=(
      --memory="${MEMORY}" --cpu-shares="${CPU}"
      --publish="${SSLH_PORT}:443")
  docker run "${docker_flags[@]}" "${SERVICE}" "$@"
}

start() {
  if docker top "${SERVICE}" >/dev/null 2>/dev/null; then
    echo 'docker is already running.' >&2
  fi
  DOCKER_FLAGS=(--name="${SERVICE}" --hostname="${SERVICE}" --detach)
  docker_build
  docker_run "$@"
}

stop() {
  docker kill "${SERVICE}" >/dev/null || true
  docker rm "${SERVICE}" >/dev/null || true
}

install() {
  docker_build
}

command="$1"
shift
case "${command}" in
  'start') start "$@";;
  'stop') stop;;
  'install') install;;
  'uninstall') :;;
  *) echo "no such command: ${command}" >&2;;
esac
