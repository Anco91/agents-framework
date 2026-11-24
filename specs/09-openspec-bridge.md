---
id: 09-openspec-bridge
status: ready
branch: feat/09-openspec-bridge
locked_at:
locked_tests:
  - tests/test_openspec_bridge.sh
tier: small
---

# 09 — OpenSpec bridge

Master: `specs/SPEC_MASTER.md` · Rules: WF-3, WF-7, ROLE-1..4, TEST-1..5

## Goal

A project that keeps OpenSpec reads, in the French guide, how to coexist with the framework. The
installer never touches `openspec/` and never calls `npx`.

## Acceptance criteria

1. `docs/guide-utilisation.md` gains a section `## Coexister avec OpenSpec`, placed after `## Politique d'outils`, saying: the managed block does not touch `openspec/`; `specs/SPEC_MASTER.md` may point to OpenSpec specs; OpenSpec commands (for example run with `npx`) are run by the human, never by `init.sh`.
2. `init.sh` contains no `npx`. `install` and `update` leave an existing `openspec/` tree byte-identical.
3. `tests/test_openspec_bridge.sh` passes; `tests/run.sh`, shellcheck, `lint-docs.sh`, `arch-check.sh` stay green.

## Frame

### Create

None.

### Modify

| Path | Change |
|---|---|
| `docs/guide-utilisation.md` | new French section described in criterion 1 |
| `CHANGELOG.md`, `specs/SPEC_MASTER.md` | entry; row 09 to `done` at delivery |
| `ARCHITECTURE.md` | one Decisions row: 08 dropped because the Decisions table is the changes log and `arch-check.sh` already enforces the registry; OpenSpec coexistence is documentation only |

### Read (allow-list)

- `AGENTS.md`, `ARCHITECTURE.md`, `tests/test_openspec_bridge.sh`
- `docs/guide-utilisation.md` — headings with `grep -n '^## '`, then the section "Politique d'outils" as the style exemplar
- `docs/design/spec-v4.md` lines 426-434 (decision Q2)

### Reuse (from the registry)

- None.

### Style exemplars

- `docs/guide-utilisation.md` section "Politique d'outils" — French tone, short numbered steps.

### Libraries

- None.

### Forbidden

- Any file not listed above. Editing `tests/test_openspec_bridge.sh`. Touching `init.sh`.
- Raising a line budget.

## Tests

### Locked (written by the Advisor, failing before execution)

- `tests/test_openspec_bridge.sh` — pins the guide section, no `npx` in `init.sh`, `openspec/` untouched.

Proof of failure: `bash tests/test_openspec_bridge.sh` → `FAIL: expected .../docs/guide-utilisation.md to contain '## Coexister avec OpenSpec'`

### Proposed by the Executor

| Path | What it covers | Status |
|---|---|---|

### Test change requests

| Test | Reason | Proposal | Decision |
|---|---|---|---|

## Out of scope

- Converting OpenSpec specs to sub-specs. Any `init.sh` change.

## Handoffs
