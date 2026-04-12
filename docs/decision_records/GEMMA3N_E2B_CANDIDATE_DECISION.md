# Gemma Candidate Decision: gemma3n:e2b

## Decision summary
- baseline model: `gemma3n:e4b`
- candidate model: `gemma3n:e2b`
- comparison method: isolated candidate comparison against the pinned local provider eval baseline
- result: no regressions on the current narrow eval surface during the candidate comparison run
- current verdict: `hold as lightweight Gemma-family candidate`

## Why this is not a default-model promotion
The candidate cleared the current narrow baseline comparison, which is useful. It did not yet prove enough to replace the control model.

The current control model remains:
- `gemma3n:e4b`

A no-regression result is enough to keep `gemma3n:e2b` alive as a serious Gemma-family candidate. It is not enough by itself to justify a default-model switch.

## Operational notes
- the candidate comparison used an isolated Orchestrator override path
- the live default model remained unchanged
- the candidate completed warmup successfully and produced a valid comparison run
- the comparison surface used the same local eval cases and pinned baseline workflow as the current default path

## Current interpretation
`gemma3n:e2b` is the strongest current candidate for future lightweight use because:
- it stayed inside the Gemma family
- it completed a valid comparison run
- it showed no regressions on the current narrow eval surface

## Current decision
Do not change the default model yet.

Keep:
- default provider backend: `ollama`
- default provider model: `gemma3n:e4b`

Retain `gemma3n:e2b` as a lightweight Gemma-family candidate for future consideration under the Gemma routing policy.

## What must happen before promotion
A future promotion or routing-pilot branch should require:
- a fresh comparison under the current strengthened drift-guard eval surface
- evidence of a real advantage such as lower latency or lower resource cost with acceptable quality
- a route class where the smaller model is explicitly allowed
- a written promotion decision, not just terminal output
