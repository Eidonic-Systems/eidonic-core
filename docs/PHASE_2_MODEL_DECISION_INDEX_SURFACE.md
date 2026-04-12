# Phase 2 Model Decision Index Surface

This document records the addition of a single index surface for model decisions in Eidonic Core.

## Purpose
Make the current model position understandable from one place instead of forcing reconstruction from scattered decision records, policy docs, eval files, and terminal history.

## What changed
- added `docs/MODEL_DECISION_INDEX.md`

## Why this matters
- the repo now has enough model evidence that the decision state needs a top-level index
- current control-model and candidate decisions should be easy to explain
- future changes should begin from a clear decision surface, not from memory

## Current truth
The model decision index now explains:
- why `gemma3n:e4b` remains the control model
- why `gemma3n:e2b` is on hold
- why `gemma3:4b` is on hold
- which policy, eval, and runtime surfaces govern future change
