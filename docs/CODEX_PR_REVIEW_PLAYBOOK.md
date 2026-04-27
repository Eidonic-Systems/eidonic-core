# Codex PR Review Playbook

This playbook defines how to use Codex as a pull request reviewer for Eidonic Core.

Codex review is an additional signal.
It does not replace human review, required proof commands, branch discipline, or repo truth sources.

## Purpose

Use Codex PR review to catch:

- public truth drift
- missing proof updates
- validator risk
- scope creep
- forbidden-file edits
- stale branch-history wording
- malformed markdown sections
- missing session-log updates
- documentation claims that overstate runtime proof

## Required setup

Before Codex can review GitHub pull requests:

1. Set up Codex Cloud.
2. Connect Codex to GitHub.
3. Enable Code review for the `eidonic-core` repository in Codex settings.
4. Keep automatic reviews off at first.
5. Use manual `@codex review` comments until review quality is proven.

Codex GitHub review can be requested by commenting:

```text
@codex review

A focused review prompt may be added after the mention.

Default PR review prompt

Use this prompt on most Eidonic Core pull requests:

@codex review for public truth drift, missing proof updates, validator risk, allowed-file violations, forbidden-file edits, stale branch-history wording, malformed markdown, and scope creep. Check whether the PR respects AGENTS.md, docs/CODEX_CONTEXT_PACKET.md, docs/CODEX_TASK_TEMPLATE.md, docs/CODEX_REPETITIVE_WORK_PACK.md, and the relevant repo manifests.
Documentation PR review prompt

Use this for documentation-only PRs:

@codex review for public truth drift, over-absolute runtime claims, stale branch-history wording, duplicate posture sections, malformed markdown, missing session-log updates, and missing validator proof. Do not treat handoff files as authoritative.
Manifest or validator PR review prompt

Use this for manifest, validator, or gate-surface PRs:

@codex review for manifest/schema mismatch, validator/doc drift, missing downstream reference updates, proof-command gaps, duplicate validation, wrong gate phase placement, and forbidden scope expansion.
Runtime PR review prompt

Use this for service or runtime behavior PRs:

@codex review for runtime contract drift, missing tests or proof scripts, persistence/provenance mismatch, provider/routing/governance claim inflation, health contract regressions, and docs that overstate live behavior.
What Codex must check

Codex should check:

changed files stay inside the declared branch scope
session log was updated for structural repo changes
project-state was updated when current repo posture changed
scripts README was updated when script behavior changed
manifests were updated only when explicitly scoped
validators and docs still agree
public docs classify claims as live repo surface, local operator-proved surface, declared validation surface, or target posture
runtime claims are backed by code, manifests, validators, or proved command paths
no handoff file is treated as authoritative truth
What humans must still check

Human review remains mandatory for:

architecture direction
governance policy meaning
Mirror Laws and Guardian doctrine
model routing policy
runtime persistence semantics
GitHub workflow trust boundaries
dependency approval
security posture
merge decision

Codex may flag issues.
Humans decide whether they matter.

When to use manual review

Use manual @codex review for:

all Codex-authored or Codex-assisted PRs
public docs
manifests
validators
gate shape
startup discipline
recovery surfaces
automation-helper surfaces
runtime endpoints
service READMEs
When to enable automatic review

Do not enable automatic reviews until manual Codex reviews have proven useful across several PRs.

Minimum bar before automatic review:

at least five manual Codex reviews completed
no severe hallucinated review blockers
review comments mostly map to real repo evidence
Codex respects AGENTS.md and context-packet guidance
human reviewer still catches no repeated Codex blind spot that matters

Even after automatic review is enabled:

human review remains required
proof commands remain required
Codex review is not a merge gate by itself unless explicitly configured later
Response handling

When Codex comments on a PR:

classify each finding:
confirmed
stale
false positive
needs runtime proof
needs implementation
needs reconciliation
fix only confirmed findings inside branch scope
do not expand scope without a new human decision
rerun the relevant proof commands
reply to Codex or note in the PR how findings were handled
Failure modes to watch

Codex may still:

miss project-specific nuance
overfocus on generic best practices
treat stale docs as truth
underweight local operator proof
overflag non-issues when branch scope is narrow
miss subtle runtime behavior
fail to understand why a validator enforces a strange-looking pattern

When that happens, update AGENTS.md, docs/CODEX_CONTEXT_PACKET.md, or the relevant task template.

Security posture

Do not give Codex broad trust by default.

Codex review should never require secrets.
Codex should not be used to expose private credentials.
Self-hosted runner settings, branch protection, and repository security settings must remain human-reviewed.

Final rule

Codex review is a disciplined second reader.

It is not authority.
It is not memory.
It is not a substitute for proof.
