# Signal Gateway

The Signal Gateway is the first ingress service for Eidonic Core.

## Responsibility
- receive incoming signals
- normalize them into SignalEvent objects
- reject malformed ingress
- pass valid signals to thresholding and session logic

## Current phase
Phase 1 scaffold only

## First contract
- SignalEvent schema v1
