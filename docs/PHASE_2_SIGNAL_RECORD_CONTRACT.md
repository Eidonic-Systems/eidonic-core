# Phase 2 Signal Record Contract

This document records the first explicit signal record contract for `signal-gateway`.

## Purpose
Make accepted ingress signals persist as real records instead of remaining only in-flight request payloads.

## Current contract
The shared `SignalRecord` model now defines the current canonical shape for persisted ingress signals.

## Current storage
`services/signal-gateway/data/signals.json`

## Why this matters
- accepted ingress should exist as a retrievable record
- later governance and review layers need durable ingress references
- the local JSON store is temporary, but the signal shape should begin stabilizing now

## Current truth
This is only temporary local persistence.
The improvement here is structural: accepted ingress now has an explicit shared record contract.
