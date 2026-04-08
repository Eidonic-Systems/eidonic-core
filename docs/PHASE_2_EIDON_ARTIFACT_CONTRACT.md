# Phase 2 Eidon Orchestration Artifact Contract

This document records the first explicit orchestration artifact contract for `eidon-orchestrator`.

## Purpose
Make orchestration output persist as a real artifact record instead of evaporating after the response.

## Current contract
The shared `EidonArtifactRecord` model now defines the current canonical shape for persisted orchestration artifacts.

## Current storage
`services/eidon-orchestrator/data/artifacts.json`

## Why this matters
- orchestration output should exist as a retrievable artifact
- later witness, review, and memory layers need durable output references
- the local JSON store is temporary, but the artifact shape should begin stabilizing now

## Current truth
This is only temporary local persistence.
The improvement here is structural: Eidon outputs now have an explicit shared artifact contract.
