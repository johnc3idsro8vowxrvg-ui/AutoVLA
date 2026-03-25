#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[install.sh] %s\n' "$*"
}

warn() {
  printf '[install.sh] WARNING: %s\n' "$*" >&2
}

run_optional_install() {
  local description=$1
  shift

  log "Installing ${description}"
  if ! "$@"; then
    warn "Skipping ${description}; continuing without it."
  fi
}

log "Ensuring typing_extensions is up to date"
python -m pip install --upgrade typing_extensions

run_optional_install "flash-attn==2.7.4.post1" \
  python -m pip install flash-attn==2.7.4.post1

run_optional_install "waymo-open-dataset-tf-2-12-0==1.6.7" \
  python -m pip install waymo-open-dataset-tf-2-12-0==1.6.7

run_optional_install "autoawq==0.2.8 --no-deps" \
  python -m pip install autoawq==0.2.8 --no-deps