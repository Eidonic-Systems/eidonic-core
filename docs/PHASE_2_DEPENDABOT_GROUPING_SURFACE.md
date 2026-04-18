# Phase 2 Dependabot Grouping Surface

This document records the first cleanup pass that turns Dependabot from PR spam into a bounded intake surface.

## Purpose
Reduce open update noise without blindly merging compatibility-sensitive framework and workflow upgrades.

## What changed
- updated `.github/dependabot.yml`

## Current policy
- version updates are grouped into fewer PRs
- open version-update PR volume is capped
- grouped updates still require deliberate review
- compatibility-sensitive framework changes are not auto-approved by grouping

## Why this matters
- the first Dependabot visibility pass created too many open PRs at once
- update visibility is useful, but noise without grouping wastes review attention
- this keeps Dependabot usable without pretending upgrades are risk-free
