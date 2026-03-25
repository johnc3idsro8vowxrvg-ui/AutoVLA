#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/environment.yml"
PREPROCESS_ENV_FILE="$REPO_ROOT/environment_nusc_preprocess.yml"
ENV_NAME="$(awk '/^name:/{print $2; exit}' "$ENV_FILE")"
PREPROCESS_ENV_NAME="$(awk '/^name:/{print $2; exit}' "$PREPROCESS_ENV_FILE")"
MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-$HOME/.local/share/mamba}"
AUTOVLA_INSTALL_NUSC_PREPROCESS="${AUTOVLA_INSTALL_NUSC_PREPROCESS:-0}"

log() {
  printf '[setup_cloud_environment] %s\n' "$*"
}

warn() {
  printf '[setup_cloud_environment] WARNING: %s\n' "$*" >&2
}

choose_micromamba_bin() {
  if [[ -n "${MICROMAMBA_BIN:-}" ]]; then
    printf '%s\n' "$MICROMAMBA_BIN"
    return
  fi

  if command -v micromamba >/dev/null 2>&1; then
    command -v micromamba
    return
  fi

  if [[ -x /usr/local/bin/micromamba ]]; then
    printf '%s\n' /usr/local/bin/micromamba
    return
  fi

  printf '%s\n' "$HOME/.local/bin/micromamba"
}

install_micromamba() {
  MICROMAMBA_BIN="$(choose_micromamba_bin)"
  if [[ -x "$MICROMAMBA_BIN" ]]; then
    log "Using existing micromamba at $MICROMAMBA_BIN"
    return
  fi

  local temp_dir archive_path bin_dir
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' EXIT
  archive_path="$temp_dir/micromamba.tar.bz2"
  bin_dir="$(dirname "$MICROMAMBA_BIN")"

  log "Installing micromamba to $MICROMAMBA_BIN"
  curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest -o "$archive_path"
  tar -xjf "$archive_path" -C "$temp_dir"

  if [[ "$MICROMAMBA_BIN" == /usr/local/bin/* ]] && command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    sudo mkdir -p "$bin_dir"
    sudo install -m 0755 "$temp_dir/bin/micromamba" "$MICROMAMBA_BIN"
  else
    mkdir -p "$bin_dir"
    install -m 0755 "$temp_dir/bin/micromamba" "$MICROMAMBA_BIN"
  fi

  trap - EXIT
  rm -rf "$temp_dir"
}

create_or_update_environment() {
  local env_file=$1
  local env_name=$2

  if [[ -d "$MAMBA_ROOT_PREFIX/envs/$env_name" ]]; then
    log "Updating micromamba environment: $env_name"
    "$MICROMAMBA_BIN" env update -y -n "$env_name" -f "$env_file"
  else
    log "Creating micromamba environment: $env_name"
    "$MICROMAMBA_BIN" create -y -f "$env_file"
  fi
}

install_editable_packages() {
  log "Installing AutoVLA editable package"
  "$MICROMAMBA_BIN" run -n "$ENV_NAME" python -m pip install -e "$REPO_ROOT" --no-warn-conflicts

  log "Installing navsim editable package"
  "$MICROMAMBA_BIN" run -n "$ENV_NAME" python -m pip install -e "$REPO_ROOT/navsim" --no-warn-conflicts
}

prepare_navsim_workspace() {
  local navsim_workspace
  navsim_workspace="${AUTOVLA_NAVSIM_WORKSPACE:-$HOME/navsim_workspace}"

  mkdir -p \
    "$navsim_workspace/exp" \
    "$navsim_workspace/dataset" \
    "$navsim_workspace/dataset/maps"
}

run_optional_installs() {
  log "Installing optional extras from install.sh"
  "$MICROMAMBA_BIN" run -n "$ENV_NAME" bash "$REPO_ROOT/install.sh"
}

verify_main_environment() {
  log "Verifying the main AutoVLA environment"
  "$MICROMAMBA_BIN" run -n "$ENV_NAME" python - <<'PY'
import torch
import transformers
import models
import navsim

print("torch", torch.__version__)
print("transformers", transformers.__version__)
print("models import ok")
print("navsim import ok")
PY
}

verify_preprocess_environment() {
  log "Verifying the nuScenes preprocessing environment"
  "$MICROMAMBA_BIN" run -n "$PREPROCESS_ENV_NAME" python - <<'PY'
import nuscenes
import pyquaternion

print("nuscenes import ok")
print("pyquaternion import ok")
PY
}

install_micromamba
export MAMBA_ROOT_PREFIX

create_or_update_environment "$ENV_FILE" "$ENV_NAME"
install_editable_packages
prepare_navsim_workspace
run_optional_installs
verify_main_environment

if [[ "$AUTOVLA_INSTALL_NUSC_PREPROCESS" == "1" ]]; then
  create_or_update_environment "$PREPROCESS_ENV_FILE" "$PREPROCESS_ENV_NAME"
  verify_preprocess_environment
else
  warn "Skipping $PREPROCESS_ENV_NAME. Re-run with AUTOVLA_INSTALL_NUSC_PREPROCESS=1 to install it."
fi

log "Environment setup complete. Activate it with: source .cursor/activate_autovla.sh"
