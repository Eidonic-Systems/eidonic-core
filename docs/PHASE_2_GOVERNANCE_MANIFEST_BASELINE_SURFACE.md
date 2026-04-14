# Phase 2 Governance Manifest Baseline Surface

This document records the first pinned baseline for the governance rules manifest.

## Purpose
Freeze the current governance rules manifest so future rule changes can be compared against an explicit reference.

## What changed
- added `config/baselines/governance_rules_manifest_baseline.json`
- added `scripts/compare_governance_manifest_to_baseline.ps1`

## Why this matters
- behavior baselines are not enough if the rules file itself can drift silently
- manifest-backed enforcement should have a pinned manifest reference
- this makes structural rule changes explicit before they become surprising runtime changes

## Current truth
The governance rules manifest is now pinned as a first-class baseline.

This branch adds baseline and comparison only. It does not change governance behavior.
