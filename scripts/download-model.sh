#!/usr/bin/env bash
# Download a single model by its Hugging Face id.
#
#   ./scripts/download-model.sh <model-id> [local-dir] [--dry-run|--yes]
#
# Examples:
#   ./scripts/download-model.sh zai-org/GLM-5.1
#   ./scripts/download-model.sh Qwen/Qwen3-32B ./my-qwen --dry-run
#   ./scripts/download-model.sh meta-llama/Llama-4-Scout-17B-16E-Instruct --yes

set -euo pipefail

source "$(dirname "$0")/common.sh"

DRY_RUN=0
YES=0
MODEL_ID=""
LOCAL_DIR=""

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --yes) LOCAL_DOWNLOAD_YES=1 ;;
        *)
            if [[ -z "$MODEL_ID" ]]; then
                MODEL_ID="$arg"
            elif [[ -z "$LOCAL_DIR" ]]; then
                LOCAL_DIR="$arg"
            else
                echo "Unknown argument: $arg" >&2
                exit 1
            fi
            ;;
    esac
done

if [[ -z "$MODEL_ID" ]]; then
    echo "Usage: $0 <model-id> [local-dir] [--dry-run|--yes]" >&2
    exit 1
fi

if [[ -z "$LOCAL_DIR" ]]; then
    LOCAL_DIR="${REPO_ROOT}/models/$(basename "$MODEL_ID")"
fi

if [[ "$DRY_RUN" == "1" ]]; then
    hf_download "$MODEL_ID" "$LOCAL_DIR" 1
else
    hf_download "$MODEL_ID" "$LOCAL_DIR" 0
fi
