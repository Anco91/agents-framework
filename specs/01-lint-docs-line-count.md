---
id: 01-lint-docs-line-count
status: done
branch: feat/self-hosted-pilot
locked_at: b687643
locked_tests:
  - tests/test_lint_docs.sh
---

# 01 — Count the unterminated last line

Master: `specs/SPEC_MASTER.md` · Rules: WF-3, WF-7, ROLE-1..4, TEST-1..5

## Goal

`lint-docs.sh` rejects a document whose last line has no trailing newline when that line pushes
the file over its budget. Today `wc -l` undercounts such a file by one, so an over-budget document
passes the gate.

## Acceptance criteria

1. Given an 81-line procedure with no trailing newline, `lint-docs.sh` exits 1 and names the file.
2. Given an 80-line procedure with no trailing newline, `lint-docs.sh` exits 0.
3. Existing budget behaviour for newline-terminated files does not change.

## Frame

<!-- Written by the Advisor. The Executor touches nothing outside this section. -->

### Create

| Path | Role | Exports (signatures) |
|---|---|---|
| — | — | — |

### Modify

| Path | Change |
|---|---|
| `framework/scripts/lint-docs.sh` | In `check_budget`, replace the `wc -l` line count with `awk 'END { print NR }' "$file"`. Keep the comparison, message and `failed=1` unchanged. |

### Read (allow-list)

- `ARCHITECTURE.md`
- `framework/scripts/lint-docs.sh`
- `tests/test_lint_docs.sh`

### Reuse (from the registry)

- `framework/scripts/lint-docs.sh` — the gate itself; extend its existing `check_budget` helper.

### Libraries

- POSIX `awk` — already used throughout the script; no new dependency.

### Forbidden

- Any file not listed above.
- Editing `tests/test_lint_docs.sh` (locked).
- Changing budget values, rule-ID checks, link checks or the handoff-block check.
- Adding a helper script or a new command dependency.

## Tests

### Locked (written by the Advisor, failing before execution)

- `tests/test_lint_docs.sh` — 81 lines without a final newline must fail the budget.

Proof of failure: `bash tests/test_lint_docs.sh` → `FAIL: lint-docs accepted an unterminated last line over the budget`

### Proposed by the Executor

| Path | What it covers | Status |
|---|---|---|

### Test change requests

| Test | Reason | Proposal | Decision |
|---|---|---|---|

## Out of scope

- Changing any line budget.
- Counting logical lines differently (CRLF, blank lines).
- Refactoring the rest of `lint-docs.sh`.

## Handoffs

<!-- Appended by new-handoff.sh users (SES-5): newest last. -->
- `docs/handoffs/20261123-0107-01-lint-docs-line-count.md` — Advisor → Executor, test locked.
- `docs/handoffs/20261123-0108-01-lint-docs-line-count.md` — Executor → Advisor, delivered and verified.
