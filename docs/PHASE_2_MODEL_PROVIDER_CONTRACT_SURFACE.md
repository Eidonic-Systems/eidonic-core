# Phase 2 Model Provider Contract Surface

This document records the first explicit model provider contract surface for Orchestrator.

## Purpose
Create a provider-neutral seam for response generation before any real model runtime is introduced.

## Why this matters
- the durable state spine is now real and proven
- model concerns should not be wired directly into Orchestrator without an adapter boundary
- a stub provider lets the repo prove the contract shape before real local model integration

## Current contract surface
- `backend_name`
- `model_name`
- `generate_response(intent, content)`
- `ping()`

## Current truth
This branch adds only a stub provider implementation. It does not introduce a real model runtime yet.
