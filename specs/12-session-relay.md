---
id: 12-session-relay
status: done
branch: feat/12-session-relay
tier: medium
locked_at: cec4c41
locked_tests:
  - tests/test_relay.sh
---

# 12 — Session relay

Master: `specs/SPEC_MASTER.md` · Rules: SES-1..4, AUTO-2

## Goal

A running session cannot clear or restart itself. An outer script, started once by the human, runs the
host CLI headless on the latest handoff's `NEXT SESSION` block, again and again, until the work is done
or a human gate is reached.

## Acceptance criteria

1. `framework/scripts/relay.sh [--root <dir>] [--max <n>]` reads the host command from
   `AGENTS_FW_RELAY_CMD` (required; no default, no permission-bypass flag shipped), feeds the prompt on stdin.
2. Stops (exit 0): `.agents-fw/STOP` exists; every master row is `done`; the block has `Stop: done` or
   `Stop: human-gate: <reason>`. Exit 3: the command produced no new handoff. Exit 4: `--max` reached
   (default 10). Exit 2: usage, missing command or no resume block. Exit 5: the command failed.
3. The resume block gains a line `Stop: none | done | human-gate: <reason>` in `HANDOFF.md`,
   `handoff.md` (identical blocks) and SES-4; SES-9 documents the relay.
4. Bash 3.2, no `jq`, no network, no new dependency.

## Frame

### Create
`framework/scripts/relay.sh`.

### Modify
`framework/templates/HANDOFF.md`, `framework/procedures/handoff.md`, `framework/rules/session.md`,
`framework/core.md` (one line), `docs/guide-utilisation.md`, `README.md`, `CHANGELOG.md`,
`ARCHITECTURE.md` (registry row), `specs/SPEC_MASTER.md`.

### Forbidden
`init.sh`, any budget raise, `--dangerously-skip-permissions` anywhere.

## Tests
Locked: `tests/test_relay.sh` (stub host command).

## Handoffs
