# Model Decision Index

This document is the top-level index for current model decisions in Eidonic Core.

## Current control model
- provider backend: `ollama`
- control model: `gemma3n:e4b`

## Why `gemma3n:e4b` remains the control model
`gemma3n:e4b` remains the default because it is the current proven control path across:
- startup preflight and warmup discipline
- provider failure semantics
- drift-guarded eval behavior
- generic eval baseline
- domain-task eval baseline
- full-chain integration proof

It is the current model with the strongest combined operational and measurement position.

## Current held candidates

### `gemma3n:e2b`
Status:
- `hold pending better runtime evidence`

Why it is held:
- passed generic candidate comparison
- passed domain-task candidate comparison
- remained inside the Gemma family
- but local runtime profiling on this machine did not justify lightweight promotion

Current machine-level runtime evidence:
- `gemma3n:e2b` was faster on eval duration
- `gemma3n:e2b` was slower overall than `gemma3n:e4b`
- the warmup penalty outweighed the narrower eval-time gain

### `gemma3:4b`
Status:
- `hold`

Why it is held:
- completed a valid Gemma-family comparison run
- did not regress on the narrow baseline during earlier comparison
- but showed reasons for caution around output shape and formatting discipline during comparison work
- current evidence is not strong enough to justify promotion or routing eligibility

## Non-Gemma models
Non-Gemma models are not the current architectural direction.

They may still be used for:
- tooling validation
- comparison sanity checks
- testing whether eval surfaces are honest

They are not part of default strategy unless the model-family policy changes.

## Current decision surfaces

### Family policy
- `docs/GEMMA_FAMILY_MODEL_POLICY.md`

Defines:
- Gemma as the primary local model family
- the control model concept
- candidate classes
- promotion requirements

### Routing policy
- `docs/GEMMA_ROUTING_POLICY.md`

Defines:
- routeable task classes as future policy
- route disqualifiers
- routing safety rules
- the fact that routing is not yet live

### Candidate decision records
- `docs/decision_records/GEMMA3N_E2B_CANDIDATE_DECISION.md`
- `docs/decision_records/GEMMA3_4B_CANDIDATE_DECISION.md`

These capture the current explicit verdicts for the tested Gemma candidates.

## Current measurement surfaces

### Generic provider eval
- eval cases: `evals/local_provider_eval_cases.json`
- runner: `scripts/run_local_provider_eval.ps1`
- baseline: `evals/baselines/local_provider_eval_baseline.json`
- baseline compare: `scripts/compare_local_provider_eval_to_baseline.ps1`

### Domain-task eval
- eval cases: `evals/domain_task_eval_cases.json`
- runner: `scripts/run_domain_task_eval.ps1`
- baseline: `evals/baselines/domain_task_eval_baseline.json`
- baseline compare: `scripts/compare_domain_task_eval_to_baseline.ps1`

### Candidate comparison
- generic candidate comparison: `scripts/run_local_provider_candidate_eval.ps1`
- domain-task candidate comparison: `scripts/run_domain_task_candidate_eval.ps1`

### Runtime profile
- runtime profile script: `scripts/profile_gemma_candidate_runtime.ps1`

## Current rejected assumptions
- smaller Gemma does not automatically mean better runtime on this machine
- passing a narrow eval does not automatically justify promotion
- routing should not be implemented before policy and measurement discipline exist
- generic prompts are not enough to judge the real system

## What would justify a future change
A future change to the control model or route eligibility should require:
- passing drift-guarded eval behavior
- passing generic and domain-task comparisons
- no new operational fragility
- a documented reason better than curiosity
- a written decision update

## Current truth
The build is Gemma-family-centered.

Current control model:
- `gemma3n:e4b`

Current held candidates:
- `gemma3n:e2b`
- `gemma3:4b`

No candidate currently has enough evidence to replace the control model.
