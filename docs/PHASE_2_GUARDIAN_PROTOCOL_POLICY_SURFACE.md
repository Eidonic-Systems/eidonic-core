# Phase 2 Guardian Protocol Policy Surface

This document records the addition of the first explicit Guardian Protocol policy surface in Eidonic Core.

## Purpose
Define the Guardian Protocol in clear system terms before any runtime Guardian enforcement is introduced.

## What changed
- added `docs/GUARDIAN_PROTOCOL_POLICY.md`

## Why this matters
- the upstream Guardian Protocol source should not remain only symbolic or external
- future governance eval and enforcement work need a prior rule surface
- the repo should define Guardian modules and outcome classes before trying to automate them

## Current truth
Guardian Protocol now exists as explicit policy only.

It is not yet runtime-enforced.
It does not yet block live orchestration behavior.
It will inform future governance eval, provenance, and enforcement surfaces.
