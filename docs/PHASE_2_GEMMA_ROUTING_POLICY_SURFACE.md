# Phase 2 Gemma Routing Policy Surface

This document records the addition of an explicit Gemma-family routing policy surface.

## Purpose
Define the rules that future Gemma-family routing must obey before any runtime router exists.

## What changed
- added `docs/GEMMA_ROUTING_POLICY.md`

## Why this matters
- multiple Gemma-family candidates now exist
- comparison tooling and drift-guarded evaluation now exist
- routing without policy would create hidden chaos
- the system needs a written doctrine before any future model-selection logic is introduced

## Current truth
Routing is still future work.

The current live default remains `gemma3n:e4b`.

The build now has enough measurement discipline to define a routing policy without pretending the router itself already exists.
