# Phase 2 PostgreSQL Bootstrap Surface

This document records the first explicit bootstrap surface for the local Phase 2 PostgreSQL database.

## Purpose
Automate the repetitive database existence check and creation step for fresh local Phase 2 machines.

## What changed
- added `scripts/bootstrap_phase2_postgres.ps1`

## What the script does
- reads the repo `.env`
- finds a PostgreSQL DSN
- checks PostgreSQL reachability through `psql`
- checks whether the target database exists
- creates the target database if missing

## Why this matters
- fresh-machine setup still required manual database creation
- database creation is repetitive local setup work, not deep architecture
- this keeps the bootstrap explicit while removing one more avoidable friction point

## Current truth
This branch adds PostgreSQL bootstrap automation only.

It does not:
- generate `.env`
- install PostgreSQL
- pull Ollama models
- change runtime behavior
