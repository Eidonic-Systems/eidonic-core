# Gemma Candidate Decision: gemma3:4b

## Decision summary
- baseline model: `gemma3n:e4b`
- candidate model: `gemma3:4b`
- comparison method: isolated candidate comparison against the pinned local provider eval baseline
- result: no regressions on the current narrow eval surface during the candidate comparison run
- current verdict: `hold`

## Why the verdict is hold
The candidate completed a valid Gemma-family comparison and did not regress on the narrow baseline. That is useful. It is still not enough for promotion.

The recorded candidate outputs also showed reasons for caution during comparison work:
- response-shape drift
- wrapper-style output tendencies
- encoding or punctuation weirdness in some responses

Those observations were exactly why the eval surface had to be strengthened with drift guards and why the plain-text response guard was added to the provider path.

## Operational notes
- the candidate comparison used an isolated Orchestrator override path
- the live default model remained unchanged
- the candidate warmed successfully and completed a valid comparison run
- the candidate is inside the Gemma family, which keeps it strategically relevant
- the current evidence does not show a strong enough reason to replace the control model

## Current interpretation
`gemma3:4b` is a real Gemma-family candidate, but it is not currently clean enough to justify promotion or future routing eligibility without stricter confidence around output shape and presentation behavior.

## Current decision
Do not change the default model.

Keep:
- default provider backend: `ollama`
- default provider model: `gemma3n:e4b`

Retain `gemma3:4b` as a held Gemma-family candidate only.

## What must happen before promotion
A future promotion or routing-pilot branch should require:
- a fresh comparison under the current strengthened drift-guard eval surface
- clean behavior on formatting, encoding, and response-shape expectations
- a concrete reason to prefer it over `gemma3n:e4b`
- a written promotion decision
