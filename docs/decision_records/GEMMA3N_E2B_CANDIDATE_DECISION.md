# Gemma Candidate Decision: gemma3n:e2b

## Decision summary
- baseline model: `gemma3n:e4b`
- candidate model: `gemma3n:e2b`
- comparison method: isolated candidate comparison against the pinned local provider eval baseline plus local runtime profiling
- eval result: no regressions on the current drift-guarded eval surface
- runtime result on this machine: slower overall than the control model
- current verdict: `hold pending better runtime evidence`

## Why this is not a default-model promotion
The candidate cleared the current eval surface, which means it remains a valid Gemma-family candidate. That is useful.

It still did not prove the thing it needed to prove for lightweight promotion on this machine:
a real runtime advantage over the control model.

The current control model remains:
- `gemma3n:e4b`

## Runtime profile evidence
Local runtime profiling recorded:

- control model `gemma3n:e4b`
  - warmup: `8511.71 ms`
  - eval duration: `9649.16 ms`
  - total profile: `18160.87 ms`

- candidate model `gemma3n:e2b`
  - warmup: `12658.03 ms`
  - eval duration: `8684.93 ms`
  - total profile: `21342.96 ms`

Observed comparison:
- candidate faster on eval: `true`
- candidate faster overall: `false`
- overall delta candidate minus control: `+3182.09 ms`

## Operational interpretation
`gemma3n:e2b` is still strategically relevant because:
- it stays inside the Gemma family
- it passes the current drift-guarded eval surface
- it remains a legitimate measured candidate

But the current runtime evidence does not justify lightweight routing or default promotion on this machine.

The warmup penalty outweighed the smaller eval-time gain.

## Current decision
Do not change the default model.

Keep:
- default provider backend: `ollama`
- default provider model: `gemma3n:e4b`

Retain `gemma3n:e2b` as a held Gemma-family candidate only.

Do not classify it as a lightweight routing candidate at this time.

## What must happen before promotion
A future promotion or routing-pilot branch should require:
- fresh runtime profiling on the current machine
- evidence of a real overall runtime advantage, not just a narrower eval-duration win
- continued passing behavior on the drift-guarded eval surface
- an explicit route class and written promotion decision
