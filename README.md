# loca — local open-weights LLM harvest notes

> Research dump. No guarantees, no official benchmark lab, no maintenance promises.
> Last updated: **2026-06-16**.

This repo is a scratchpad of the best **locally-runnable, open-weight language models** available on Hugging Face right now. It exists because I kept asking “what should I actually download for experiments?” and got tired of re-deriving the answer.

The current direction is **remote qualification first, local download second**: run the same prompts against Cloudflare-hosted versions, shortlist the useful model families, and only then spend disk space on local weights.

## Repo layout

```text
loca/
├── LICENSE
├── README.md
├── models.json              # machine-readable model registry
├── tiers.json               # hardware-based harvest groups
├── scripts/                 # guarded download helpers
└── evals/                   # CloudEval + named AI Gateway harness
    ├── datasets/
    ├── evals.config.mjs
    └── run.sh
```

A few ground rules used here:

- **“Local”** means the weights are downloadable and runnable on your own hardware (with the right GPU/VRAM), not API-only.
- Specs are taken from the official Hugging Face model cards/configs as of the date above.
- VRAM numbers are **rough Q4_K_M estimates** (~0.6 bytes/param) and include only model weights. KV-cache, context length, and framework overhead will eat more.
- For MoE models I list **total-params / active-params** because the full checkpoint is huge but inference can use only the active experts.

---

## ⚠️ First: there is no GLM 5.2

If you came here looking for `GLM 5.2`, it does not exist as a downloadable open model as of this writing. The latest GLM-family releases are:

- [`zai-org/GLM-5.1`](https://huggingface.co/zai-org/GLM-5.1) (~31B dense, MIT)
- [`zai-org/GLM-4.7-Flash`](https://huggingface.co/zai-org/GLM-4.7-Flash) (~4.4B dense, MIT)

Both are in the matrix below.

---

## 🏆 Top 20 local open models (quick comparison matrix)

| # | Model | Released | Params (total / active) | Context | Precision / Formats | ~VRAM (Q4, all / active-only) | License | Best For |
|---|---|---|---|---|---|---|---|---|
| 1 | [deepseek-ai/DeepSeek-V4-Pro](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro) | Apr 2026 | **1.6T / 49B** | **1M** | FP8/FP4 mixed, safetensors, GGUF* | ~960 GB / ~29 GB | MIT | Absolute SOTA general + long-context |
| 2 | [deepseek-ai/DeepSeek-V4-Flash](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash) | Apr 2026 | **284B / 13B** | **1M** | FP8/FP4 mixed, GGUF* | ~170 GB / ~8 GB | MIT | Efficient 1M-context MoE |
| 3 | [deepseek-ai/DeepSeek-R1-0528](https://huggingface.co/deepseek-ai/DeepSeek-R1-0528) | May 2025 | **671B / 37B** | 128K | FP8/FP4, GGUF* | ~403 GB / ~22 GB | MIT | Reasoning / chain-of-thought |
| 4 | [Qwen/Qwen3-235B-A22B](https://huggingface.co/Qwen/Qwen3-235B-A22B) | Apr 2025 | **235B / 22B** | 32K → **128K** YaRN | safetensors, GGUF, AWQ, FP8 | ~141 GB / ~13 GB | Apache 2.0 | Multilingual flagship |
| 5 | [Qwen/Qwen3-32B](https://huggingface.co/Qwen/Qwen3-32B) | Apr 2025 | **32.8B dense** | 32K → **128K** YaRN | safetensors, GGUF, AWQ, FP8 | ~20 GB / — | Apache 2.0 | Best dense ~30B |
| 6 | [Qwen/Qwen3-30B-A3B](https://huggingface.co/Qwen/Qwen3-30B-A3B) | Apr 2025 | **30.5B / 3.3B** | 32K → **128K** YaRN | safetensors, GGUF, AWQ | ~18 GB / ~2 GB | Apache 2.0 | Ultra-efficient MoE |
| 7 | [meta-llama/Llama-4-Maverick-17B-128E-Instruct](https://huggingface.co/meta-llama/Llama-4-Maverick-17B-128E-Instruct) | Apr 2025 | **400B / 17B** | **1M** | safetensors, GGUF* | ~240 GB / ~10 GB | Llama 4 | Multimodal + very long context |
| 8 | [meta-llama/Llama-4-Scout-17B-16E-Instruct](https://huggingface.co/meta-llama/Llama-4-Scout-17B-16E-Instruct) | Apr 2025 | **109B / 17B** | **256K** | safetensors, GGUF* | ~65 GB / ~10 GB | Llama 4 | Single-GPU multimodal |
| 9 | [meta-llama/Llama-3.3-70B-Instruct](https://huggingface.co/meta-llama/Llama-3.3-70B-Instruct) | Nov 2024 | **70B dense** | **128K** | safetensors, GGUF, AWQ, FP8 | ~42 GB / — | Llama 3.3 | Reliable dense generalist |
| 10 | [moonshotai/Kimi-K2-Instruct](https://huggingface.co/moonshotai/Kimi-K2-Instruct) | Jul 2025 | **1T / 32B** | **128K** | safetensors, GGUF* | ~600 GB / ~19 GB | modified-MIT | Huge-scale general MoE |
| 11 | [zai-org/GLM-5.1](https://huggingface.co/zai-org/GLM-5.1) | Apr 2026 | **~31B dense** | ~**128K** | safetensors, GGUF* | ~19 GB / — | MIT | General Chinese-English |
| 12 | [zai-org/GLM-4.7-Flash](https://huggingface.co/zai-org/GLM-4.7-Flash) | Jan 2026 | **~4.4B dense** | ~**128K** | safetensors, GGUF* | ~3 GB / — | MIT | Edge / fast GLM |
| 13 | [Qwen/Qwen2.5-Coder-32B-Instruct](https://huggingface.co/Qwen/Qwen2.5-Coder-32B-Instruct) | Nov 2024 | **32.5B dense** | **128K** | safetensors, GGUF, AWQ | ~20 GB / — | Apache 2.0 | Code generation |
| 14 | [Qwen/QwQ-32B](https://huggingface.co/Qwen/QwQ-32B) | Mar 2025 | **32.5B dense** | **128K** | safetensors, GGUF, AWQ | ~20 GB / — | Apache 2.0 | Reasoning on consumer HW |
| 15 | [google/gemma-4-26B-A4B-it](https://huggingface.co/google/gemma-4-26B-A4B-it) | Mar 2026 | **26B / 4B active** | **256K** | safetensors, GGUF* | ~16 GB / ~2 GB | Apache 2.0 | Multimodal MoE |
| 16 | [google/gemma-4-12B-it](https://huggingface.co/google/gemma-4-12B-it) | May 2026 | **~12B dense** | **256K** | safetensors, GGUF* | ~7 GB / — | Apache 2.0 | Multimodal on small GPU |
| 17 | [openai/gpt-oss-20b](https://huggingface.co/openai/gpt-oss-20b) | Aug 2025 | **21B / 3.6B** | ~**128K**\* | safetensors, FP8, MXFP4, GGUF* | ~13 GB / ~2 GB | Apache 2.0 | OpenAI open-weight general |
| 18 | [CohereLabs/North-Mini-Code-1.0](https://huggingface.co/CohereLabs/North-Mini-Code-1.0) | Jun 2026 | **30B / 3B** | **256K** (64K out) | safetensors | ~18 GB / ~2 GB | Apache 2.0 | Coding / agent / terminal |
| 19 | [LiquidAI/LFM2.5-8B-A1B](https://huggingface.co/LiquidAI/LFM2.5-8B-A1B) | May 2026 | **8.3B / 1.5B** | **128K** | safetensors, GGUF, MLX, vLLM, SGLang | ~5 GB / ~1 GB | lfm1.0 | Edge / high-throughput |
| 20 | [XiaomiMiMo/MiMo-V2.5-Pro](https://huggingface.co/XiaomiMiMo/MiMo-V2.5-Pro) | Apr 2026 | **~34B dense** | **1M** | safetensors, FP8 | ~20 GB / — | MIT | Long-context coding/agent |

\*VRAM estimates assume **Q4_K_M ≈ 0.6 bytes/param** and include only model weights. KV-cache, overhead, and long contexts will add more.
\*\*Context marked with `*` is inferred from family/usage examples, not explicitly listed on the card.

---

## 🎯 Harvest recommendations by hardware tier

> This is the practical “which ones should actually grab?” section.

### Laptop / 8–16 GB VRAM
- **GLM-4.7-Flash** (~3 GB Q4) — best ultra-compact general model.
- **Gemma-4-12B-it** (~7 GB Q4) — best multimodal at the edge.
- **LFM2.5-8B-A1B** (~5 GB Q4 total, ~1 GB active) — best throughput / battery-friendly.
- **Qwen3-30B-A3B** active-only (~2 GB) — punches way above its weight if you route experts.

### Single 24–48 GB GPU (the sweet spot)
- **Qwen3-32B** or **QwQ-32B** (~20 GB Q4) — best dense 30B.
- **Qwen2.5-Coder-32B** (~20 GB Q4) — best coding specialist.
- **GLM-5.1** (~19 GB Q4) — best 30B-class Chinese/English.
- **MiMo-V2.5-Pro** (~20 GB Q4) — best long-context coding/agent.

### Single 80 GB GPU / dual 48 GB
- **Llama-4-Scout** (~65 GB Q4 total) — best multimodal that fits on one H100/A100.
- **Llama-3.3-70B** (~42 GB Q4) — most reliable dense 70B.
- **Gemma-4-26B-A4B** (~16 GB Q4 total) — strong multimodal MoE with tiny active cost.

### Multi-GPU / Server (128 GB+)
- **DeepSeek-R1-0528** — best open reasoning model.
- **Qwen3-235B-A22B** — best multilingual MoE.
- **DeepSeek-V4-Flash** — best 1M-context model at sensible active cost.

### Cluster / research infra
- **DeepSeek-V4-Pro** — absolute SOTA.
- **Llama-4-Maverick** — best open multimodal + 1M context.
- **Kimi-K2-Instruct** — another 1T-class MoE worth benchmarking.

---

## 🛠️ Safe local-download recipes

Nothing downloads by default. Preview the disk-impact command first:

```bash
# Preview one model
./scripts/download-model.sh zai-org/GLM-5.1 --dry-run

# Preview a hardware tier
./scripts/download-tier.sh laptop --dry-run

# Interactive download only after deciding
./scripts/download-model.sh zai-org/GLM-5.1
```

For gated models, accept the model license on Hugging Face and set `HF_TOKEN` before running the helper.

---

## 📋 Notes / caveats

- **Licenses matter.** Apache 2.0 / MIT are the friendliest. Llama-family models use Meta’s custom license. `Kimi-K2` uses a modified MIT. Always read the license before product use.
- **Gated models** (Meta Llama, some others) require accepting terms on Hugging Face before download.
- **MoE VRAM is misleading.** Loading all experts for the full checkpoint is enormous; many inference engines can keep only active experts in GPU memory and offload the rest to CPU/SSD.
- **Quantization changes everything.** Q4 is usually “good enough” for evaluation. For serious fine-tuning or sensitive reasoning tasks you often want FP8 or FP16 of smaller models.

---

## 🧭 What to add next (maybe)

- [ ] Concrete per-model run commands for `llama.cpp`, `vLLM`, `SGLang`, `Ollama`.
- [x] A `models.json` registry of the shortlist.
- [x] Safe download scripts.
- [x] Named AI Gateway eval harness using CloudEval.
- [x] Dated JSON/HTML/Markdown eval artifacts.
- [ ] Add latency, token usage, and estimated cost to eval reports.
- [ ] Add a second independent judge and human spot checks.

This is intentionally a “plopped research” starting point. PRs welcome if you want to expand any section.
