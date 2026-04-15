# Session Log

## 2026-04-04
- Created Eidonic Systems organization
- Created eidonic-core repository
- Created setup/initial-scaffold branch
- Next step: upload initial scaffold and create first pull request

## 2026-04-04
- Merged initial scaffold into main
- Created phase-1/signal-schema-and-service-scaffold branch
- Added SignalEvent schema v1
- Updated signal-gateway README
- Updated technical stack notes and checklist
- Next step: open PR for first Phase 1 artifact

## 2026-04-04
- Created branch `phase-1/signal-gateway-fastapi-scaffold`
- Added initial FastAPI scaffold for `signal-gateway`
- Added Python dependencies for the service
- Updated `signal-gateway` README with current endpoints and scope
- Marked `signal-gateway` scaffold as complete in the build checklist
- Next step: open PR for the first executable service shell

## 2026-04-04
- Created branch `phase-1/gitignore-and-local-run-docs`
- Added a root `.gitignore` for Python and local environment files
- Documented local run steps for `signal-gateway`
- Confirmed the service runs locally with Uvicorn
- Next step: open PR for repo hygiene and local run documentation

## 2026-04-04
- Added sample SignalEvent payload for manual ingest testing
- Documented manual ingest testing in the `signal-gateway` README
- Fixed `signal-gateway` README formatting and clarified local run and test instructions
- Confirmed manual ingest passed locally against the real cloned repo
- Next step: bring local Git workflow into sync and continue Phase 1 service scaffolds

## 2026-04-04
- Created branch `phase-1/herald-service-fastapi-scaffold`
- Added initial FastAPI scaffold for `herald-service`
- Added Python dependencies for the service
- Added `herald-service` README
- Marked `herald-service` scaffold as complete in the build checklist
- Next step: open PR for the first thresholding service shell

## 2026-04-06
- Ran `herald-service` locally from the real cloned repo
- Confirmed `/threshold/check` passed with a manual payload
- Next step: scaffold the session engine

## 2026-04-06
- Created branch `phase-1/session-engine-fastapi-scaffold`
- Added initial FastAPI scaffold for `session-engine`
- Added Python dependencies for the service
- Added `session-engine` README
- Marked `session-engine` scaffold as complete in the build checklist
- Next step: open PR for the first session binding service shell

## 2026-04-06
- Ran `session-engine` locally from the real cloned repo
- Confirmed `/sessions/start` passed with a manual payload
- Next step: scaffold the Eidon orchestrator

## 2026-04-07
- Created branch `phase-1/eidon-orchestrator-fastapi-scaffold`
- Added initial FastAPI scaffold for `eidon-orchestrator`
- Added Python dependencies for the service
- Added `eidon-orchestrator` README
- Marked `eidon-orchestrator` scaffold as complete in the build checklist
- Next step: open PR for the first orchestration service shell

## 2026-04-07
- Verified `eidon-orchestrator` runs locally on port 8003
- Verified manual orchestration request passes with required fields
- Created branch `phase-1/core-loop-manual-test-pack`
- Added manual test payloads for Herald, Session Engine, and Eidon Orchestrator
- Added Phase 1 core loop manual test document
- Next step: open PR for the first complete manual test pack

## 2026-04-07
- Synced local `main` with `origin/main`
- Verified local repo is clean and connected to GitHub
- Created branch `phase-1/core-loop-local-runner-script`
- Added `scripts/test_phase_1_core_loop.ps1` for the first local end-to-end Phase 1 service checks
- Updated `scripts/README.md` with local runner instructions
- Next step: open PR for the first scripted local core loop runner

## 2026-04-07
- Created branch `phase-1/shared-python-schemas`
- Added shared Python schema package under `packages/common-schemas/python`
- Refactored service request models to import from `eidonic_schemas`
- Updated service requirements to install the shared package in editable mode
- Added `packages/common-schemas/README.md`
- Next step: open PR for the first shared Python schema package

## 2026-04-07
- Created branch `phase-2/gateway-to-herald-http-chain`
- Added the first live HTTP handoff from `signal-gateway` to `herald-service`
- Updated `signal-gateway` requirements to include `httpx`
- Updated `signal-gateway` README for the first downstream chain behavior
- Added `docs/PHASE_2_GATEWAY_TO_HERALD_CHAIN.md`
- Next step: open PR for the first real service-to-service link in the core spine

## 2026-04-07
- Created branch phase-2/full-chain-integration-test
- Added 	ests/integration/test_full_chain.ps1
- Added 	ests/README.md
- Next step: open PR for the first automated full-chain integration test

## 2026-04-07
- Created branch phase-2/full-chain-integration-test
- Added 	ests/integration/test_full_chain.ps1
- Added 	ests/README.md
- Next step: open PR for the first automated full-chain integration test

## 2026-04-07
- Created branch `phase-2/environment-config-for-chain`
- Added root `.env.example` with downstream service URLs
- Updated `.gitignore` to ignore local `.env` files
- Updated `signal-gateway` to load downstream URLs from a repo root `.env` file when present
- Added `python-dotenv` to `signal-gateway` dependencies
- Updated `signal-gateway` README for environment configuration
- Next step: open PR for the first environment config layer

## 2026-04-07
- Created branch `phase-2/local-stack-launcher`
- Added `scripts/start_phase_2_stack.ps1`
- Updated `scripts/README.md` with stack launcher instructions
- Next step: open PR for the first local stack launcher

## 2026-04-08
- Created branch `phase-2/session-engine-local-persistence`
- Added a temporary local JSON persistence layer to `session-engine`
- Added `GET /sessions/{session_id}` for simple retrieval
- Added `docs/PHASE_2_SESSION_ENGINE_LOCAL_PERSISTENCE.md`
- Updated `.gitignore` for local session data
- Updated `session-engine` README for local persistence
- Next step: open PR for the first real session persistence layer

## 2026-04-08
- Created branch `phase-2/integration-test-session-persistence`
- Extended `tests/integration/test_full_chain.ps1` to verify persisted session lookup
- Updated `tests/README.md` for session persistence coverage
- Next step: open PR for persistence-aware full-chain integration testing

## 2026-04-08
- Created branch `phase-2/session-record-contract`
- Added shared `SessionRecord` model to `eidonic_schemas`
- Refactored `session-engine` to build and store explicit session records through the shared contract
- Added `docs/PHASE_2_SESSION_RECORD_CONTRACT.md`
- Updated `session-engine` README for the session record contract step
- Next step: open PR for the first explicit session record contract

## 2026-04-08
- Created branch `phase-2/session-store-adapter`
- Added `SessionStore` and `LocalJsonSessionStore` to `session-engine`
- Refactored `session-engine` to use a store adapter instead of direct JSON file mechanics
- Added `docs/PHASE_2_SESSION_STORE_ADAPTER.md`
- Updated `session-engine` README for the store adapter step
- Next step: open PR for the first session store adapter boundary

## 2026-04-08
- Created branch `phase-2/postgres-ready-session-store-contract`
- Expanded the `SessionStore` contract surface for a future Postgres backend
- Updated `LocalJsonSessionStore` to implement `backend_name`, `list_recent`, and `ping`
- Updated `session-engine` to use the richer store contract surface
- Added `docs/PHASE_2_POSTGRES_READY_SESSION_STORE_CONTRACT.md`
- Updated `session-engine` README for the Postgres-ready contract step
- Next step: open PR for the Postgres-ready session store contract surface

## 2026-04-08
- Created branch `phase-2/eidon-orchestration-artifact-contract`
- Added shared `EidonArtifactRecord` model to `eidonic_schemas`
- Added temporary local JSON persistence for `eidon-orchestrator` outputs
- Added `GET /artifacts/{artifact_id}` for simple artifact retrieval
- Added `docs/PHASE_2_EIDON_ARTIFACT_CONTRACT.md`
- Updated `eidon-orchestrator` README for the artifact contract step
- Next step: open PR for the first explicit orchestration artifact contract

## 2026-04-08
- Created branch `phase-2/integration-test-artifact-persistence`
- Extended `tests/integration/test_full_chain.ps1` to verify persisted artifact lookup
- Updated `tests/README.md` for artifact persistence coverage
- Next step: open PR for artifact-aware full-chain integration testing

## 2026-04-08
- Created branch `phase-2/artifact-lineage-surface`
- Added shared `ArtifactLineageRecord` model to `eidonic_schemas`
- Added temporary local JSON persistence for Eidon artifact lineage records
- Added `GET /lineage/{artifact_id}` for lineage retrieval
- Added `docs/PHASE_2_ARTIFACT_LINEAGE_SURFACE.md`
- Updated `eidon-orchestrator` README for the lineage surface step
- Next step: open PR for the first artifact lineage surface

## 2026-04-09
- Created branch `phase-2/orchestrator-list-surfaces`
- Added `GET /artifacts` to list persisted orchestrator artifacts
- Added `GET /lineage` to list persisted orchestrator lineage records
- Extended orchestrator store adapters with list semantics
- Updated `services/eidon-orchestrator/README.md`
- Added `docs/PHASE_2_ORCHESTRATOR_LIST_SURFACES.md`
- Next step: open PR for orchestrator list surfaces

## 2026-04-09
- Created branch `phase-2/integration-test-orchestrator-list-surfaces`
- Extended the full integration test to verify `GET /artifacts`
- Extended the full integration test to verify `GET /lineage`
- Added `docs/PHASE_2_INTEGRATION_TEST_ORCHESTRATOR_LIST_SURFACES.md`
- Next step: open PR for orchestrator list surface integration proof

## 2026-04-09
- Created branch `phase-2/herald-threshold-record-contract`
- Added shared `ThresholdRecord` model to `eidonic_schemas`
- Added temporary local JSON persistence for `herald-service` threshold results
- Added `GET /thresholds/{signal_id}` for threshold record retrieval
- Added `docs/PHASE_2_HERALD_THRESHOLD_RECORD_CONTRACT.md`
- Updated `services/herald-service/README.md` for the threshold contract step
- Next step: open PR for the first explicit Herald threshold record contract

## 2026-04-09
- Created branch `phase-2/integration-test-herald-threshold-record`
- Extended the full integration test to verify `GET /thresholds/{signal_id}`
- Added `docs/PHASE_2_INTEGRATION_TEST_HERALD_THRESHOLD_RECORD.md`
- Next step: open PR for Herald threshold record integration proof

## 2026-04-09
- Created branch `phase-2/herald-list-surfaces`
- Added `GET /thresholds` to list persisted Herald threshold records
- Extended Herald threshold store with list semantics
- Updated `services/herald-service/README.md`
- Added `docs/PHASE_2_HERALD_LIST_SURFACES.md`
- Next step: open PR for Herald list surfaces

## 2026-04-09
- Created branch `phase-2/integration-test-herald-list-surfaces`
- Extended the full integration test to verify `GET /thresholds`
- Added `docs/PHASE_2_INTEGRATION_TEST_HERALD_LIST_SURFACES.md`
- Next step: open PR for Herald list surface integration proof

## 2026-04-09
- Created branch `phase-2/signal-record-contract`
- Added shared `SignalRecord` model to `eidonic_schemas`
- Added temporary local JSON persistence for `signal-gateway` accepted ingress records
- Added `GET /signals/{signal_id}` for signal record retrieval
- Added `docs/PHASE_2_SIGNAL_RECORD_CONTRACT.md`
- Updated `services/signal-gateway/README.md` for the signal contract step
- Next step: open PR for the first explicit signal record contract

## 2026-04-09
- Created branch `phase-2/integration-test-signal-record`
- Extended the full integration test to verify `GET /signals/{signal_id}`
- Added `docs/PHASE_2_INTEGRATION_TEST_SIGNAL_RECORD.md`
- Next step: open PR for signal record integration proof

## 2026-04-09
- Created branch `phase-2/signal-store-contract-surface`
- Added `services/signal-gateway/app/store.py`
- Extracted signal persistence behind a `SignalStore`
- Updated `services/signal-gateway/app/main.py` to use the store adapter
- Updated `services/signal-gateway/README.md`
- Next step: open PR for signal store contract surface

## 2026-04-09
- Created branch `phase-2/signal-list-surfaces`
- Added `GET /signals` to list persisted signal records
- Extended signal store with list semantics
- Updated `services/signal-gateway/README.md`
- Added `docs/PHASE_2_SIGNAL_LIST_SURFACES.md`
- Next step: open PR for signal list surfaces

## 2026-04-09
- Created branch `phase-2/integration-test-signal-list-surfaces`
- Extended the full integration test to verify `GET /signals`
- Added `docs/PHASE_2_INTEGRATION_TEST_SIGNAL_LIST_SURFACES.md`
- Next step: open PR for signal list surface integration proof

## 2026-04-09
- Created branch `phase-2/integration-test-session-list-surfaces`
- Extended the full integration test to verify `GET /sessions`
- Added `docs/PHASE_2_INTEGRATION_TEST_SESSION_LIST_SURFACES.md`
- Next step: open PR for session list surface integration proof

## 2026-04-09
- Created branch `phase-2/repo-truth-surface-sync`
- Updated root `README.md` to reflect the proven Phase 2 scaffold truth
- Updated `AGENTS.md` to reflect current build discipline and proven surfaces
- Added `docs/PHASE_2_REPO_TRUTH_SURFACE_SYNC.md`
- Next step: open PR for repo truth surface sync

## 2026-04-09
- Created branch `phase-2/integration-test-health-surfaces`
- Extended the full integration test to verify service health surfaces
- Added `docs/PHASE_2_INTEGRATION_TEST_HEALTH_SURFACES.md`
- Next step: open PR for service health surface integration proof

## 2026-04-09
- Created branch `phase-2/proof-surface-sync`
- Updated root `README.md` to include service health surfaces in the current integration proof
- Added `docs/PHASE_2_PROOF_SURFACE_SYNC.md`
- Next step: open PR for proof surface sync

## 2026-04-09
- Created branch `phase-2/herald-postgres-ready-store-contract`
- Hardened `ThresholdStore` with `list_recent(limit)` semantics
- Kept local JSON as the active Herald store implementation
- Updated `services/herald-service/app/main.py` to use the mature store contract surface
- Updated `services/herald-service/README.md`
- Added `docs/PHASE_2_HERALD_POSTGRES_READY_STORE_CONTRACT.md`
- Next step: open PR for Herald Postgres-ready store contract surface

## 2026-04-09
- Created branch `phase-2/signal-postgres-ready-store-contract`
- Hardened `SignalStore` with `list_recent(limit)` semantics
- Kept local JSON as the active Signal Gateway store implementation
- Updated `services/signal-gateway/app/main.py` to use the mature store contract surface
- Updated `services/signal-gateway/README.md`
- Added `docs/PHASE_2_SIGNAL_POSTGRES_READY_STORE_CONTRACT.md`
- Next step: open PR for Signal Gateway Postgres-ready store contract surface

## 2026-04-09
- Created branch `phase-2/orchestrator-postgres-ready-store-contract`
- Hardened orchestrator store contracts with `list_recent(limit)` semantics
- Kept local JSON as the active orchestrator store implementation
- Updated `services/eidon-orchestrator/app/main.py` to use the mature store contract surfaces
- Updated `services/eidon-orchestrator/README.md`
- Added `docs/PHASE_2_ORCHESTRATOR_POSTGRES_READY_STORE_CONTRACT.md`
- Next step: open PR for Orchestrator Postgres-ready store contract surface

## 2026-04-09
- Created branch `phase-2/integration-test-list-limit-surfaces`
- Extended the full integration test to verify `limit=1` behavior across current list surfaces
- Added `docs/PHASE_2_INTEGRATION_TEST_LIST_LIMIT_SURFACES.md`
- Next step: open PR for list limit surface integration proof

## 2026-04-10
- Created branch `phase-2/herald-postgres-backend-pilot`
- Added `PostgresThresholdStore` for the second real durable-backend pilot
- Kept `LocalJsonThresholdStore` as fallback
- Added backend selection through environment variables
- Updated `services/herald-service/README.md`
- Added `docs/PHASE_2_HERALD_POSTGRES_BACKEND_PILOT.md`
- Next step: prove Herald against local PostgreSQL

## 2026-04-10
- Created branch `phase-2/signal-gateway-postgres-backend-pilot`
- Added `PostgresSignalStore` for the third real durable-backend pilot
- Kept `LocalJsonSignalStore` as fallback
- Added backend selection through environment variables
- Updated `services/signal-gateway/README.md`
- Added `docs/PHASE_2_SIGNAL_GATEWAY_POSTGRES_BACKEND_PILOT.md`
- Next step: prove Signal Gateway against local PostgreSQL

## 2026-04-10
- Created branch `phase-2/orchestrator-postgres-backend-pilot`
- Added PostgreSQL artifact and lineage stores for the fourth real durable-backend pilot
- Kept local JSON artifact and lineage stores as fallback
- Added backend selection through environment variables
- Updated `services/eidon-orchestrator/README.md`
- Added `docs/PHASE_2_ORCHESTRATOR_POSTGRES_BACKEND_PILOT.md`
- Next step: prove Orchestrator against local PostgreSQL

## 2026-04-10
- Created branch `phase-2/postgres-state-spine-truth-sync`
- Updated top-level repo docs to reflect the PostgreSQL-backed Phase 2 state spine
- Updated `.env.example` to reflect current proven backend defaults
- Updated service READMEs to reflect PostgreSQL-backed primary persistence with local JSON fallback
- Added `docs/PHASE_2_POSTGRES_STATE_SPINE_TRUTH_SYNC.md`
- Next step: open PR for PostgreSQL state spine truth sync

## 2026-04-10
- Created branch `phase-2/postgres-state-spine-truth-surface-finish`
- Updated `AGENTS.md` to reflect PostgreSQL-backed verified persistence
- Updated `.env.example` to set PostgreSQL-backed defaults across the full Phase 2 chain
- Updated Session Engine, Herald, and Signal Gateway READMEs to reflect PostgreSQL-backed current truth
- Added `docs/PHASE_2_POSTGRES_STATE_SPINE_TRUTH_SURFACE_FINISH.md`
- Next step: open PR for PostgreSQL state spine truth surface finish

## 2026-04-10
- Created branch `phase-2/model-provider-contract-surface`
- Added `services/eidon-orchestrator/app/provider.py`
- Routed Orchestrator response generation through a provider contract surface
- Added stub provider selection through environment variables
- Updated `services/eidon-orchestrator/README.md`
- Added `docs/PHASE_2_MODEL_PROVIDER_CONTRACT_SURFACE.md`
- Next step: prove Orchestrator still passes with the stub provider contract in place

## 2026-04-10
- Created branch `phase-2/integration-test-provider-surface`
- Extended the full integration test to verify the Orchestrator provider health surface
- Added `docs/PHASE_2_INTEGRATION_TEST_PROVIDER_SURFACE.md`
- Next step: open PR for provider surface integration proof

## 2026-04-11
- Created branch `phase-2/ollama-provider-adapter-pilot`
- Added `OllamaModelProvider` for the first real local model adapter
- Kept `StubModelProvider` as fallback
- Updated Orchestrator to route response generation through Ollama when selected
- Updated `.env.example` with Ollama provider settings
- Updated `services/eidon-orchestrator/README.md`
- Added `docs/PHASE_2_OLLAMA_PROVIDER_ADAPTER_PILOT.md`
- Next step: prove the full chain with Ollama-backed generation

## 2026-04-11
- Created branch `phase-2/provider-provenance-contract`
- Added provider provenance fields to artifact and lineage contracts
- Updated Orchestrator persistence to store provider backend and provider model
- Updated Orchestrator retrieval surfaces to expose persisted provider provenance
- Added `docs/PHASE_2_PROVIDER_PROVENANCE_CONTRACT.md`
- Next step: prove provider provenance appears in artifact and lineage retrieval

## 2026-04-11
- Created branch `phase-2/integration-test-provider-provenance-surface`
- Extended the full integration test to verify persisted provider provenance in artifact and lineage retrieval
- Added `docs/PHASE_2_INTEGRATION_TEST_PROVIDER_PROVENANCE_SURFACE.md`
- Next step: open PR for provider provenance surface integration proof

## 2026-04-11
- Created branch `phase-2/provider-failure-semantics`
- Added explicit provider failure classes in the Orchestrator provider layer
- Persisted provider failure truth in artifact and lineage records
- Updated Orchestrator to return structured `provider_failed` responses instead of vague generic failures
- Added `docs/PHASE_2_PROVIDER_FAILURE_SEMANTICS.md`
- Next step: prove happy-path stability and one controlled provider failure path

## 2026-04-11
- Created branch `phase-2/integration-test-provider-failure-surface`
- Added focused integration coverage for the controlled provider-failure path
- Added `tests/integration/test_provider_failure_surface.ps1`
- Added `docs/PHASE_2_INTEGRATION_TEST_PROVIDER_FAILURE_SURFACE.md`
- Next step: open PR for provider failure surface integration proof

## 2026-04-11
- Created branch `phase-2/provider-cold-start-timeout-hardening`
- Added configurable per-downstream timeouts in Signal Gateway
- Kept Herald and Session Engine on tight defaults
- Increased default Orchestrator timeout to better tolerate local-model cold starts
- Updated `services/signal-gateway/README.md`
- Added `docs/PHASE_2_PROVIDER_COLD_START_TIMEOUT_HARDENING.md`
- Next step: prove the chain remains healthy with hardened timeout defaults

## 2026-04-11
- Created branch `phase-2/provider-warmup-surface`
- Added provider warmup capability and readiness reporting in Orchestrator
- Added `POST /provider/warm`
- Added `scripts/warm_eidon_provider.ps1`
- Updated `services/eidon-orchestrator/README.md`
- Added `docs/PHASE_2_PROVIDER_WARMUP_SURFACE.md`
- Next step: prove readiness transitions from false to true through the warmup surface

## 2026-04-11
- Created branch `phase-2/integration-test-provider-warmup-surface`
- Added focused integration coverage for the Orchestrator provider warmup and readiness surface
- Added `tests/integration/test_provider_warmup_surface.ps1`
- Added `docs/PHASE_2_INTEGRATION_TEST_PROVIDER_WARMUP_SURFACE.md`
- Next step: open PR for provider warmup surface integration proof

## 2026-04-11
- Created branch `phase-2/stack-provider-warmup-sequence`
- Updated the Phase 2 stack launcher to wait for health and warm the Eidon provider automatically
- Added clear startup failure behavior when provider warmup fails
- Updated `README.md` to reflect the standard warmup startup sequence
- Added `docs/PHASE_2_STACK_PROVIDER_WARMUP_SEQUENCE.md`
- Next step: prove stack startup now warms the provider automatically

## 2026-04-11
- Created branch `phase-2/integration-test-provider-warmup-failure-surface`
- Added focused integration coverage for the controlled provider warmup failure path
- Added `tests/integration/test_provider_warmup_failure_surface.ps1`
- Added `docs/PHASE_2_INTEGRATION_TEST_PROVIDER_WARMUP_FAILURE_SURFACE.md`
- Next step: open PR for provider warmup failure surface integration proof

## 2026-04-11
- Created branch `phase-2/local-runtime-preflight-surface`
- Added `scripts/check_phase_2_runtime_prereqs.ps1`
- Added explicit local runtime preflight for env keys, PostgreSQL reachability, Ollama reachability, configured model presence, and Orchestrator Python presence
- Updated `README.md` to include the preflight step in the standard local workflow
- Added `docs/PHASE_2_LOCAL_RUNTIME_PREFLIGHT_SURFACE.md`
- Next step: prove the preflight passes before normal stack startup

## 2026-04-11
- Created branch `phase-2/stack-runtime-preflight-sequence`
- Updated the Phase 2 stack launcher to run runtime preflight before opening service windows
- Startup now fails fast if preflight fails
- Updated `README.md` to reflect enforced startup preflight
- Added `docs/PHASE_2_STACK_RUNTIME_PREFLIGHT_SEQUENCE.md`
- Next step: prove stack startup now enforces runtime preflight before boot

## 2026-04-11
- Created branch `phase-2/provider-runtime-truth-sync`
- Updated `AGENTS.md` to reflect the current proven provider/runtime state
- Updated `services/eidon-orchestrator/README.md` to reflect provenance, failure semantics, warmup, and readiness
- Added `docs/CANONICAL_EXTERNAL_REFERENCES.md` as a bridge to the larger external canon
- Added `docs/PHASE_2_PROVIDER_RUNTIME_TRUTH_SYNC.md`
- Next step: open PR for narrow provider/runtime truth sync

## 2026-04-11
- Created branch `phase-2/local-provider-eval-baseline`
- Added `evals/baselines/local_provider_eval_baseline.json`
- Added `scripts/compare_local_provider_eval_to_baseline.ps1`
- Added the first pinned baseline for the local provider eval surface
- Added `docs/PHASE_2_LOCAL_PROVIDER_EVAL_BASELINE.md`
- Next step: prove current eval output matches the pinned baseline

## 2026-04-11
- Created branch `phase-2/local-provider-candidate-comparison`
- Added `scripts/run_local_provider_candidate_eval.ps1`
- Added isolated candidate comparison workflow for alternate local provider models
- Candidate comparison now writes results under `evals/candidates` and compares them to the pinned baseline
- Added `docs/PHASE_2_LOCAL_PROVIDER_CANDIDATE_COMPARISON.md`
- Next step: prove one candidate comparison run without changing the live default model

## 2026-04-11
- Created branch `phase-2/gemma-family-model-policy`
- Updated `AGENTS.md` to define Gemma as the primary local model family
- Added `docs/GEMMA_FAMILY_MODEL_POLICY.md`
- Added `docs/PHASE_2_GEMMA_FAMILY_MODEL_POLICY.md`
- Next step: open PR for Gemma-family-centered model policy

## 2026-04-11
- Created branch `phase-2/measurement-and-policy-truth-sync`
- Updated `README.md` to reflect local measurement surfaces and Gemma-family model policy
- Added `docs/PHASE_2_MEASUREMENT_AND_POLICY_TRUTH_SYNC.md`
- Next step: open PR for measurement and policy truth sync

## 2026-04-11
- Created branch `phase-2/runtime-artifact-gitignore-hygiene`
- Updated `.gitignore` to ignore generated local eval outputs
- Kept eval cases and pinned baselines as tracked source artifacts
- Added `docs/PHASE_2_RUNTIME_ARTIFACT_GITIGNORE_HYGIENE.md`
- Next step: open PR for runtime artifact gitignore hygiene

## 2026-04-11
<<<<<<< Updated upstream
- Created branch `phase-2/provider-plain-text-response-guard`
- Updated the Ollama provider path to require and normalize plain-text responses
- Added `docs/PHASE_2_PROVIDER_PLAIN_TEXT_RESPONSE_GUARD.md`
- Updated `services/eidon-orchestrator/README.md`
- Next step: prove the default model no longer leaks wrapper-style formatting in the command response path
=======
- Created branch `phase-2/local-provider-eval-drift-guards`
- Hardened the local provider eval surface against identity, formatting, and encoding drift
- Updated `evals/local_provider_eval_cases.json`
- Updated `scripts/run_local_provider_eval.ps1`
- Added `docs/PHASE_2_LOCAL_PROVIDER_EVAL_DRIFT_GUARDS.md`
- Next step: prove the current default model still passes the strengthened eval surface or expose the specific drift that must be corrected
>>>>>>> Stashed changes

## 2026-04-11
- Created branch `phase-2/gemma-routing-policy-surface`
- Added `docs/GEMMA_ROUTING_POLICY.md`
- Added `docs/PHASE_2_GEMMA_ROUTING_POLICY_SURFACE.md`
- Defined future Gemma-family routing rules without introducing runtime routing behavior
- Next step: open PR for Gemma routing policy surface

## 2026-04-12
- Created branch `phase-2/gemma-candidate-decision-records`
- Added written decision records for Gemma-family candidates `gemma3n:e2b` and `gemma3:4b`
- Recorded both candidates as `hold` rather than promote
- Added `docs/PHASE_2_GEMMA_CANDIDATE_DECISION_RECORDS.md`
- Next step: open PR for Gemma candidate decision records

## 2026-04-12
- Created branch `phase-2/gemma-candidate-runtime-profile-surface`
- Added `scripts/profile_gemma_candidate_runtime.ps1`
- Added narrow local runtime profiling for Gemma control-vs-candidate comparison
- Updated `.gitignore` to ignore generated runtime profile outputs under `evals/profiles/`
- Added `docs/PHASE_2_GEMMA_CANDIDATE_RUNTIME_PROFILE_SURFACE.md`
- Next step: prove whether `gemma3n:e2b` shows a real runtime advantage over `gemma3n:e4b` while still passing the eval surface

## 2026-04-12
- Created branch `phase-2/gemma-candidate-runtime-decision-update`
- Updated the `gemma3n:e2b` candidate decision record with local runtime profile evidence
- Recorded that `gemma3n:e2b` remains on hold and is not currently justified as a lightweight routing candidate on this machine
- Added `docs/PHASE_2_GEMMA_CANDIDATE_RUNTIME_DECISION_UPDATE.md`
- Next step: open PR for Gemma candidate runtime decision update

## 2026-04-12
- Created branch `phase-2/domain-task-eval-surface`
- Added `evals/domain_task_eval_cases.json`
- Added `scripts/run_domain_task_eval.ps1`
- Updated `.gitignore` to ignore generated domain task eval results
- Added `docs/PHASE_2_DOMAIN_TASK_EVAL_SURFACE.md`
- Next step: prove the current default model against domain-specific eval cases

## 2026-04-12
- Created branch `phase-2/domain-task-eval-baseline`
- Added `evals/baselines/domain_task_eval_baseline.json`
- Added `scripts/compare_domain_task_eval_to_baseline.ps1`
- Added the first pinned baseline for the domain-task eval surface
- Added `docs/PHASE_2_DOMAIN_TASK_EVAL_BASELINE.md`
- Next step: prove current domain-task eval output matches the pinned baseline

## 2026-04-12
- Created branch `phase-2/domain-task-candidate-comparison-surface`
- Added `scripts/run_domain_task_candidate_eval.ps1`
- Added isolated candidate comparison for the domain-task eval surface
- Added `docs/PHASE_2_DOMAIN_TASK_CANDIDATE_COMPARISON_SURFACE.md`
- Next step: prove one Gemma-family candidate against the pinned domain-task baseline

## 2026-04-12
- Created branch `phase-2/model-decision-index-surface`
- Added `docs/MODEL_DECISION_INDEX.md`
- Added `docs/PHASE_2_MODEL_DECISION_INDEX_SURFACE.md`
- Added a single top-level index for current control-model and candidate decisions
- Next step: open PR for model decision index surface

## 2026-04-12
- Created branch `phase-2/domain-task-candidate-runtime-profile-surface`
- Added `scripts/profile_domain_task_candidate_runtime.ps1`
- Added domain-task runtime profiling for Gemma control-vs-candidate comparison
- Added `docs/PHASE_2_DOMAIN_TASK_CANDIDATE_RUNTIME_PROFILE_SURFACE.md`
- Next step: prove whether `gemma3n:e2b` shows a real runtime advantage over `gemma3n:e4b` on the domain-task eval surface

## 2026-04-12
- Created branch `phase-2/domain-task-candidate-runtime-decision-update`
- Updated the `gemma3n:e2b` candidate decision record with domain-task runtime evidence
- Updated `docs/MODEL_DECISION_INDEX.md` to reflect `gemma3n:e2b` as a conditional domain-task routing candidate
- Added `docs/PHASE_2_DOMAIN_TASK_CANDIDATE_RUNTIME_DECISION_UPDATE.md`
- Next step: open PR for domain-task candidate runtime decision update

## 2026-04-12
- Created branch `phase-2/domain-task-routing-pilot-surface`
- Added a narrow optional domain-task routing pilot in the Orchestrator provider layer
- Added `tests/integration/test_domain_task_routing_pilot_surface.ps1`
- Updated `.env.example` with domain-task routing pilot flags
- Updated `services/eidon-orchestrator/README.md`
- Added `docs/PHASE_2_DOMAIN_TASK_ROUTING_PILOT_SURFACE.md`
- Next step: prove route eligibility uses `gemma3n:e2b` and non-eligible traffic stays on `gemma3n:e4b`, with control fallback available on candidate failure

## 2026-04-12
- Created branch `phase-2/domain-task-routing-provenance-surface-retry`
- Persisted routing route mode and route reason for the domain-task routing pilot
- Added `tests/integration/test_domain_task_routing_provenance_surface.ps1`
- Added `docs/PHASE_2_DOMAIN_TASK_ROUTING_PROVENANCE_SURFACE.md`
- Proved candidate routing provenance and full-chain integration behavior
- Next step: open PR for domain-task routing provenance surface

## 2026-04-12
- Created branch `phase-2/mirror-laws-policy-surface`
- Added `docs/MIRROR_LAWS_POLICY.md`
- Added `docs/PHASE_2_MIRROR_LAWS_POLICY_SURFACE.md`
- Defined the Mirror Laws as an explicit governance policy surface
- Next step: open PR for Mirror Laws policy surface

## 2026-04-12
- Created branch `phase-2/guardian-protocol-policy-surface`
- Added `docs/GUARDIAN_PROTOCOL_POLICY.md`
- Added `docs/PHASE_2_GUARDIAN_PROTOCOL_POLICY_SURFACE.md`
- Defined the Guardian Protocol as an explicit governance policy surface grounded in the upstream universe source
- Next step: open PR for Guardian Protocol policy surface

## 2026-04-12
- Created branch `phase-2/governance-eval-surface`
- Added `evals/governance_eval_cases.json`
- Added `scripts/run_governance_eval.ps1`
- Updated `.gitignore` to ignore generated governance eval results
- Added `docs/PHASE_2_GOVERNANCE_EVAL_SURFACE.md`
- Next step: prove the current control model can answer named governance outcome cases in plain text

## 2026-04-12
- Created branch `phase-2/governance-provenance-surface`
- Added governance outcome and governance reason to artifact and lineage provenance
- Added `tests/integration/test_governance_provenance_surface.ps1`
- Added `docs/PHASE_2_GOVERNANCE_PROVENANCE_SURFACE.md`
- Next step: prove persisted governance outcome and reason through artifact and lineage retrieval

## 2026-04-12
- Created branch `phase-2/governance-provenance-surface`
- Added governance outcome and governance reason to artifact and lineage provenance
- Added `tests/integration/test_governance_provenance_surface.ps1`
- Added `docs/PHASE_2_GOVERNANCE_PROVENANCE_SURFACE.md`
- Next step: prove persisted governance outcome and reason through artifact and lineage retrieval

## 2026-04-12
- Created branch `phase-2/governance-enforcement-pilot-surface`
- Added a narrow governance enforcement pilot in Orchestrator
- Added `tests/integration/test_governance_enforcement_pilot_surface.ps1`
- Added `docs/PHASE_2_GOVERNANCE_ENFORCEMENT_PILOT_SURFACE.md`
- Next step: prove allow, refuse, and hold outcomes are enforced and persisted cleanly

## 2026-04-12
- Created branch `phase-2/governance-eval-baseline`
- Added `evals/baselines\governance_eval_baseline.json`
- Added `scripts/compare_governance_eval_to_baseline.ps1`
- Added the first pinned baseline for the governance eval surface
- Added `docs/PHASE_2_GOVERNANCE_EVAL_BASELINE.md`
- Next step: prove current governance eval output matches the pinned baseline

## 2026-04-12
- Created branch `phase-2/governance-rules-manifest-surface`
- Added `config/governance_rules_manifest.json`
- Moved the narrow governance enforcement pilot rules into a visible manifest
- Updated `services/eidon-orchestrator/app/main.py` to load the manifest
- Added `docs/PHASE_2_GOVERNANCE_RULES_MANIFEST_SURFACE.md`
- Next step: prove the manifest-backed pilot still matches the pinned governance baseline and enforcement behavior

## 2026-04-12
- Created branch `phase-2/governance-rule-provenance-surface`
- Added governance rule id and governance manifest version to artifact and lineage provenance
- Added `tests/integration/test_governance_rule_provenance_surface.ps1`
- Added `docs/PHASE_2_GOVERNANCE_RULE_PROVENANCE_SURFACE.md`
- Next step: prove manifest rule identity is persisted for allow, refuse, and hold outcomes

## 2026-04-12
- Added `docs/PHASE_2_STATUS.md` as the current top-level Phase 2 status surface
- Added `docs/PHASE_2_MILESTONE_100_MERGED_PRS.md` to record the first 100 merged pull requests as a structural milestone
- Updated `services/eidon-orchestrator/README.md` to reflect the current provider, routing, governance, manifest, and provenance surfaces
- Completed a bounded docs consolidation pass on the 100-merge milestone branch

## 2026-04-13
- Created branch `phase-2/root-readme-truth-sync`
- Rewrote the root `README.md` to reflect the current Phase 2 provider, routing, governance, baseline, manifest, and provenance surfaces
- Next step: open PR for root README truth sync

## 2026-04-13
- Created branch `phase-2/governance-outcome-coverage-surface`
- Extended the manifest-backed governance pilot to cover `reshape` and `handoff`
- Added `tests/integration/test_governance_outcome_coverage_surface.ps1`
- Added `docs/PHASE_2_GOVERNANCE_OUTCOME_COVERAGE_SURFACE.md`
- Next step: prove `reshape` and `handoff` are enforced and persisted cleanly while keeping baseline and full-chain behavior intact

## 2026-04-13
- Created branch `phase-2/governance-eval-baseline-refresh`
- Refreshed `evals/baselines/governance_eval_baseline.json` to match the current six-outcome manifest-backed governance behavior
- Added `docs/PHASE_2_GOVERNANCE_EVAL_BASELINE_REFRESH.md`
- Next step: open PR for governance eval baseline refresh

## 2026-04-13
- Created branch `phase-2/governance-manifest-baseline-surface`
- Added `config/baselines/governance_rules_manifest_baseline.json`
- Added `scripts/compare_governance_manifest_to_baseline.ps1`
- Added `docs/PHASE_2_GOVERNANCE_MANIFEST_BASELINE_SURFACE.md`
- Next step: prove the current governance manifest matches the pinned baseline

## 2026-04-13
- Created branch `phase-2/governance-change-record-surface`
- Added `docs/GOVERNANCE_CHANGE_RECORDS_INDEX.md`
- Added `docs/decision_records/GOVERNANCE_MANIFEST_CHANGE_RECORD_2026_04_13.md`
- Added `docs/PHASE_2_GOVERNANCE_CHANGE_RECORD_SURFACE.md`
- Established governance manifest changes as explicit decision-recorded changes rather than casual config edits
- Next step: open PR for governance change record surface

## 2026-04-13
- Created branch `phase-2/governance-change-validation-surface`
- Added `scripts/validate_governance_manifest_change.ps1`
- Added `docs/PHASE_2_GOVERNANCE_CHANGE_VALIDATION_SURFACE.md`
- Added a validation surface that fails when the governance manifest changes materially without version change and matching governance change record coverage
- Next step: prove the current unchanged manifest passes the new governance change validation surface

## 2026-04-13
- Created branch `phase-2/governance-gate-surface`
- Added `scripts/run_governance_gate.ps1`
- Added `docs/PHASE_2_GOVERNANCE_GATE_SURFACE.md`
- Added a single-command governance gate that runs manifest baseline comparison, change validation, governance eval, eval baseline comparison, governance rule provenance, and full-chain verification
- Next step: prove the governance gate passes end to end

## 2026-04-13
- Created branch `phase-2/phase2-gate-surface`
- Added `scripts/run_phase2_gate.ps1`
- Added `docs/PHASE_2_GATE_SURFACE.md`
- Added a top-level Phase 2 gate that starts the stack, warms the provider, checks health, and runs the governance gate
- Next step: prove the Phase 2 gate passes end to end

## 2026-04-13
- Created branch `phase-2/phase2-gate-ci-surface`
- Added `.github/workflows/phase2-gate.yml`
- Added `docs/PHASE_2_GATE_CI_SURFACE.md`
- Added the first CI surface for the Phase 2 gate using a self-hosted Windows runner and the existing `scripts/run_phase2_gate.ps1` command
- Next step: push the workflow branch and verify the Phase 2 gate workflow is available in GitHub Actions

## 2026-04-15
- Created branch `phase-2/gate-fail-fast-surface`
- Updated `scripts/run_governance_gate.ps1` to fail fast on child step exit codes
- Updated `scripts/run_phase2_gate.ps1` to fail fast on child step exit codes
- Added `docs/PHASE_2_GATE_FAIL_FAST_SURFACE.md`
- Next step: prove the gates only report success when all required steps actually pass

## 2026-04-15
- Created branch `phase-2/service-venv-bootstrap-surface`
- Added `scripts/bootstrap_phase2_service_venvs.ps1`
- Added `docs/PHASE_2_SERVICE_VENV_BOOTSTRAP_SURFACE.md`
- Added a reusable bootstrap surface for the four Phase 2 service virtual environments
- Next step: prove service venv bootstrap passes on an already-prepared dev box and reduces manual runner setup repetition

## 2026-04-15
- Created branch `phase-2/postgres-bootstrap-surface`
- Added `scripts/bootstrap_phase2_postgres.ps1`
- Added `docs/PHASE_2_POSTGRES_BOOTSTRAP_SURFACE.md`
- Added an explicit PostgreSQL bootstrap surface for local Phase 2 machines
- Next step: prove PostgreSQL bootstrap passes cleanly against the local Phase 2 `.env` and database

## 2026-04-15
- Created branch `phase-2/laptop-sync-surface`
- Added `scripts/sync_laptop_runner_main.ps1`
- Added `docs/PHASE_2_LAPTOP_SYNC_SURFACE.md`
- Added a local runner sync surface so the laptop box can refresh from `main` and rerun bootstrap checks without branch-by-branch babysitting
- Next step: prove the laptop sync script passes on the runner box and can optionally rerun the Phase 2 gate

## 2026-04-15
- Created branch `phase-2/postgres-schema-bootstrap-surface`
- Added `scripts/bootstrap_phase2_postgres_schema.ps1`
- Added `docs/PHASE_2_POSTGRES_SCHEMA_BOOTSTRAP_SURFACE.md`
- Added an explicit PostgreSQL schema bootstrap and verification surface for the local Phase 2 state layer
- Next step: prove required PostgreSQL tables are created and verified cleanly from the local Orchestrator environment

## 2026-04-15
- Created branch `phase-2/postgres-schema-drift-surface`
- Added `scripts/validate_phase2_postgres_schema_drift.ps1`
- Added `docs/PHASE_2_POSTGRES_SCHEMA_DRIFT_SURFACE.md`
- Added a PostgreSQL schema drift validation surface for required artifact and lineage provenance columns
- Next step: prove required Phase 2 PostgreSQL columns are present and fail cleanly if the schema shape drifts

## 2026-04-15
- Created branch `phase-2/state-gate-surface`
- Updated `scripts/run_phase2_gate.ps1` to include PostgreSQL database bootstrap, schema bootstrap, and schema drift validation in the required proof path
- Added `docs/PHASE_2_STATE_GATE_SURFACE.md`
- Next step: prove the top-level Phase 2 gate now enforces state bootstrap and schema validation before the rest of the proof path

## 2026-04-15
- Created branch `phase-2/startup-state-bootstrap-surface`
- Updated `scripts/start_phase_2_stack.ps1` to include PostgreSQL database bootstrap, schema bootstrap, and schema drift validation before service startup
- Added `docs/PHASE_2_STARTUP_STATE_BOOTSTRAP_SURFACE.md`
- Next step: prove the startup path now enforces state discipline before bringing Phase 2 services up

## 2026-04-15
- Created branch `phase-2/startup-readiness-surface`
- Added `scripts/check_phase_2_startup_readiness.ps1`
- Updated `scripts/start_phase_2_stack.ps1` to verify service readiness before provider warmup
- Added `docs/PHASE_2_STARTUP_READINESS_SURFACE.md`
- Next step: prove startup now waits for real service readiness instead of treating window launch as success

## 2026-04-15
- Created branch `phase-2/readme-truth-refresh`
- Updated root `README.md` to reflect current governance, startup, bootstrap, and state surfaces
- Updated `services/eidon-orchestrator/README.md` to reflect current provider, governance, state, and readiness surfaces
- Next step: open PR for bounded README truth refresh
