# Phase 2 Governance Rules Manifest Surface

This document records the extraction of the narrow governance enforcement pilot rules into an explicit manifest.

## Purpose
Make the current governance pilot rules visible and inspectable instead of burying them inline in code.

## What changed
- added `config/governance_rules_manifest.json`
- updated Orchestrator to load the narrow governance pilot rules from the manifest
- kept the current pilot behavior the same
- reused the current pilot integration test to prove behavior stayed stable

## Current manifest scope
- default success path remains `allow`
- explicit impersonation-style requests map to `refuse`
- explicit materially ambiguous command input maps to `hold`

## Why this matters
- visible rules are better than buried conditions
- the governance baseline can now protect manifest-backed behavior
- this keeps the pilot inspectable without pretending a full Guardian engine exists

## Current truth
This branch moves the current pilot rules into a visible manifest only. It does not widen enforcement scope.
