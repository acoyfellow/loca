#!/usr/bin/env bash
# Download the recommended models for a hardware tier.
#
#   ./scripts/download-tier.sh <tier> [--dry-run|--yes]
#
# Tiers: laptop, single-gpu-24-48, single-gpu-80, server, cluster
#
# Default behavior: show the list and prompt before each download.
# Use --dry-run to only print commands. Use --yes to skip prompts.

set -euo pipefail

source "$(dirname "$0")/common.sh"

TIER=""
DRY_RUN=0

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --yes) LOCAL_DOWNLOAD_YES=1 ;;
        *)
            if [[ -z "$TIER" ]]; then
                TIER="$arg"
            else
                echo "Unknown argument: $arg" >&2
                exit 1
            fi
            ;;
    esac
done

if [[ -z "$TIER" ]]; then
    echo "Usage: $0 <tier> [--dry-run|--yes]" >&2
    echo "Tiers: laptop, single-gpu-24-48, single-gpu-80, server, cluster" >&2
    exit 1
fi

MODELS=()
TMPFILE="$(mktemp)"
python3 - "$TIERS_JSON" "$TIER" <<'PY' > "$TMPFILE"
import json, sys
path, tier = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
entry = data["tiers"].get(tier)
if not entry:
    print(f"Unknown tier: {tier}", file=sys.stderr)
    sys.exit(1)
print(entry.get("note", ""))
for m in entry["models"]:
    print(m)
PY

while IFS= read -r line; do
    MODELS+=("$line")
done < "$TMPFILE"
rm -f "$TMPFILE"

NOTE="${MODELS[0]}"
echo "Tier: $TIER"
echo "Note: $NOTE"
echo "Models to fetch:"
for m in "${MODELS[@]:1}"; do
    echo "  - $m"
done
echo ""

if [[ "$DRY_RUN" == "1" ]]; then
    for m in "${MODELS[@]:1}"; do
        hf_download "$m" "${REPO_ROOT}/models/$(basename "$m")" 1
    done
    exit 0
fi

if ! _prompt_yes_no "Proceed with tier '$TIER' downloads?"; then
    echo "Aborted."
    exit 0
fi

for m in "${MODELS[@]:1}"; do
    hf_download "$m" "${REPO_ROOT}/models/$(basename "$m")" 0 || true
    echo "---"
done
