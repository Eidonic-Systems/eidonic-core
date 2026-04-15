# Phase 2 Runner Bootstrap Surface

This document records the first explicit host bootstrap surface for a Phase 2 laptop or self-hosted runner.

## Purpose
Turn fresh-machine setup from tribal memory into a visible preflight surface.

## What changed
- added `scripts/check_phase2_host_bootstrap.ps1`
- added `docs/RUNNER_BOOTSTRAP.md`

## Why this matters
- the current build can be proven, but second-machine setup was still too dependent on memory and luck
- missing `.env`, missing venvs, missing database, and cold provider behavior should be detected earlier
- a runner or laptop should say what is missing before the operator burns hours

## Current truth
This branch adds a host bootstrap check and runner bootstrap documentation only.

It does not change:
- runtime behavior
- governance behavior
- routing behavior
- CI behavior
