#!/usr/bin/env bash
# Undoes install.sh: removes the links it made, and only those that still point
# into this checkout, so it cannot take out a link another checkout owns.
#
# Leaves what cb itself created alone - images, volumes, remembered settings -
# and lists it instead. Those outlive a reinstall on purpose.
#
# Idempotent: a link that is already gone is reported and skipped.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
BIN_DIR="${CB_BIN_DIR:-${HOME}/.local/bin}"
COMPLETION_DIR="${CB_COMPLETION_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/zsh/site-functions}"

unlink_ours() {
  local source="$1" target="$2"

  if [[ ! -L "${target}" ]]; then
    echo "absent   ${target}"
  elif [[ "$(readlink "${target}")" != "${source}" ]]; then
    echo "skipped  ${target}: points to $(readlink "${target}"), not here"
  else
    rm "${target}"
    echo "removed  ${target}"
  fi
}

unlink_ours "${SRC_DIR}/bin/cb" "${BIN_DIR}/cb"
unlink_ours "${SRC_DIR}/completions/_cb" "${COMPLETION_DIR}/_cb"

cat <<HINT

left in place, remove by hand if wanted:
  images:   docker image rm claude-box:latest claude-box:base
  volumes:  docker volume ls --filter name=cb-
  settings: ${XDG_STATE_HOME:-${HOME}/.local/state}/claude-box
  checkout: ${SRC_DIR}
HINT
