# Gemma Candidate Decision: gemma3n:e2b

## Decision summary
- baseline control model: `gemma3n:e4b`
- candidate model: `gemma3n:e2b`
- comparison methods:
  - isolated generic candidate comparison
  - isolated domain-task candidate comparison
  - generic runtime profiling
  - domain-task runtime profiling
- eval result: passed the current drift-guarded generic eval surface and the current domain-task eval surface
- current verdict: `conditional domain-task routing candidate`

## Why this is not a default-model promotion
`gemma3n:e2b` has now earned more than vague hold status, but it has not earned control-model replacement.

The current control model remains:
- `gemma3n:e4b`

Why:
- the control model still has the strongest overall proven operational position
- the generic runtime profile did not justify promotion for `gemma3n:e2b`
- the candidate has now shown a real advantage on the domain-task runtime profile, but that is narrower than universal superiority

## Generic runtime evidence
Earlier local runtime profiling recorded:

- control model `gemma3n:e4b`
  - warmup: `8511.71 ms`
  - eval duration: `9649.16 ms`
  - total profile: `18160.87 ms`

- candidate model `gemma3n:e2b`
  - warmup: `12658.03 ms`
  - eval duration: `8684.93 ms`
  - total profile: `21342.96 ms`

Observed generic comparison:
- candidate faster on eval: `true`
- candidate faster overall: `false`
- overall delta candidate minus control: `+3182.09 ms`

## Domain-task runtime evidence
Local domain-task runtime profiling recorded:

- control model `gemma3n:e4b`
  - warmup: `10225.88 ms`
  - eval duration: `13209.11 ms`
  - total profile: `23434.99 ms`

- candidate model `gemma3n:e2b`
  - warmup: `8698.93 ms`
  - eval duration: `12800.44 ms`
  - total profile: `21499.37 ms`

Observed domain-task comparison:
- candidate faster on warmup: `true`
- candidate faster on eval: `true`
- candidate faster overall: `true`
- overall delta candidate minus control: `-1935.62 ms`

## Operational interpretation
`gemma3n:e2b` now has a split result:

- generic runtime profile:
  - not good enough for promotion
- domain-task runtime profile:
  - good enough to justify conditional routing consideration for narrow domain-task classes

That means the candidate is no longer merely "held pending better runtime evidence."
It now has evidence for a narrower claim:

`gemma3n:e2b` may be suitable for future routeable domain-task classes if the routing policy stays explicit and narrow.

## Current decision
Do not change the default model.

Keep:
- default provider backend: `ollama`
- default control model: `gemma3n:e4b`

Update `gemma3n:e2b` to:
- valid Gemma-family candidate
- not a default replacement
- conditionally eligible for future domain-task routing consideration

## What must happen before promotion or routing use
A future routing or promotion branch should still require:
- route classes defined explicitly under the Gemma routing policy
- continued passing behavior on the drift-guarded eval surface
- continued passing behavior on the domain-task eval surface
- a routing implementation that logs model choice and preserves rollback
- a written decision update after that implementation is tested
