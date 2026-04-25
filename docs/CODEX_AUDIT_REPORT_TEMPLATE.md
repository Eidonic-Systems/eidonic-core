# Codex Audit Report Template

Use this template when asking Codex to inspect repo surfaces.

The purpose is to separate real drift from stale audit noise.

## Audit target

Files, directories, or surfaces inspected:
- `<path>`

## Audit mode

Choose one:
- static file inspection only
- manifest-to-doc comparison
- validator failure diagnosis
- runtime proof review
- PR diff review
- public truth reconciliation

## Limitations

State what Codex did not do.

Examples:
- did not run the local stack
- did not access private GitHub settings
- did not inspect secrets
- did not verify branch protection
- did not run full gate

## Finding summary

| ID | Severity | Classification | Surface | Short finding |
|---|---|---|---|---|

## Classification key

- Confirmed: supported by current repo evidence
- Stale: contradicted by current repo evidence
- False positive: caused by bad assumption or incomplete audit method
- Needs runtime proof: cannot be decided statically
- Needs implementation: doc target is valid but code is missing
- Needs reconciliation: code/proof exists but docs overclaim or underclaim

## Finding detail

### F-001: `<finding title>`

Severity:
- Critical / High / Medium / Low

Classification:
- Confirmed / Stale / False positive / Needs runtime proof / Needs implementation / Needs reconciliation

Evidence:
- `<file/path>`
- `<line or section if known>`
- `<manifest/script/proof reference>`

Reasoning:
- Explain why this is a real issue or not.

Recommended branch:
- `phase-2/<branch-name>`

Allowed files:
- `<path>`

Required proof:
- `<PowerShell command>`

Risk if ignored:
- Explain the concrete risk.

## Final recommendation

State the next bounded branch.

Do not recommend more than one primary next branch unless explicitly asked.
