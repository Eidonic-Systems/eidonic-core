# Phase 2 Artifact Lineage Surface

This document records the first explicit lineage surface between sessions and Eidon orchestration artifacts.

## Purpose
Prevent sessions and artifacts from becoming isolated persisted objects by defining a simple reviewable lineage record.

## Current contract
The shared `ArtifactLineageRecord` model now defines the current lineage surface for Eidon outputs.

## What it links
- session ID
- signal ID
- artifact ID
- artifact kind
- artifact status
- artifact storage backend

## Current retrieval surface
`GET /lineage/{artifact_id}`

## Why this matters
- durable records should not become orphaned data
- later review, witness, and memory systems need a stable relational surface
- this is the first structural bridge between persisted session context and persisted output

## Current truth
This is still temporary local JSON persistence.
The improvement here is architectural: artifacts now have an explicit lineage surface.
