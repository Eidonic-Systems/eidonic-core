# Phase 2 Laptop Sync Surface

This document records the first explicit sync surface for the laptop runner box.

## Purpose
Stop laptop runner maintenance from depending on branch-by-branch babysitting and repeated manual update steps.

## What changed
- added `scripts/sync_laptop_runner_main.ps1`

## What the script does
- fetches origin
- switches the laptop repo to `main`
- pulls `main` with fast-forward only
- reruns service venv bootstrap
- reruns PostgreSQL bootstrap
- reruns host bootstrap checks
- optionally reruns the full Phase 2 gate

## Why this matters
- the laptop runner box should not behave like a second primary dev machine
- the runner should refresh from `main` cleanly and predictably
- this reduces repetitive local maintenance without hiding what the machine is doing

## Current truth
This branch adds a local runner sync surface only.

It does not:
- change runtime behavior
- change governance behavior
- change CI behavior
- change branch management on the dev PC
