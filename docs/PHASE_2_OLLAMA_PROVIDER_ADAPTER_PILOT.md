# Phase 2 Ollama Provider Adapter Pilot

This document records the first real local model adapter in the Phase 2 scaffold.

## Purpose
Replace the stub-only provider path with a real local Ollama-backed provider while preserving the provider contract surface.

## Why this matters
- the provider contract is already proven on `main`
- the next honest step is one real local model adapter, not multi-model routing
- Ollama provides a clean local runtime boundary for Gemma-family models

## Current provider truth
- backend: `ollama`
- model: `gemma3n:e4b`
- fallback: `StubModelProvider`

## Current truth
This branch introduces one real local provider adapter only. It does not add training, routing, or hosted model backends.
