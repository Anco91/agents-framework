---
id: 11-autonomous-team
status: review
branch: feat/11-autonomous-team
tier: medium
locked_at: a28fb53
locked_tests:
  - tests/test_autonomous_team.sh
---

# 11 — Autonomous team (PM, kickoff, no choice prompts)

Master: `specs/SPEC_MASTER.md` · Rules: WF-1, WF-7, ROLE-1..4, GIT-7

## Goal

The agent never asks the human to choose or to validate. A Project Manager role runs a small team
(Advisor, Executor, Reviewer), holds a bounded kickoff per change, picks the recommended option and
logs it. The human is only stopped by GIT-7 gates.

## Acceptance criteria

1. `rules/autonomy.md` defines AUTO-1..6; `core.md` cites them; "no agent spawned unasked" is replaced.
2. WF-1, WF-7 step 2, ROLE-3, ROLE-4 route validation and blockers to the PM/Advisor, not the human.
3. ROLE-11 defines the PM. `procedures/kickoff.md` and `procedures/pm-loop.md` exist.
4. Claude host installs `.claude/agents/agents-fw-pm.md` (tier alias, no slug).

## Frame

### Create
`framework/rules/autonomy.md`, `framework/procedures/kickoff.md`, `framework/procedures/pm-loop.md`,
`adapters/claude/agents/agents-fw-pm.md`.

### Modify
`framework/core.md`, `framework/rules/workflow.md`, `framework/rules/roles.md`, `init.sh` (Claude
agent list and `hosts` output only), `docs/guide-utilisation.md`, `README.md`, `CHANGELOG.md`,
`ARCHITECTURE.md`, `specs/SPEC_MASTER.md`.

### Forbidden
GIT-7 gate list (unchanged), any budget raise, `tests/test_hosts.sh` agent assertions already pinned.

## Tests
Locked: `tests/test_autonomous_team.sh`.

## Handoffs
