# Spec master — agents-framework

Rules: WF-2, WF-4, SES-5. This file is an index: no implementation detail.

## Vision

A portable, spec-first framework for AI coding agents. A project installs one managed block,
then works from sliced sub-specs, locked tests and session handoffs. Success: a cheap Executor
can implement a slice without searching the workspace, and a strong Advisor keeps the specs true.

## Invariants

- Scripts stay bash 3.2 / POSIX compatible: no `jq`, no associative arrays, no prompts.
- `sha256sum` with a `shasum -a 256` fallback; no network access at runtime.
- Delivered files in `framework/` and `adapters/` are English; README and design docs are French.
- Line budgets are enforced by `lint-docs.sh`; do not raise them.
- One milestone = one branch = one PR, with trailer `Spec: docs/design/spec-v4.md`.
- No model slug, price or API key in `framework/` or `adapters/`.
- Tests are behavioural: run against a temporary project and assert the produced state.

## Glossary

| Term | Meaning |
|---|---|
| Managed block | Region of `AGENTS.md` rewritten by `init.sh update` |
| Sub-spec | One slice with a Frame, acceptance criteria and locked tests |
| Locked test | Test committed by the Advisor before execution; `test-lock.sh` guards it |
| Handoff | One file per session with a `NEXT SESSION` resume block |
| Frame | Exact create/modify/read/reuse/forbidden list for the Executor |

## Sub-specs

<!-- Ordered. Only the next one or two are written in detail (WF-4). -->
<!-- status: draft | ready | in-progress | review | done -->
| # | Sub-spec | Outcome | Status | Last handoff |
|---|---|---|---|---|
| 01 | `specs/01-lint-docs-line-count.md` | Line budgets count an unterminated last line | done | `docs/handoffs/20261123-0108-01-lint-docs-line-count.md` |
| 02 | `specs/02-agent-tiers.md` | Claude Executor/Reviewer agents with model tier aliases; `tier:` in sub-specs | done | `docs/handoffs/20261124-1315-02-agent-tiers.md` |
| 03 | `specs/03-session-gauge.md` | Tool-call counter warns at the SES-2 limit | done | `docs/handoffs/20261124-1325-03-session-gauge.md` |
| 04 | `specs/04-autonomous-flow.md` | GIT-7: commit, push, merge on green; human gates only | done | — |
| 05 | `specs/05-style-review.md` | Reviewer checks code against project house style and exemplars | done | `docs/handoffs/20261124-1436-05-style-review.md` |
| 06 | `specs/06-adopt-existing.md` | `init.sh adopt`: replace existing rules/skills with the framework, with backup | done | — |
| 07 | `specs/07-tool-policy.md` | Tool-order rule CTX-8; Claude `permissions.deny` and Context7 MCP examples installed beside the adapter | done | — |
| 09 | `specs/09-openspec-bridge.md` | Documentation-only bridge to OpenSpec; `init.sh` never calls `npx` | draft | — |
