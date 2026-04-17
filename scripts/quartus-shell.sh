#!/usr/bin/env bash
#
# quartus-shell.sh — interactive launcher for a Quartus container target
#
# Invoked by a per-target wrapper.  The wrapper exports TARGET_* env vars
# then execs this script.  This script drops the user into an interactive
# bash inside the container, or launches the Quartus GUI if --quartus is
# passed as the first argument.
#
# Required env vars:
#   TARGET_NAME            registry key (for prompt/hostname)
#   TARGET_IMAGE           container image tag
#   TARGET_INSTALL_ROOT    Quartus install root inside the container
#   TARGET_CONTAINER_PATH  PATH to set inside the container
#   LICENSE_DIR            host dir with quartus_license.dat and questa_license.dat
#   CONTAINER_RUNTIME      podman|docker

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(pwd)}"
DATA_ROOT="${DATA_ROOT:-${REPO_ROOT}/.quartus}"
ROOT_MOUNT="${ROOT_MOUNT:-${DATA_ROOT}/root}"
SLL_MOUNT="${SLL_MOUNT:-${REPO_ROOT}}"
XHOST_USERS="${XHOST_USERS:-root,${USER:-$(id -un)}}"
XAUTH_SRC="${XAUTHORITY:-${HOME}/.Xauthority}"
QUARTUS_HOSTNAME="${QUARTUS_HOSTNAME:-svunit-${TARGET_NAME}}"
GUI_MODE=0

mkdir -p "${ROOT_MOUNT}"

if [ "${1:-}" = "--quartus" ]; then
  GUI_MODE=1
fi

DISPLAY_ENV="${DISPLAY:-}"
if [ -z "${DISPLAY_ENV}" ] && [ -S /tmp/.X11-unix/X0 ]; then
  DISPLAY_ENV=":0"
fi

if [ "${GUI_MODE}" = "1" ] && [ -z "${DISPLAY_ENV}" ]; then
  echo "DISPLAY is not set. Export DISPLAY before launching the Quartus GUI." >&2
  exit 1
fi

if [ ! -f "${LICENSE_DIR}/quartus_license.dat" ] || [ ! -f "${LICENSE_DIR}/questa_license.dat" ]; then
  echo "Quartus or Questa license file missing in ${LICENSE_DIR}." >&2
  echo "Set LICENSE_DIR to the directory containing quartus_license.dat and questa_license.dat." >&2
  exit 1
fi

if ! "${CONTAINER_RUNTIME}" image exists "${TARGET_IMAGE}" >/dev/null 2>&1; then
  echo "Container image ${TARGET_IMAGE} not found." >&2
  echo "Build it via the upstream Quartus Pro podman flake for this target first." >&2
  exit 1
fi

CONTAINER_ENV=(
  -e LM_LICENSE_FILE=/opt/quartus_license.dat:/opt/questa_license.dat
  -e QUARTUS_PATH="${TARGET_INSTALL_ROOT}"
  -e QUARTUS_ROOTDIR="${TARGET_INSTALL_ROOT}/quartus"
  -e SOPC_KIT_NIOS2="${TARGET_INSTALL_ROOT}/nios2eds"
  -e QSYS_ROOTDIR="${TARGET_INSTALL_ROOT}/qsys/bin"
  -e QUARTUS_64BIT=1
  -e LANG=C.UTF-8
  -e LC_ALL=C.UTF-8
  -e PATH="${TARGET_CONTAINER_PATH}"
)

X11_SOCKET_MOUNT=()
if [ -n "${DISPLAY_ENV}" ]; then
  CONTAINER_ENV+=(-e DISPLAY="${DISPLAY_ENV}" -e QT_X11_NO_MITSHM=1)
  if [[ "${DISPLAY_ENV}" == :* ]]; then
    X11_SOCKET_MOUNT=(-v /tmp/.X11-unix:/tmp/.X11-unix:rw)
    IFS=',' read -r -a _xhost_users <<< "${XHOST_USERS}"
    for _u in "${_xhost_users[@]}"; do
      DISPLAY="${DISPLAY_ENV}" xhost +si:localuser:"${_u}" >/dev/null
    done
  fi
fi

XAUTH_MOUNT=()
XAUTH_ENV=()
if [ -f "${XAUTH_SRC}" ]; then
  XAUTH_MOUNT=(-v "${XAUTH_SRC}:/tmp/.Xauthority:ro")
  XAUTH_ENV=(-e XAUTHORITY=/tmp/.Xauthority)
fi

CONTAINER_TTY_ARGS=()
if [ -t 0 ] && [ -t 1 ]; then
  CONTAINER_TTY_ARGS=(-it)
fi

DEFAULT_CMD=(/bin/bash)
if [ "${GUI_MODE}" = "1" ]; then
  shift
  DEFAULT_CMD=("${TARGET_INSTALL_ROOT}/quartus/bin/quartus" "$@")
elif [ "$#" -gt 0 ]; then
  DEFAULT_CMD=("$@")
fi

exec "${CONTAINER_RUNTIME}" run --rm \
  --hostname="${QUARTUS_HOSTNAME}" \
  --net=host \
  --cap-add=NET_ADMIN \
  "${CONTAINER_ENV[@]}" \
  "${X11_SOCKET_MOUNT[@]}" \
  "${XAUTH_ENV[@]}" \
  -v "${ROOT_MOUNT}:/root" \
  -v "${SLL_MOUNT}:/sll" \
  "${XAUTH_MOUNT[@]}" \
  -v "${LICENSE_DIR}/quartus_license.dat:/opt/quartus_license.dat:ro" \
  -v "${LICENSE_DIR}/questa_license.dat:/opt/questa_license.dat:ro" \
  "${CONTAINER_TTY_ARGS[@]}" \
  "${TARGET_IMAGE}" "${DEFAULT_CMD[@]}"
