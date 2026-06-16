#!/usr/bin/env bash
# Install the minimal tooling needed to download and run local models.
# Does not download any weights.

set -euo pipefail

echo "Installing huggingface_hub + hf-transfer..."
pip install -U huggingface_hub hf-transfer

echo ""
echo "Optional: install inference backends (.pick what you'll actually use):"
echo "  pip install vllm               # high-throughput GPU serving"
echo "  pip install sglang             # fast structured generation"
echo "  pip install llama-cpp-python   # llama.cpp bindings"
echo "  pip install mlx-lm             # Apple Silicon"
echo ""
echo "Done. Set HF_TOKEN if you plan to download gated models:"
echo "  export HF_TOKEN=hf_..."
