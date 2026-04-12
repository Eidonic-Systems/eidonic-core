# Gemma Routing Policy

This document defines the future routing policy for Gemma-family models in Eidonic Core.

## Purpose
State clearly how Gemma-family routing may happen later without pretending that runtime routing already exists.

## Current truth
Runtime routing is not live.

The current default live model remains:
- backend: `ollama`
- model: `gemma3n:e4b`

Candidate comparison tooling exists.
Drift-guarded evaluation exists.
Those measurement layers are prerequisites for routing. They are not routing.

## Routing doctrine
Future Gemma-family routing must remain:
- explicit
- measurable
- reversible
- narrow

No model should be selected dynamically without a stated reason, a measurable benefit, and a clear rollback path.

## Current model classes

### 1. Default control model
The default control model is the current proven live model used for standard orchestration.

Current control model:
- `gemma3n:e4b`

The control model remains in charge unless a future routing policy explicitly allows another Gemma-family model for a defined task class.

### 2. Gemma-family candidates
Other Gemma-family models may be evaluated and compared, but they are not routeable by default.

A Gemma-family candidate becomes route-eligible only after:
- passing the local provider eval surface
- passing baseline comparison without regressions
- avoiding identity drift
- avoiding formatting drift
- avoiding encoding drift
- showing an operational or quality reason to exist

### 3. Non-Gemma models
Non-Gemma models are not part of the default routing strategy.

They may still be used as tooling probes or comparison sanity checks, but they do not enter routing policy unless the overall model-family strategy changes.

## Future routeable task classes
These task classes may become routeable later, but only through explicit implementation branches.

### A. Lightweight conversational acknowledgments
Examples:
- greetings
- short confirmations
- simple status acknowledgments

Potential future policy:
- smaller Gemma variants may be considered here if they remain clean and materially reduce latency or cost

### B. Standard orchestration responses
Examples:
- normal chain responses
- routine file-review follow-ups
- ordinary command interpretation

Current policy:
- keep on the control model unless a future candidate demonstrates a clear advantage without drift

### C. Heavier structured reasoning
Examples:
- more demanding synthesis
- longer multi-part orchestration outputs
- more complex instruction handling

Potential future policy:
- larger Gemma variants may be considered if they clearly outperform the control model on meaningful evals

## Hard disqualifiers for routing
A model is not routeable if it shows:
- formatting drift
- identity drift
- encoding drift
- unstable output shape
- worse operational behavior without compensating advantage
- only “not worse” performance with no real benefit

## Promotion requirements
Before any Gemma-family model enters a future runtime router, it should have:
- a passing drift-guarded eval run
- a passing baseline comparison
- a written decision record
- a specific route class it is allowed to handle
- a reason better than curiosity

## Routing safety rules
Future routing implementation must:
- keep one control model as the fallback
- log which model handled which request
- keep routing rules understandable
- keep rollback simple
- avoid hidden automatic behavior that cannot be explained afterward

## Current decision
The build is now ready for a routing policy surface, but not yet for runtime routing implementation.

Current default remains:
- `gemma3n:e4b`

Current position on routing:
- policy now
- implementation later
