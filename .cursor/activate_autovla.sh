#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/environment.yml"
ENV_NAME="$(awk '/^name:/{print $2; exit}' "$ENV_FILE")"
MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-$HOME/.local/share/mamba}"
MICROMAMBA_BIN="${MICROMAMBA_BIN:-$HOME/.local/bin/micromamba}"

if [[ ! -x "$MICROMAMBA_BIN" ]] && command -v micromamba >/dev/null 2>&1; then
  MICROMAMBA_BIN="$(command -v micromamba)"
fi

if [[ ! -x "$MICROMAMBA_BIN" ]]; then
  echo "micromamba is not installed. Run: bash .cursor/setup_cloud_environment.sh" >&2
  return 1 2>/dev/null || exit 1
fi

export MAMBA_ROOT_PREFIX
eval "$("$MICROMAMBA_BIN" shell hook -s bash)"
micromamba activate "$ENV_NAME"

export NUPLAN_MAP_VERSION="${NUPLAN_MAP_VERSION:-nuplan-maps-v1.0}"
export AUTOVLA_NAVSIM_WORKSPACE="${AUTOVLA_NAVSIM_WORKSPACE:-$HOME/navsim_workspace}"
export NUPLAN_MAPS_ROOT="${NUPLAN_MAPS_ROOT:-$AUTOVLA_NAVSIM_WORKSPACE/dataset/maps}"
export NAVSIM_EXP_ROOT="${NAVSIM_EXP_ROOT:-$AUTOVLA_NAVSIM_WORKSPACE/exp}"
export NAVSIM_DEVKIT_ROOT="${NAVSIM_DEVKIT_ROOT:-$REPO_ROOT/navsim}"
export OPENSCENE_DATA_ROOT="${OPENSCENE_DATA_ROOT:-$AUTOVLA_NAVSIM_WORKSPACE/dataset}"

mkdir -p "$NAVSIM_EXP_ROOT" "$OPENSCENE_DATA_ROOT" "$NUPLAN_MAPS_ROOT"

echo "Activated $ENV_NAME"
