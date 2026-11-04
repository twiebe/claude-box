#!/usr/bin/env bash
# Puts this checkout's cb on PATH and its zsh completion on fpath, as symlinks
# into the checkout, so a `git pull` here is the whole update.
#
# Idempotent: a link that already points here is left alone. A link that points
# elsewhere - an older checkout, the stow link from dotfiles - is replaced,
# since a symlink holds nothing that could be lost. A regular file in the way is
# refused rather than overwritten.
#
# Builds nothing: cb builds a missing image on its first run.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
BIN_DIR="${CB_BIN_DIR:-${HOME}/.local/bin}"
COMPLETION_DIR="${CB_COMPLETION_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/zsh/site-functions}"

link() {
  local source="$1" target="$2"

  if [[ -L "${target}" && "$(readlink "${target}")" == "${source}" ]]; then
    echo "ok       ${target}"
    return
  fi
  if [[ -e "${target}" && ! -L "${target}" ]]; then
    echo "refusing ${target}: exists and is not a symlink" >&2
    return 1
  fi

  mkdir -p "$(dirname "${target}")"
  ln -sfn "${source}" "${target}"
  echo "linked   ${target} -> ${source}"
}

link "${SRC_DIR}/bin/cb" "${BIN_DIR}/cb"
link "${SRC_DIR}/completions/_cb" "${COMPLETION_DIR}/_cb"

case ":${PATH}:" in
  *":${BIN_DIR}:"*) ;;
  *) echo "note: ${BIN_DIR} is not on PATH" ;;
esac
