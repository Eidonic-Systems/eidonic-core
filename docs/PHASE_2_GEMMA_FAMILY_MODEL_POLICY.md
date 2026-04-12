# Phase 2 Gemma Family Model Policy

This document records the move from ad hoc model curiosity to an explicit model-family policy.

## Purpose
State clearly that the local provider strategy is Gemma-family-centered and distinguish that strategy from generic comparison tooling.

## What changed
- updated `AGENTS.md` with a Gemma-family-centered model policy
- added `docs/GEMMA_FAMILY_MODEL_POLICY.md`

## Why this matters
- comparison tooling is reusable, but strategy still needs a center
- the system should not drift into random model-shopping
- future default-model changes should happen inside a stated policy, not by impulse

## Current truth
The build now has reusable candidate-comparison tooling, but the architectural direction remains Gemma-family-centered with `gemma3n:e4b` as the current default live model.
