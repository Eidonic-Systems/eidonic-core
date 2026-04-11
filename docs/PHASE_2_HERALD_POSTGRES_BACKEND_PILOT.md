# Phase 2 Herald Postgres Backend Pilot

This document records the second real durable-backend pilot in the Phase 2 scaffold.

## Purpose
Prove the existing ThresholdStore contract against PostgreSQL without changing HTTP behavior or widening the runtime scope.

## Backend strategy
- keep `LocalJsonThresholdStore`
- add `PostgresThresholdStore`
- select backend by environment variable
- keep the current routes and response shapes unchanged

## Why this matters
- threshold durability should be proven before moving outward to signal and orchestration stores
- Herald is the cleanest next seam after Session Engine
- this reduces architectural risk before rolling PostgreSQL across the rest of the chain

## Current truth
This branch introduces a real PostgreSQL-backed store only for Herald.
