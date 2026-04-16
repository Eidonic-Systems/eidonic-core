\# Phase 2 Startup Topology Surface



This document records the point where the Phase 2 startup path began launching services from the shared service topology manifest.



\## Purpose

Make startup, readiness, and restart all depend on the same declared service topology surface.



\## What changed

\- updated `config/service\_topology\_manifest.json`

\- updated `scripts/start\_phase\_2\_stack.ps1`



\## Added topology fields

The service topology manifest now declares startup launch truth for each service:

\- `startup\_name`

\- `startup\_workdir`

\- `startup\_command`



\## Why this matters

\- startup should not hardcode launch behavior while readiness and restart use a manifest

\- operational truth is stronger when startup, readiness, and restart all read one declared topology surface

\- this reduces operational drift without changing runtime behavior inside services



\## Current truth

This branch strengthens startup topology discipline only.



It does not:

\- change runtime behavior inside services

\- add new persistence fields

\- widen governance behavior

\- expand CI behavior

