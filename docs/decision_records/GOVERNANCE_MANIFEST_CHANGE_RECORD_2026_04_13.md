# Governance Manifest Change Record: 2026-04-13

## Record purpose
This record establishes the current governance manifest as a governed surface with explicit change-record expectations.

## What this record covers
This record covers the current manifest-backed governance pilot as it exists after:
- narrow governance enforcement pilot introduction
- manifest extraction
- governance rule provenance
- runtime outcome coverage for all six named governance outcomes
- governance eval baseline refresh
- governance manifest baseline introduction

## Current governed manifest truth
The current manifest governs a narrow runtime pilot that now covers:
- `allow`
- `reshape`
- `hold`
- `handoff`
- `refuse`
- `fallback`

The current manifest also has:
- explicit `rule_id` values
- explicit `manifest_version`
- persisted rule provenance
- a pinned manifest baseline

## Why a governance change record surface is needed
At this point, governance changes are no longer trivial.

Changing the manifest can alter:
- runtime behavior
- governance provenance
- baseline expectations
- the meaning of rule identity in artifact and lineage retrieval

That means future manifest edits should not be treated as casual config churn.

## Current decision
From this point forward, a material governance manifest change should have:
- a governance change record
- a PR that references that record
- matching baseline and provenance updates when required

## What counts as a material governance change
Examples:
- adding a rule
- removing a rule
- changing a rule's match patterns
- changing a rule's outcome
- changing a rule's reason
- changing default success behavior
- changing `manifest_version`
- changing runtime coverage expectations

## What does not automatically require a new record
Examples:
- typo-only corrections in documentation
- comment-only clarifications in surrounding docs
- non-material formatting changes that do not change manifest meaning

## What remains unchanged
This record does not:
- widen governance scope
- introduce new outcomes
- change enforcement behavior
- change the governance baseline
- change the governance manifest baseline

## Proof context
The current governance stack already has:
- policy surfaces
- eval surface
- governance provenance
- narrow enforcement
- rule provenance
- behavior baseline
- manifest baseline

This record adds the missing decision layer for future governance changes.
