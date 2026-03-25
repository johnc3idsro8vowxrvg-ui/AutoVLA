#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

export NAVSIM_DEVKIT_ROOT="${NAVSIM_DEVKIT_ROOT:-$REPO_ROOT/navsim}"
export PYTHONPATH="$NAVSIM_DEVKIT_ROOT:${PYTHONPATH:-}"

TRAIN_TEST_SPLIT="${TRAIN_TEST_SPLIT:-navtest}"
CHECKPOINT="${CHECKPOINT:-}"
CACHE_PATH="${CACHE_PATH:-$NAVSIM_EXP_ROOT/metric_cache}"
JSON_DATA_PATH="${JSON_DATA_PATH:-}"
SENSOR_DATA_PATH="${SENSOR_DATA_PATH:-}"
CONFIG_PATH="${CONFIG_PATH:-$REPO_ROOT/config/training/qwen2.5-vl-3B-nuplan-grpo-cot.yaml}"
LORA="${LORA:-false}"
CUDA_VISIBLE_DEVICES_VALUE="${CUDA_VISIBLE_DEVICES:-}"

if [[ -z "$CHECKPOINT" ]]; then
  echo "CHECKPOINT is required. Export it before running this script." >&2
  exit 1
fi

if [[ -z "$JSON_DATA_PATH" ]]; then
  echo "JSON_DATA_PATH is required. Export it before running this script." >&2
  exit 1
fi

if [[ -z "$SENSOR_DATA_PATH" ]]; then
  echo "SENSOR_DATA_PATH is required. Export it before running this script." >&2
  exit 1
fi

if [[ -z "${NAVSIM_EXP_ROOT:-}" ]]; then
  echo "NAVSIM_EXP_ROOT is required. Export it before running this script." >&2
  exit 1
fi

if [[ -n "$CUDA_VISIBLE_DEVICES_VALUE" ]]; then
  export CUDA_VISIBLE_DEVICES="$CUDA_VISIBLE_DEVICES_VALUE"
fi

python "$NAVSIM_DEVKIT_ROOT/navsim/planning/script/run_pdm_score_cot.py" \
  train_test_split="$TRAIN_TEST_SPLIT" \
  agent=autovla_agent \
  +agent.config_path="$CONFIG_PATH" \
  +agent.checkpoint_path="$CHECKPOINT" \
  +agent.sensor_data_path="$SENSOR_DATA_PATH" \
  +agent.lora_conf.use_lora="$LORA" \
  metric_cache_path="$CACHE_PATH" \
  json_data_path="$JSON_DATA_PATH" \
  experiment_name=autovla_agent