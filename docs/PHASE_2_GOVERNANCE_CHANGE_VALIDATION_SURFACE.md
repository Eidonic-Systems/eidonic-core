# Phase 2 Governance Change Validation Surface

This document records the first validation surface for governance manifest change discipline.

## Purpose
Fail cleanly when the governance manifest changes materially without the expected decision layer.

## What changed
- added `scripts/validate_governance_manifest_change.ps1`

## What the validation checks
- whether the current manifest differs from the pinned manifest baseline
- whether `manifest_version` changed
- whether at least one governance change record mentions the current manifest version
- which rule ids were added, removed, or changed

## Validation rule
If the manifest changed materially, the validation expects:
- a manifest version change
- at least one matching governance change record for the current manifest version

## Why this matters
- governance change records are now expected, not optional
- manifest changes should not pass quietly as casual config edits
- this turns governance decision discipline into an explicit repo check

## Current truth
This branch adds governance change validation only. It does not modify governance behavior or the current manifest baseline.
