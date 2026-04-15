# Phase 2 Service Venv Bootstrap Surface

This document records the first explicit bootstrap surface for Phase 2 service virtual environments.

## Purpose
Automate the repetitive creation and dependency installation of the local service virtual environments.

## What changed
- added `scripts/bootstrap_phase2_service_venvs.ps1`

## Covered services
The bootstrap script currently covers:
- `eidon-orchestrator`
- `signal-gateway`
- `session-engine`
- `herald-service`

## What the script does
- checks for a `.venv` in each service folder
- creates the `.venv` if missing
- upgrades `pip`
- installs dependencies from `requirements.txt`

## Why this matters
- fresh-machine setup was still too repetitive
- recreating four service venvs by hand wastes time and creates avoidable errors
- this keeps the setup explicit while removing the most boring repetition

## Current truth
This branch adds service venv bootstrap automation only.

It does not:
- create `.env`
- create the PostgreSQL database
- pull Ollama models
- change runtime behavior
