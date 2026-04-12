# Phase 2 Domain Task Routing Provenance Surface

This document records the persistence of routing-choice provenance for the narrow domain-task routing pilot.

## Purpose
Persist not only which model handled a routed request, but also why that routing outcome occurred.

## What changed
- routing provenance now persists route mode and route reason
- artifact retrieval now surfaces:
  - `provider_route_mode`
  - `provider_route_reason`
- lineage retrieval now surfaces:
  - `artifact_provider_route_mode`
  - `artifact_provider_route_reason`

## Route modes
- `candidate`
- `control`
- `fallback`

## Route reasons
- `candidate_domain_route`
- `control_non_routeable`
- `control_fallback_after_candidate_failure`
- `control_default_no_routing`

## Why this matters
- a routing pilot without routing provenance is harder to trust and harder to debug
- persisted routing truth makes model selection explainable after the fact
- this keeps the routing pilot narrow while making it auditable

## Current truth
The domain-task routing pilot now persists why the chosen model was used, not only which model handled the request.
