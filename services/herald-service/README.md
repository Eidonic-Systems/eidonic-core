# Herald Service

The Herald Service is the first thresholding service for Eidonic Core.

## Responsibility
- receive normalized signal input
- perform initial threshold review
- provide a first pass on whether a signal should proceed
- later hold clarification, consent, and escalation logic

## Current phase
Phase 1 scaffold only

## Current endpoints
- `GET /health`
- `POST /threshold/check`

## Notes
This service currently accepts and echoes valid threshold input.
Clarification, consent checks, sensitivity escalation, and route shaping are not implemented yet.
