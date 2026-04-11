# Phase 2 Signal Gateway Postgres Backend Pilot

This document records the third real durable-backend pilot in the Phase 2 scaffold.

## Purpose
Prove the existing SignalStore contract against PostgreSQL without changing HTTP behavior or widening the runtime scope.

## Backend strategy
- keep `LocalJsonSignalStore`
- add `PostgresSignalStore`
- select backend by environment variable
- keep the current routes and response shapes unchanged

## Why this matters
- ingress durability should be proven before moving outward to orchestrator stores
- Signal Gateway is the cleanest next seam after Herald
- this reduces architectural risk before rolling PostgreSQL across the rest of the chain

## Current truth
This branch introduces a real PostgreSQL-backed store only for Signal Gateway.
