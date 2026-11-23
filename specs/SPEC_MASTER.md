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
| 01 | `specs/01-lint-docs-line-count.md` | Line budgets count an unterminated last line | draft | — |
