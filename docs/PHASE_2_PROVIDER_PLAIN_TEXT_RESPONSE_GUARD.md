# Phase 2 Provider Plain Text Response Guard

This document records the runtime fix for wrapper-style response drift in the local provider path.

## Purpose
Keep the current default provider output in plain text form so the strengthened eval surface does not catch avoidable JSON or fenced-block formatting drift.

## What changed
- updated `services/eidon-orchestrator/app/provider.py`
- strengthened the Ollama prompt to require plain text only
- added normalization for common fenced-block and JSON-wrapper leakage
- updated `services/eidon-orchestrator/README.md`

## Why this matters
- the strengthened eval surface exposed real formatting drift in the current default model path
- routing policy should not sit on top of sloppy output contracts
- fixing plain-text behavior in the provider layer is narrower and cleaner than weakening the eval

## Current truth
The provider path now pushes harder toward plain text and normalizes common wrapper leakage before returning the final response text.
