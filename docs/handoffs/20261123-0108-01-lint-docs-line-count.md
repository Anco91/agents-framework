# Handoff — 01-lint-docs-line-count — 2026-11-23 01:08

Sub-spec: `specs/01-lint-docs-line-count.md` · Handoff: `docs/handoffs/20261123-0108-01-lint-docs-line-count.md` · Rules: SES-1..5

## Trigger

Sub-spec 01 delivered and verified (Executor → Advisor handoff, SES-1).

## Done

- `framework/scripts/lint-docs.sh` now counts the unterminated last line (`963409c`).
- `bash tests/run.sh`: 7/7 PASS.
- `shellcheck init.sh framework/scripts/*.sh tests/*.sh`: OK.
- `bash framework/scripts/lint-docs.sh`: OK.
- `bash framework/scripts/arch-check.sh ARCHITECTURE.md`: OK.
- `bash framework/scripts/test-lock.sh specs/01-lint-docs-line-count.md`: exit 0.

## Left

1. Record the pilot measurements in `docs/decisions-log.md`.
2. Set `VERSION` to `1.0.0` and update `CHANGELOG.md`.
3. Open the PR for `feat/self-hosted-pilot`.

## Decisions

- Pilot runs in this repository, not in `mbongo`: the framework repo is the intended self-hosted
  target. The earlier `mbongo` branch was deleted without push.
- No generated `.agents-fw/` copy is committed; `framework/scripts/` stays the source of truth.
- SES-2 thresholds (30 exchanges, 40 tool calls) fit the observed Executor session; no change.

## Files touched

- `framework/scripts/lint-docs.sh` — modified (one line)
- `ARCHITECTURE.md` — created
- `specs/SPEC_MASTER.md` — created
- `specs/01-lint-docs-line-count.md` — created
- `tests/test_lint_docs.sh` — modified (locked test, Advisor commit `b687643`)
- `docs/handoffs/` — two handoffs

## Tests

- Locked test before execution: `FAIL: lint-docs accepted an unterminated last line over the budget`.
- After execution: `bash tests/test_lint_docs.sh` exit 0; full suite 7/7 PASS.
- `test-lock.sh` exit 0 after the fix: the locked test file is unchanged.

## Pilot measurements

| Metric | Value |
|---|---|
| Sessions | 1 Advisor, 1 Executor (plus one discarded `mbongo` attempt) |
| Executor files read | 6 (AGENTS.md, ARCHITECTURE.md, handoff, sub-spec, lint-docs.sh, test_lint_docs.sh) |
| Executor files changed | 1 |
| Executor commands | 2 test runs |
| Out-of-Frame reads | 0 |
| Locked-test edits | 0 |
| `test-lock` violations | 0 |
| `arch-check` violations | 0 |
| Commits | 5 on `feat/self-hosted-pilot` |
| OpenRouter cost | not measurable from this environment (needs the Activity dashboard) |

## Blockers / risks

- Cost per role is the only M9 metric still missing. It requires an OpenRouter Activity export
  covering the Advisor and Executor sessions.
- One wasted cycle: the pilot started in `mbongo` before moving here. Revert was clean (local
  branch only, no push).

## Next action

Write the decisions-log entry, bump `VERSION` to `1.0.0`, update `CHANGELOG.md`, then open the PR.

## Resume block

Paste this, filled, as the last message of the session (SES-4):

```
NEXT SESSION
Role: advisor
Read: AGENTS.md, ARCHITECTURE.md, docs/handoffs/20261123-0108-01-lint-docs-line-count.md
Sub-spec: specs/01-lint-docs-line-count.md (master: specs/SPEC_MASTER.md)
First action: Record pilot measurements and release 1.0.0.
```
