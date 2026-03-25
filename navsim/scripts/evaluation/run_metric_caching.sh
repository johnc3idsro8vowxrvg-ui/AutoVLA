#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

export NAVSIM_DEVKIT_ROOT="${NAVSIM_DEVKIT_ROOT:-$REPO_ROOT/navsim}"
export PYTHONPATH="${NAVSIM_DEVKIT_ROOT}:${PYTHONPATH:-}"
export AUTOVLA_NAVSIM_WORKSPACE="${AUTOVLA_NAVSIM_WORKSPACE:-$HOME/navsim_workspace}"
export NAVSIM_EXP_ROOT="${NAVSIM_EXP_ROOT:-$AUTOVLA_NAVSIM_WORKSPACE/exp}"
export OPENSCENE_DATA_ROOT="${OPENSCENE_DATA_ROOT:-$AUTOVLA_NAVSIM_WORKSPACE/dataset}"
export NUPLAN_MAPS_ROOT="${NUPLAN_MAPS_ROOT:-$AUTOVLA_NAVSIM_WORKSPACE/dataset/maps}"

TRAIN_TEST_SPLIT="${TRAIN_TEST_SPLIT:-warmup_test_e2e}"
CACHE_PATH="${CACHE_PATH:-$NAVSIM_EXP_ROOT/metric_cache/${TRAIN_TEST_SPLIT}}"

mkdir -p "$CACHE_PATH" "$NAVSIM_EXP_ROOT" "$OPENSCENE_DATA_ROOT" "$NUPLAN_MAPS_ROOT"

python "$NAVSIM_DEVKIT_ROOT/navsim/planning/script/run_metric_caching.py" \
  train_test_split="$TRAIN_TEST_SPLIT" \
  cache.cache_path="$CACHE_PATH"