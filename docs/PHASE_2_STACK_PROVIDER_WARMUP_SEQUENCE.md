# Phase 2 Stack Provider Warmup Sequence

This document records the move from manual provider warmup to standard startup warmup in the Phase 2 local stack workflow.

## Purpose
Make provider warmup part of the normal stack startup sequence so the local system enters a ready state deterministically.

## What changed
- the Phase 2 stack launcher now waits for service health
- the launcher then runs `scripts/warm_eidon_provider.ps1`
- startup fails clearly if provider warmup fails
- the startup readout now states that provider warmup completed

## Why this matters
- manual warmup is weaker than standard startup behavior
- a hardened local stack should boot into a known ready state
- this reduces operator error and makes cold-start discipline part of the default workflow

## Current truth
Starting the Phase 2 local stack now includes provider warmup automatically after Orchestrator becomes healthy.
