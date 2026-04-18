# Phase 2 Repo Trust Surface

This document records the bounded repo trust scaffolding pass that follows the early build audit.

## Purpose
Make the repository trust posture more explicit and less dependent on assumption.

## What changed
- added `LICENSE`
- added `.github/dependabot.yml`
- tightened `.github/CODEOWNERS`

## Why this matters
- the audit correctly flagged repo trust scaffolding as incomplete or unconfirmed
- explicit ownership, explicit security reporting, explicit dependency update visibility, and explicit license posture reduce trust ambiguity
- this strengthens repo governance without changing runtime behavior

## Current truth
This branch improves repo trust posture only.

It does not:
- change runtime behavior
- change startup behavior
- change governance semantics
- change CI execution logic
