#!/usr/bin/env bash
# Shared helpers for loca download scripts.
# These scripts are intentionally cautious: they default to dry-run / prompt mode.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS_JSON="${REPO_ROOT}/models.json"
TIERS_JSON="${REPO_ROOT}/tiers.json"

_exists() { command -v "$1" >/dev/null 2>&1; }

_model_info() {
    python3 - "$MODELS_JSON" "$1" "$2" <<'PY'
import json, sys
path, mid, key = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    data = json.load(f)
for m in data["models"]:
    if m["id"] == mid:
        print(m.get(key, ""))
        sys.exit(0)
sys.exit(1)
PY
}

_estimate_vram() {
    python3 - "$MODELS_JSON" "$1" <<'PY'
import json, sys
path, mid = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
for m in data["models"]:
    if m["id"] == mid:
        if m.get("is_moe"):
            print(f"~{m['vram_q4_all_gb']}GB total / ~{m['vram_q4_active_gb']}GB active-only")
        else:
            print(f"~{m['vram_q4_all_gb']}GB Q4")
        sys.exit(0)
print("unknown")
PY
}

_is_gated() {
    [[ "$(_model_info "$1" gated)" == "True" ]]
}

_ensure_hf_cli() {
    if ! _exists huggingface-cli; then
        echo "Missing: huggingface-cli" >&2
        echo "Run: ./scripts/setup.sh" >&2
        exit 1
    fi
}

_prompt_yes_no() {
    local prompt="$1 (y/N) "
    if [[ "${LOCAL_DOWNLOAD_YES:-}" == "1" ]]; then
        return 0
    fi
    read -r -p "$prompt" ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

hf_download() {
    local model_id="$1"
    local local_dir="$2"
    local dry_run="${3:-0}"

    local name
    name="$(basename "$model_id")"

    echo ""
    echo "Model:        $model_id"
    echo "Local path:   $local_dir"
    echo "Est. VRAM:    $(_estimate_vram "$model_id")"
    echo "License:      $(_model_info "$model_id" license)"
    if _is_gated "$model_id"; then
        echo "Gated:        YES — accept the license on Hugging Face and set HF_TOKEN"
    fi

    if [[ "$dry_run" == "1" ]]; then
        echo "Dry-run command:"
        echo "  HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download \"$model_id\" --local-dir \"$local_dir\" --local-dir-use-symlinks False"
        return 0
    fi

    _ensure_hf_cli

    if ! _prompt_yes_no "Download $name?"; then
        echo "Skipped $name"
        return 0
    fi

    mkdir -p "$local_dir"
    HF_HUB_ENABLE_HF_TRANSFER=1 huggingface-cli download "$model_id" \
        --local-dir "$local_dir" \
        --local-dir-use-symlinks False
}
