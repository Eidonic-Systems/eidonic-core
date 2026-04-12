# Phase 2 Measurement and Policy Truth Sync

This document records a narrow truth sync after the local measurement and Gemma-family policy layers landed on `main`.

## Purpose
Bring the top-level build README into alignment with the current proven provider, measurement, and model-policy state.

## What changed
- updated `README.md`

## Why this matters
- the build repo should describe the system that actually exists
- the README should not stop at warmup when eval, baseline, candidate comparison, and Gemma-family policy are already live
- top-level docs should reflect the current local workflow without inventing new runtime changes

## Current truth
The build now includes local evaluation, a pinned baseline, isolated candidate comparison, and a Gemma-family-centered model policy on `main`.
