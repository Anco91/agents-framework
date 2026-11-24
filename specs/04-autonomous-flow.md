---
id: 04-autonomous-flow
status: done
branch: chore/m-f-autonomous-flow
tier: small
---

# 04 — Autonomous delivery flow

Master: `specs/SPEC_MASTER.md` · Rules: GIT-4, GIT-7, WF-5

## Goal

The agent commits, pushes, opens and merges its own PR without asking, and stops only at a listed human gate.

## Acceptance criteria

1. `git.md` has GIT-7 with the human-gate list; GIT-4 no longer says the human keeps control of every PR.
2. `core.md` and `fast-track.md` match GIT-7. `lint-docs.sh` passes (budgets, IDs, links).

## Frame

### Modify

| Path | Change |
|---|---|
| `framework/rules/git.md` | reword GIT-4, add GIT-7 |
| `framework/core.md` | one rule line |
| `framework/procedures/fast-track.md` | step 6 merges on green |
| `CHANGELOG.md` | entry |

## Out of scope

- Review step for style (05) and project adoption (06).

## Handoffs
