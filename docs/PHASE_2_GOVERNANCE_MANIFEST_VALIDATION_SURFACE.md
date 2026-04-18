# Phase 2 Governance Manifest Validation Surface

This document records the first explicit validation surface for the governance rules manifest.

## Purpose
Fail clearly on malformed governance manifest shape before the pilot widens.

## What changed
- added `scripts/validate_governance_rules_manifest.ps1`

## What the script validates
- `manifest_version`
- `default_success_behavior`
- rule presence
- unique `rule_id`
- valid governance outcomes
- required `reason`
- required `response_text`
- required `match_patterns`

## Allowed outcomes
- `allow`
- `fallback`
- `refuse`
- `hold`
- `reshape`
- `handoff`

## Why this matters
- the governance pilot is explicit, but still brittle if the manifest shape is not validated
- malformed manifest state should fail directly instead of surfacing later through confusing behavior
- this is the first bounded hardening step before broader fixture coverage

## Current truth
This branch adds governance manifest validation only.

It does not:
- add new governance outcomes
- widen pilot semantics
- add fixture expansion
- change runtime behavior outside manifest validation
