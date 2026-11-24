---
id: 10-openspec-default
status: done
branch: feat/10-openspec-default
tier: medium
locked_at: b6120ca
locked_tests:
  - tests/test_openspec_default.sh
---

# 10 — OpenSpec is the default spec workflow

Master: `specs/SPEC_MASTER.md` · Rules: WF-3, WF-7, ROLE-1..4

## Goal

A new feature goes explore → propose → tasks → apply → archive with OpenSpec, without stopping. A
sub-spec is an OpenSpec change; the framework Frame lives in `openspec/changes/<id>/frame.md`.

## Acceptance criteria

1. `WF-9 MUST` in `rules/workflow.md`: OpenSpec is the default; mapping change folder ↔ sub-spec.
2. `procedures/openspec-flow.md` and `templates/FRAME.md` exist and install under `.agents-fw/`.
3. `test-lock.sh` and `new-handoff.sh` accept `openspec/changes/<id>/frame.md` (front matter `id`).
4. `core.md` names OpenSpec as the default; the guide section "Coexister avec OpenSpec" says so.
5. `init.sh` untouched: still no `npx`, `openspec/` byte-identical (spec 09 test stays green).

## Frame

### Create
| Path | Role |
|---|---|
| `framework/procedures/openspec-flow.md` | explore → propose → frame → apply → archive, no stop |
| `framework/templates/FRAME.md` | front matter + Frame + Tests, no goal/criteria (proposal owns them) |

### Modify
| Path | Change |
|---|---|
| `framework/rules/workflow.md` | WF-9 |
| `framework/core.md`, `framework/procedures/write-sub-spec.md` | point to the OpenSpec flow |
| `docs/guide-utilisation.md`, `README.md`, `CHANGELOG.md`, `ARCHITECTURE.md`, `specs/SPEC_MASTER.md` | docs, Decisions row superseding 09 |

### Forbidden
`init.sh`, `tests/test_openspec_bridge.sh`, any budget raise.

## Tests
Locked: `tests/test_openspec_default.sh`.

## Handoffs
