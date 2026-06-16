import base from "../../cloudeval/src/presets/cloudflare.mjs";

export default {
  ...base,
  project: "loca-gateway-evals",
  defaultProvider: "workers-ai",
  defaultJudgeModel: "@cf/meta/llama-3.3-70b-instruct-fp8-fast",
  systemPrompt: "You are a helpful, accurate AI assistant. Follow the user's requested format exactly. Give the final answer directly and do not expose hidden chain-of-thought or internal reasoning.",
  judgeParams: {
    temperature: 0,
  },
  modelParams: {
    "@cf/zai-org/glm-4.7-flash": {
      reasoning_effort: "low",
      chat_template_kwargs: { enable_thinking: false },
      temperature: 0.2,
    },
    "@cf/openai/gpt-oss-20b": {
      reasoning_effort: "low",
      temperature: 0.2,
    },
    "@cf/qwen/qwen3-30b-a3b-fp8": {
      chat_template_kwargs: { enable_thinking: false },
      temperature: 0.2,
    },
    "@cf/qwen/qwq-32b": {
      max_tokens: 2048,
      temperature: 0.2,
    },
    "@cf/moonshotai/kimi-k2.6": {
      max_tokens: 1024,
      temperature: 0.2,
    },
  },
  // Extend the Cloudflare preset aliases with the CF-hosted loca models.
  models: {
    ...base.models,
    "llama-4-scout": "@cf/meta/llama-4-scout-17b-16e-instruct",
    "gpt-oss-20b": "@cf/openai/gpt-oss-20b",
    "gemma-4-26b": "@cf/google/gemma-4-26b-a4b-it",
    "qwq-32b": "@cf/qwen/qwq-32b",
    "qwen3-30b-a3b": "@cf/qwen/qwen3-30b-a3b-fp8",
    "kimi-k2.5": "@cf/moonshotai/kimi-k2.5",
    "kimi-k2.6": "@cf/moonshotai/kimi-k2.6",
    "kimi-k2.7-code": "@cf/moonshotai/kimi-k2.7-code",
    // Already present in the shared-models preset, repeated here for clarity.
    "glm-4.7-flash": "@cf/zai-org/glm-4.7-flash",
    "glm-5.1": "@cf/zai-org/glm-5.1",
    "qwen-coder-32b": "@cf/qwen/qwen2.5-coder-32b-instruct",
    "llama-3.3-70b": "@cf/meta/llama-3.3-70b-instruct-fp8-fast",
    "llama-3.1-8b": "@cf/meta/llama-3.1-8b-instruct-fp8-fast",
  },
  datasets: {
    ...base.datasets,
    "loca-smoke": "./datasets/loca-smoke.mjs",
    "loca-quality": "./datasets/loca-quality.mjs",
  },
};
