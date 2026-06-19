# loca/scripts

Safe download helpers. Nothing here downloads weights unless you explicitly say yes.

## Files

- `common.sh` — shared helpers (VRAM estimates, prompt logic, gated-model warning).
- `download-model.sh` — download one model.
- `download-tier.sh` — download the recommended set for your hardware tier.
- `setup.sh` — install `huggingface_hub` and `hf-transfer` only.

## Safety defaults

- **No `--yes` or `--dry-run`?** You get a preview and a `y/N` prompt before any bytes move.
- **`--dry-run`** prints the exact command and the estimated VRAM requirement.
- **`--yes`** skips prompts (use carefully — this is how you bloat a machine).
- **`LOCAL_DOWNLOAD_YES=1`** also skips prompts.

## Examples

```bash
# Preview only
./scripts/download-model.sh openai/gpt-oss-20b --dry-run

# Interactive download of one model
./scripts/download-model.sh openai/gpt-oss-20b

# Download a whole recommended tier
./scripts/download-tier.sh single-gpu-24-48 --dry-run
./scripts/download-tier.sh single-gpu-24-48

# Install tooling (no weights downloaded)
./scripts/setup.sh
```

## Tiers defined in `../tiers.json`

- `laptop` — 8–16 GB VRAM
- `single-gpu-24-48` — single 24–48 GB GPU
- `single-gpu-80` — single 80 GB GPU / dual 48 GB
- `server` — multi-GPU / 128 GB+
- `cluster` — research cluster
