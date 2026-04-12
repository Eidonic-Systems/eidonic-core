# Gemma Family Model Policy

This document defines the current model-family policy for the local provider path in Eidonic Core.

## Core decision
The primary local model family for Eidonic Core is `Gemma`.

This is the current architectural direction unless evidence later justifies changing it.

## Why Gemma is the chosen family
Gemma fits the current build doctrine:
- local-first use is viable
- open-weight deployment fits the project constraints
- multiple model sizes make family-internal comparison possible
- the family can support gradual evolution without turning the system into a random model zoo

## Current default live model
- backend: `ollama`
- model: `gemma3n:e4b`

This remains the current proven default until a future branch explicitly changes it.

## Model classes

### 1. Default live model
The current proven default used in the standard startup path.

### 2. Gemma-family candidates
Other Gemma-family variants that may be evaluated through:
- the local eval surface
- baseline comparison
- isolated candidate comparison

These are real candidates for future promotion.

### 3. Non-Gemma tooling probes
Models outside the Gemma family may be used occasionally to:
- validate comparison tooling
- sanity-check evaluation assumptions
- test whether the measurement surface is honest

These are not the default architectural direction.

## Promotion rules
A model does not become the default because it is interesting.

A future default-model pilot should require:
- no regressions on the current eval surface
- comparison against the pinned baseline
- a written decision record
- at least one concrete advantage, such as:
  - stronger outputs on meaningful tasks
  - better runtime stability
  - better latency at acceptable quality
  - operational simplicity worth the change

## Rejection rules
Do not promote a candidate when:
- the only argument is hype
- the eval surface is too narrow to justify the switch
- the candidate adds operational fragility without clear benefit
- the comparison result is only "not worse"

## Current truth
- Gemma is the primary family
- `gemma3n:e4b` is the current live default
- candidate comparison tooling is reusable
- non-Gemma models are tooling probes unless explicitly elevated by evidence
