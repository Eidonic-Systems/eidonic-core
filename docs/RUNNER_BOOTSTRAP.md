\# Runner Bootstrap



This document defines the expected local setup for a Phase 2 laptop or self-hosted runner.



\## Purpose

Reduce machine setup from tribal memory to a visible checklist.



\## Host expectations

A usable Phase 2 host should have:



\- Git on PATH

\- Python on PATH

\- Ollama on PATH

\- PostgreSQL client available

\- a repo root `.env`

\- service virtual environments present for:

&#x20; - `eidon-orchestrator`

&#x20; - `signal-gateway`

&#x20; - `session-engine`

&#x20; - `herald-service`



\## Required local models

The current local provider position expects:

\- `gemma3n:e4b`

\- `gemma3n:e2b`



These should be visible in:

\- `ollama list`



\## Repository setup

Expected repo root:

\- `C:\\eidonic\_core` on the dev PC

\- `C:\\eidonic-runner\\eidonic-core` on the runner laptop



Expected root files:

\- `.env`

\- `.env.example`



`.env.example` is only the template.

A real `.env` must exist.



\## PostgreSQL expectations

The current Phase 2 stack expects local PostgreSQL reachability and the `eidonic\_core` database.



The exact DSN and credentials are controlled by `.env`.



\## Service virtual environments

Each service is expected to have a local `.venv` with a working `python.exe`:



\- `services\\eidon-orchestrator\\.venv\\Scripts\\python.exe`

\- `services\\signal-gateway\\.venv\\Scripts\\python.exe`

\- `services\\session-engine\\.venv\\Scripts\\python.exe`

\- `services\\herald-service\\.venv\\Scripts\\python.exe`



\## Self-hosted runner notes

The current CI surface is a manual-only mirror of the local Phase 2 gate.



Current truth:

\- local gate is primary

\- GitHub Actions is secondary

\- the self-hosted runner should be treated as automation support, not core dependency



Expected runner labels:

\- `self-hosted`

\- `windows`

\- `eidonic-phase2`



Recommended runner mode:

\- manual `workflow\_dispatch`

\- manual `.\\run.cmd` or carefully managed service mode only after proven stable



\## Recommended bootstrap order

1\. clone or align the repo

2\. place the real `.env`

3\. verify Git, Python, Ollama, and PostgreSQL client

4\. ensure required Ollama models exist

5\. create service virtual environments

6\. create or verify the `eidonic\_core` database

7\. run `scripts/check\_phase2\_host\_bootstrap.ps1`

8\. run `scripts/run\_phase2\_gate.ps1`

9\. only after local proof, use the self-hosted runner for GitHub Actions



\## Host preflight command

Run this from repo root:



powershell -ExecutionPolicy Bypass -File .\\scripts\\check\_phase2\_host\_bootstrap.ps1



Optional runner folder check:



powershell -ExecutionPolicy Bypass -File .\\scripts\\check\_phase2\_host\_bootstrap.ps1 -CheckRunnerFolder



\## Current truth

A fresh machine should fail fast on missing prerequisites instead of wasting hours on blind setup.

