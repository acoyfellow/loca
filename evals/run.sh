#!/usr/bin/env bash
# Run loca quality evals through a named Cloudflare AI Gateway.
# No local weights are downloaded.
#
# Examples:
#   ./run.sh --suite smoke                         # preview only
#   ./run.sh --suite smoke --run --env-file .env  # real, prompts
#   ./run.sh --suite pilot --run --yes --env-file .env
#   ./run.sh --suite full --mock                   # fake outputs, no API calls

set -euo pipefail

cd "$(dirname "$0")"

ACTION="preview"
SUITE="full"
YES=0
ENV_FILE="${CLOUDEVAL_ENV_FILE:-}"
GATEWAY="${CLOUDEVAL_GATEWAY_ID:-default}"
CONCURRENCY="${CLOUDEVAL_CONCURRENCY:-3}"
CUSTOM_MODELS=""
CLOUDEVAL_ROOT="${CLOUDEVAL_ROOT:-../../cloudeval}"
CLI="${CLOUDEVAL_ROOT}/bin/cloudeval.mjs"
JUDGE="@cf/meta/llama-3.3-70b-instruct-fp8-fast"

SMOKE_MODELS="glm-5.2,glm-4.7-flash"
PILOT_MODELS="glm-5.2,glm-4.7-flash,gpt-oss-20b"
FULL_MODELS="glm-5.2,glm-4.7-flash,llama-4-scout,gpt-oss-20b,gemma-4-26b,qwq-32b,qwen3-30b-a3b,qwen-coder-32b,llama-3.3-70b,kimi-k2.6"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run) ACTION="run"; shift ;;
    --mock) ACTION="mock"; shift ;;
    --yes) YES=1; shift ;;
    --suite) SUITE="${2:?--suite requires smoke, pilot, or full}"; shift 2 ;;
    --env-file) ENV_FILE="${2:?--env-file requires a path}"; shift 2 ;;
    --gateway) GATEWAY="${2:?--gateway requires an id}"; shift 2 ;;
    --concurrency) CONCURRENCY="${2:?--concurrency requires a number}"; shift 2 ;;
    --models) CUSTOM_MODELS="${2:?--models requires a CSV list}"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

case "$SUITE" in
  smoke) DATASET="loca-smoke"; MODELS="$SMOKE_MODELS" ;;
  pilot) DATASET="loca-quality"; MODELS="$PILOT_MODELS" ;;
  full) DATASET="loca-quality"; MODELS="$FULL_MODELS" ;;
  *) echo "Unknown suite: $SUITE (expected smoke, pilot, or full)" >&2; exit 1 ;;
esac
[[ -n "$CUSTOM_MODELS" ]] && MODELS="$CUSTOM_MODELS"

if [[ ! -f "$CLI" ]]; then
  echo "CloudEval CLI not found at: $CLI" >&2
  echo "Set CLOUDEVAL_ROOT to your CloudEval checkout." >&2
  exit 1
fi

if [[ -n "$ENV_FILE" ]]; then
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "Credential file not found: $ENV_FILE" >&2
    exit 1
  fi
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

# Only fall back to the personal pair when the generic pair is entirely absent.
if [[ -z "${CLOUDFLARE_ACCOUNT_ID:-}" && -z "${CLOUDFLARE_API_TOKEN:-}" && \
      -n "${CLOUDFLARE_PERSONAL_ACCOUNT_ID:-}" && -n "${CLOUDFLARE_PERSONAL_API_TOKEN:-}" ]]; then
  export CLOUDFLARE_ACCOUNT_ID="$CLOUDFLARE_PERSONAL_ACCOUNT_ID"
  export CLOUDFLARE_API_TOKEN="$CLOUDFLARE_PERSONAL_API_TOKEN"
fi

COMMAND=(node "$CLI" run --dataset "$DATASET" --models "$MODELS" --gateway "$GATEWAY" --concurrency "$CONCURRENCY" --output-dir "./runs")
[[ "$ACTION" == "mock" ]] && COMMAND+=(--mock)

print_plan() {
  echo "Suite:    $SUITE"
  echo "Dataset:  $DATASET"
  echo "Gateway:  $GATEWAY"
  echo "Parallel: $CONCURRENCY model workers"
  echo "Judge:    $JUDGE"
  echo "Output:   ./runs/"
  if [[ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]]; then
    echo "Account:  $CLOUDFLARE_ACCOUNT_ID"
  else
    echo "Account:  <not configured>"
  fi
  echo "Models:"
  printf '%s\n' "$MODELS" | tr ',' '\n' | sed 's/^/  - /'
}

if [[ "$ACTION" == "preview" ]]; then
  echo "Dry-run preview (no API calls):"
  print_plan
  echo ""
  printf 'Command:'
  printf ' %q' "${COMMAND[@]}"
  echo ""
  exit 0
fi

if [[ "$ACTION" == "run" ]]; then
  if [[ -z "${CLOUDFLARE_ACCOUNT_ID:-}" || -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
    echo "Missing a matched CLOUDFLARE_ACCOUNT_ID / CLOUDFLARE_API_TOKEN pair." >&2
    echo "Pass --env-file or export both variables explicitly." >&2
    exit 1
  fi
fi

if [[ "$ACTION" == "mock" ]]; then
  echo "Running MOCK suite (no API calls):"
else
  echo "Running real suite through Cloudflare AI Gateway:"
fi
print_plan

if [[ "$ACTION" == "run" && "$YES" != "1" ]]; then
  echo ""
  read -r -p "Proceed with billable API calls? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

"${COMMAND[@]}"
