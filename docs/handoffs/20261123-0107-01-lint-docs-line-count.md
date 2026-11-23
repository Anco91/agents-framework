# Handoff — 01-lint-docs-line-count — 2026-11-23 01:07

Sub-spec: `specs/01-lint-docs-line-count.md` · Handoff: `docs/handoffs/20261123-0107-01-lint-docs-line-count.md` · Rules: SES-1..5

## Trigger

Sub-spec 01 is ready and its test is locked (Advisor → Executor handoff).

## Done

- Self-hosted pilot setup (`b687643`): `ARCHITECTURE.md` registry, `specs/SPEC_MASTER.md`,
  sub-spec 01 and the locked test.
- Registry passes `bash framework/scripts/arch-check.sh ARCHITECTURE.md` (exit 0).
- Sub-spec locked (`82a3712`), `locked_at` = `b687643`.

## Left

1. Change `check_budget` in `framework/scripts/lint-docs.sh` to count with `awk 'END { print NR }'`.
2. Run `bash tests/test_lint_docs.sh`; it must pass.
3. Run `bash framework/scripts/test-lock.sh specs/01-lint-docs-line-count.md`; exit 0.
4. Commit `fix(lint-docs): count unterminated last line` with trailer
   `Spec: docs/design/spec-v4.md`.

## Decisions

- Self-hosting uses `framework/scripts/` directly; no generated `.agents-fw/` copy is committed.
- Budget values and every other check stay unchanged.

## Files touched

- `ARCHITECTURE.md` — created
- `specs/SPEC_MASTER.md` — created
- `specs/01-lint-docs-line-count.md` — created
- `tests/test_lint_docs.sh` — modified (locked test)

## Tests

- `bash tests/test_lint_docs.sh` → `FAIL: lint-docs accepted an unterminated last line over the budget` (expected before execution).
- `bash framework/scripts/test-lock.sh specs/01-lint-docs-line-count.md` → exit 0.
- `bash tests/run.sh` → all 7 files PASS before this sub-spec.

## Blockers / risks

- `tests/test_lint_docs.sh` is locked; the Executor must not edit it.
- The 80-line regression case must keep passing: do not lower the limit.

## Next action

Open `framework/scripts/lint-docs.sh` and replace the `wc -l` count in `check_budget`.

## Resume block

Paste this, filled, as the last message of the session (SES-4):

```
NEXT SESSION
Role: executor
Read: AGENTS.md, ARCHITECTURE.md, docs/handoffs/20261123-0107-01-lint-docs-line-count.md
Sub-spec: specs/01-lint-docs-line-count.md (master: specs/SPEC_MASTER.md)
First action: Fix the line count in framework/scripts/lint-docs.sh.
```
