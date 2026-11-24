---
id: 03-session-gauge
status: review
branch: feat/m-c-session-gauge
tier: small
locked_at: 7e85a95
locked_tests:
  - tests/test_session_gauge.sh
---

# 03 — Session gauge

Master: `specs/SPEC_MASTER.md` · Rules: SES-2, ROLE-9

## Goal

The agent is told when a session reaches the SES-2 tool-call limit, so it hands off before quality drops.

## Acceptance criteria

1. `session-gauge.sh` stays silent below the limit and prints `HANDOFF NOW` at it. It never exits non-zero.
2. With `--hook` it reads the hook JSON, counts per `session_id`, and answers with `additionalContext`.

## Frame

### Create

| Path | Role | Exports |
|---|---|---|
| `framework/scripts/session-gauge.sh` | counter | `[--hook]`; env `AGENTS_FW_TOOL_LIMIT`, `AGENTS_FW_STATE_DIR` |
| `adapters/claude/settings.example.json` | PostToolUse hook snippet | — |

## Out of scope

- Exchange counting and context percentage (not observable from a hook). Merging into `settings.json` (no `jq`): copy the snippet by hand.
- Unverified: `additionalContext` delivery depends on the Claude Code version; check the hooks reference.

## Handoffs
