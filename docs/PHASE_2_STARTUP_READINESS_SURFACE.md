\# Phase 2 Startup Readiness Surface



This document records the point where the Phase 2 startup path began verifying service readiness explicitly after launch.



\## Purpose

Make startup success mean real service readiness instead of terminal-window theater.



\## What changed

\- added `scripts/check\_phase\_2\_startup\_readiness.ps1`

\- updated `scripts/start\_phase\_2\_stack.ps1`



\## Added startup readiness coverage

The startup path now:

\- waits for the known Phase 2 services to answer `/health`

\- verifies acceptable health status before continuing

\- fails fast if launched services are not actually ready



\## Covered services

\- `signal-gateway`

\- `session-engine`

\- `herald-service`

\- `eidon-orchestrator`



\## Why this matters

\- a service is not up because a window opened

\- startup should not claim success before health is real

\- this makes readiness part of startup truth instead of a later discovery



\## Current truth

This branch strengthens startup readiness only.



It does not:

\- change runtime behavior inside services

\- add new persistence fields

\- widen governance behavior

\- expand CI behavior

