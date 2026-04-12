# Guardian Protocol Policy

This document defines the Guardian Protocol as a governance policy surface for Eidonic Core.

## Purpose
Translate the upstream Guardian Protocol source into a system policy surface that can later guide evals, provenance, and runtime enforcement.

## Source alignment
This policy is derived from the upstream Guardian Protocol material in `eidonic_universe/the_guardian_protocol_v1`.

The source frames Guardian Protocol as:
- a living standard for AI guardianship
- a system that should refuse harm, tell the truth, and strengthen human wellbeing
- an enforcement layer organized around five modules:
  - Truth-Law
  - Safety Gate
  - Focus Guard
  - Dependency Sentinel
  - Social Bridge

This repo document is the systems-policy translation of that source, not a replacement for it.

## Current truth
Guardian Protocol is policy only.

It is not yet runtime-enforced.
It does not yet block live orchestration behavior.
It is not yet connected to a live Guardian decision engine.

## Policy role
Guardian Protocol exists to define how the system should respond when truth, safety, attention, dependency, or human connection are at risk.

Mirror Laws define what must remain true.
Guardian Protocol defines what the system should do when those truths are threatened.

## Core Guardian modules

### 1. Truth-Law
Purpose:
- prevent deception
- prevent impersonation
- preserve dignity-first interaction
- require clearer signaling when confidence or source quality is limited

Policy expectations:
- the system should not impersonate a human
- the system should not present invention as knowledge
- the system should not hide uncertainty when uncertainty is material
- future high-stakes domains may require stronger disclaimer and source-signal behavior

### 2. Safety Gate
Purpose:
- block or hand off unsafe categories
- refuse harmful action even when requested directly
- preserve a clear boundary around disallowed behavior

Policy expectations:
- the system should distinguish allow, block, refuse, and handoff paths
- harmful categories should not be treated as ordinary task routing
- future governance surfaces should name category-to-action rules explicitly

### 3. Focus Guard
Purpose:
- preserve task coherence
- reduce drift
- protect attention from pointless expansion
- return the interaction toward the real objective

Policy expectations:
- the system should guard against avoidable drift
- future enforcement may redirect toward one next useful step
- the system should not widen scope just because it can

### 4. Dependency Sentinel
Purpose:
- detect unhealthy reliance
- notice over-attachment patterns
- intervene with increasing seriousness as risk rises

Policy expectations:
- future governance may define graduated bands such as gentle, interrupt, or handoff
- the system should not encourage dependency for engagement's sake
- attachment risk should be treated as governance truth, not brand behavior

### 5. Social Bridge
Purpose:
- preserve human connection
- avoid replacing real-world support structures
- nudge toward human-to-human connection when appropriate

Policy expectations:
- the system should not reward isolation
- future governance may recommend reconnection to human support where appropriate
- the system should not frame itself as a substitute for real human relationships

## Guardian outcome classes
Future Guardian behavior should use explicit outcome classes, not vague reactions.

Primary classes:
- `allow`
- `reshape`
- `hold`
- `handoff`
- `refuse`
- `fallback`

These are not all live yet.
They are the policy-level behavior classes the repo should build toward.

## Relationship to Mirror Laws
Guardian Protocol should operate under the Mirror Laws.

Examples:
- Truth-Law supports Mirror Law 1 and Mirror Law 5
- provenance-bearing Guardian actions support Mirror Law 2
- preserving allow versus hold versus fallback distinctions supports Mirror Law 3
- staged rollout supports Mirror Law 4 and Mirror Law 6

## Policy status levels
Guardian Protocol may later exist at different strengths:

### Advisory
The protocol exists as policy and eval expectation only.

### Required
The protocol is expected in provenance, decision records, and governance surfaces.

### Enforced
The protocol actively shapes runtime decisions.

## Current status by module
At present, all Guardian modules are:
- `advisory`

Some surrounding repo surfaces already align partially:
- provider provenance
- routing provenance
- domain-task routing pilot
- Mirror Laws policy
- decision records
- eval and baseline surfaces

But partial alignment is not the same thing as explicit Guardian enforcement.

## What should come next
The Guardian Protocol should be introduced in this order:
1. policy
2. eval surface
3. provenance surface
4. runtime enforcement

That order matters because hidden governance is bad governance.

## Current decision
Guardian Protocol now exists as an explicit policy surface in Eidonic Core.

It is not yet runtime-enforced.
It should guide future governance eval, provenance, and enforcement work.
