# Phase 2 Runner Trust Contract

This document defines the minimum trust assumptions and operating requirements for the self-hosted Phase 2 GitHub Actions runner.

## Scope

This trust contract applies to the workflow runner currently targeted by:
- `.github/workflows/phase2-gate.yml`
- runner labels: `self-hosted`, `windows`, `eidonic-phase2`

## Why this exists

The Phase 2 gate runs on a self-hosted Windows runner.

That runner is a privileged trust boundary.

The workflow already uses manual dispatch, minimal `contents: read` permissions, and pinned checkout, but those controls are not enough by themselves if the underlying runner is treated like a convenience machine instead of a controlled asset.

This document makes the runner assumptions explicit.

## Required trust posture

The Phase 2 runner must be treated as:
- repo-dedicated for Eidonic Core gate work
- a controlled build asset, not a general workstation
- a high-priority security boundary

## Minimum operating requirements

### 1. Dedicated use
- do not use the runner host for unrelated browsing, email, chat, or general daily work
- do not run unrelated development projects on the same host during gate execution windows

### 2. Controlled trigger posture
- keep the workflow manual-only unless a later hardening pass explicitly proves a broader trigger model is safe
- do not widen trigger scope casually

### 3. Minimal token and workflow authority
- keep workflow permissions minimal
- do not add write permissions or secret-dependent steps without a bounded review
- prefer explicit permissions over inherited defaults

### 4. Clean workspace discipline
- the runner workspace must start from a clean repo state
- do not rely on leftover local files from prior runs
- remove stale runtime artifacts and temp output after validation work

### 5. Secret handling discipline
- do not materialize secrets to ad hoc files unless the script explicitly requires it
- do not leave secrets in shell history, logs, scratch files, or desktop notes
- rotate any credential that is suspected to have landed in a persistent runner surface

### 6. Local privilege restraint
- do not treat local administrator rights as routine
- do not install unrelated privileged software on the runner host without need
- do not bypass PowerShell execution policy outside explicit repo scripts unless there is a reviewed reason

### 7. Network and dependency restraint
- outbound access should be limited to what Phase 2 validation actually requires
- do not add new external services to the gate path casually
- provider, package, and database dependencies should stay explicit and reviewable

### 8. Persistence awareness
- assume runner-local files, caches, and logs are persistent until explicitly removed
- do not assume self-hosted execution is ephemeral
- if ephemeral runner semantics are introduced later, document them explicitly rather than implying them

### 9. Failure and incident handling
- treat unexplained runner behavior as a trust event, not mere inconvenience
- if runner integrity is in doubt, stop using the host for gate work until it is reviewed
- security concerns affecting runner trust should be reported through the private channel named in `SECURITY.md`

## Current repo-aligned controls

The repo currently reflects these visible controls:
- manual workflow dispatch
- top-level `contents: read` workflow permission
- pinned `actions/checkout` commit SHA
- explicit Phase 2 gate entry script
- documented security posture acknowledging self-hosted trust risk

## What this document does not claim

This contract does not claim that the runner is:
- ephemeral
- sandboxed
- isolated by a strong host policy membrane
- protected by undocumented organization settings

If those controls exist later, they should be documented explicitly.

## Enforcement posture

This document is a governance truth surface.

It does not by itself prove host integrity.

It does define the minimum operating contract the repo expects builders to honor while the Phase 2 gate still depends on a self-hosted Windows runner.
