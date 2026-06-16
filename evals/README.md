# loca/evals

Quick personal quality evals using [CloudEval](../../cloudeval/) and a named Cloudflare AI Gateway. No model weights are downloaded.

## Files

- `evals.config.mjs` — model aliases, generation parameters, and a generic eval system prompt.
- `datasets/loca-smoke.mjs` — one-row integration smoke test.
- `datasets/loca-quality.mjs` — ten-row general-quality dataset.
- `run.sh` — guarded runner; preview-only unless `--run` is provided.

## Credentials

Use a matched account/token pair with Workers AI and AI Gateway permissions. Do not commit it.

```bash
cat > .env.local <<'EOF'
CLOUDFLARE_ACCOUNT_ID=...
CLOUDFLARE_API_TOKEN=...
EOF
```

`.env*` is ignored except `.env.example`.

## Usage

```bash
cd loca/evals

# Preview the full run; no API calls
./run.sh --suite full --env-file .env.local

# Mock report pipeline; no credentials or API calls
./run.sh --suite full --mock

# Two models × one prompt: verifies candidate + judge parsing
./run.sh --suite smoke --run --env-file .env.local --gateway default

# Three models × ten prompts
./run.sh --suite pilot --run --env-file .env.local --gateway default

# Nine models × ten prompts, three model workers in parallel
./run.sh --suite full --run --env-file .env.local --gateway default --concurrency 3
```

Add `--yes` to skip the billable-call confirmation. Override models with `--models alias-a,alias-b`. Set `CLOUDEVAL_ROOT` when CloudEval is not checked out at `../../cloudeval`.

## Default full model set

- `glm-4.7-flash` (`@cf/zai-org/glm-4.7-flash`)
- `llama-4-scout` (`@cf/meta/llama-4-scout-17b-16e-instruct`)
- `gpt-oss-20b` (`@cf/openai/gpt-oss-20b`)
- `gemma-4-26b` (`@cf/google/gemma-4-26b-a4b-it`)
- `qwq-32b` (`@cf/qwen/qwq-32b`)
- `qwen3-30b-a3b` (`@cf/qwen/qwen3-30b-a3b-fp8`)
- `qwen-coder-32b` (`@cf/qwen/qwen2.5-coder-32b-instruct`)
- `llama-3.3-70b` (`@cf/meta/llama-3.3-70b-instruct-fp8-fast`)
- `kimi-k2.6` (`@cf/moonshotai/kimi-k2.6`)

`glm-5.1` remains an alias but was not visible in the public Workers AI catalog when this research was recorded.

## Output

Reports land in ignored `./runs/` directories containing:

- `run.json` — canonical outputs, scores, errors, gateway, and concurrency
- `report.md` — comparison report
- `report.html` — shareable HTML
- `summary.txt` — compact ranking
- `meta.json` — reproducibility metadata

## Interpretation caveats

- The current ten-row dataset is a smoke-quality sample, not a benchmark suite.
- The default judge is also one of the candidates, so self-preference is possible.
- One LLM judge can be lenient; manually inspect outputs near the decision boundary.
- Model-specific parameters disable or reduce hidden reasoning where supported so token limits measure final-answer quality instead of truncation behavior.
