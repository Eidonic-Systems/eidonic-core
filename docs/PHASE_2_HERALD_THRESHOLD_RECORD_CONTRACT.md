# Phase 2 Herald Threshold Record Contract

This document records the first explicit threshold record contract for `herald-service`.

## Purpose
Make Herald threshold output persist as a real record instead of remaining only an in-flight response field.

## Current contract
The shared `ThresholdRecord` model now defines the current canonical shape for persisted threshold review records.

## Current storage
`services/herald-service/data/thresholds.json`

## Why this matters
- threshold review should exist as a retrievable record
- later review and provenance layers need durable threshold references
- the local JSON store is temporary, but the threshold shape should begin stabilizing now

## Current truth
This is only temporary local persistence.
The improvement here is structural: Herald threshold output now has an explicit shared record contract.
