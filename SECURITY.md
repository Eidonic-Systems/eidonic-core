# Security Policy

## Scope
This repository contains the current Phase 2 build surfaces for Eidonic Core.

## Reporting a vulnerability
Do not open public issues for suspected vulnerabilities.

Report security concerns privately to the repository owner through the available private reporting channel or direct maintainer contact.

Include:
- affected file or surface
- reproduction steps
- expected impact
- whether the issue affects local runtime, self-hosted runner trust, workflow trust, state integrity, or governance enforcement

## Current security posture
This repository uses:
- a local-first operational model
- a self-hosted Windows runner for the Phase 2 gate workflow
- explicit startup, gate, and bootstrap scripts
- manifest-backed operational and governance surfaces

Because self-hosted execution is a privileged trust boundary, workflow and runner hardening issues should be treated as high priority.

## Disclosure expectations
Please allow time for validation and remediation before public disclosure.
