export default {
  name: "loca-smoke",
  rows: [
    {
      id: "strict-arithmetic",
      input: "What is 17 + 25? Reply with only the number.",
      expected: "The response must be exactly 42 with no surrounding explanation.",
      scorer: "Correctness"
    }
  ]
};
