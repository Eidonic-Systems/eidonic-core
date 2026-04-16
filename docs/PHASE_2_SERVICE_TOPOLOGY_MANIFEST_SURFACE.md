# Phase 2 Service Topology Manifest Surface

This document records the point where the local Phase 2 operational scripts began reading a shared service topology manifest instead of hardcoding service truth in multiple places.

## Purpose
Turn service topology into one declared surface instead of scattered operational assumptions.

## What changed
- added `config/service_topology_manifest.json`
- updated `scripts/check_phase_2_startup_readiness.ps1`
- updated `scripts/restart_phase_2_stack.ps1`

## Declared service truth
The topology manifest now declares:
- service name
- service port
- health URL
- service root
- process match patterns
- whether provider status must also be checked

## Covered services
- `signal-gateway`
- `session-engine`
- `herald-service`
- `eidon-orchestrator`

## Why this matters
- readiness and restart logic should not hardcode service truth in multiple places
- operational drift becomes more likely when topology is duplicated
- this creates one explicit local source of truth for Phase 2 service topology

## Current truth
This branch strengthens operational topology discipline only.

It does not:
- change runtime behavior inside services
- add new persistence fields
- widen governance behavior
- expand CI behavior
