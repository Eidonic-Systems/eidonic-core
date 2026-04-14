# Phase 2 Governance Change Record Surface

This document records the addition of a decision layer for future governance manifest changes.

## Purpose
Ensure governance changes are explained as explicit decisions instead of living only in implementation diffs or PR history.

## What changed
- added `docs/GOVERNANCE_CHANGE_RECORDS_INDEX.md`
- added `docs/decision_records/GOVERNANCE_MANIFEST_CHANGE_RECORD_2026_04_13.md`

## Why this matters
- governance config is no longer casual config
- manifest changes can alter runtime behavior, provenance, and baseline expectations
- the repo now needs a written decision layer for governance changes

## Current truth
This branch adds governance change-record discipline only.

It does not change:
- governance rules
- runtime behavior
- governance baseline
- governance manifest baseline
