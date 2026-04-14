# Governance Change Records Index

This document is the top-level index for governance change records in Eidonic Core.

## Purpose
Track governance rule changes as explicit decisions instead of leaving them only in PR history, terminal history, or memory.

## Scope
Governance change records should be written for changes to:
- `config/governance_rules_manifest.json`
- governance outcome coverage
- governance rule identity
- governance manifest versioning
- governance baseline resets that materially change expected behavior

## What a governance change record should state
Each record should name:
- what changed
- why it changed
- whether a rule was added, changed, removed, or renamed
- which outcomes were affected
- whether the governance eval baseline changed
- whether the governance manifest baseline changed
- what proof was run
- what remained intentionally unchanged

## Current discipline
A governance manifest change should not be treated as a casual config tweak.

It should have:
- a written governance change record
- matching code and manifest updates
- matching eval or baseline updates when required
- a PR that points back to the written decision

## Current records
- `docs/decision_records/GOVERNANCE_MANIFEST_CHANGE_RECORD_2026_04_13.md`

## Current truth
Governance changes are now expected to have an explicit decision layer, not just implementation history.
