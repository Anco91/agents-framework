# Architecture — agents-framework

Rules: CTX-1..4, ARCH-*, LIB-3. Read this before any search. Keep it true in the same commit as the code.
Checked by `bash framework/scripts/arch-check.sh ARCHITECTURE.md`.

## Stack

- Bash 3.2+ / POSIX sh; no `jq`, no associative arrays, no interactive prompt.
- `sha256sum` with a `shasum -a 256` fallback; no network access at runtime.
- GitHub Actions on Ubuntu and macOS; `shellcheck` for lint.
- Behaviour tests: shell scripts that install into a temporary project and assert the resulting state.

## Module map

- `framework/core.md` — managed block injected into a project's `AGENTS.md`.
- `framework/rules/` — WF, ROLE, SES, TEST, CTX, GIT rules.
- `framework/standards/` — ARCH, BE, FE, LIB, TypeScript, Python, plus reference code.
- `framework/procedures/` — Advisor/Executor/Reviewer step-by-step guides.
- `framework/templates/` — `ARCHITECTURE.md`, `SPEC_MASTER.md`, `SUB_SPEC.md`, `HANDOFF.md`, `PR.md`.
- `framework/scripts/` — enforcement gates and generators used by projects and by this repository.
- `adapters/` — per-host files for Claude, Kilo, Aider and generated skills.
- `init.sh` — `install`, `update` and `hosts` entry point.
- `tests/` — behavioural tests for every script and for the installer.

## Declared folders

- `framework/scripts/`

## Reuse registry

| Path | Kind | Purpose |
|---|---|---|
| `framework/scripts/arch-check.sh` | file | Registry and declared-folder gate |
| `framework/scripts/lint-docs.sh` | file | Line budgets, rule IDs, links, handoff block |
| `framework/scripts/new-handoff.sh` | file | Handoff file generator |
| `framework/scripts/test-lock.sh` | file | Locked-test integrity gate |
| `framework/scripts/session-gauge.sh` | file | Tool-call counter, warns at the SES-2 limit |
| `init.sh` | file | Installer and updater |
| `framework/core.md` | file | Managed project block |
| `framework/templates/` | folder | Project document templates |

## Libraries

| Need | Library |
|---|---|
| Shell lint | `shellcheck` |
| Hashing | `sha256sum` / `shasum` |
| CI | GitHub Actions |

## Decisions

| Date | Decision | Reason |
|---|---|---|
| 2026-11-23 | This repository runs its own scripts from `framework/scripts/` and does not vendor a generated `.agents-fw/` copy | The framework directory is the source of truth; a second copy would drift |
| 2026-11-23 | Self-hosted sub-specs live under `specs/`; handoffs under `docs/handoffs/` | Dogfood the workflow described in the framework |
| 2026-11-24 | `init.sh adopt` moves existing agent rules to `.agents-fw/backup/<timestamp>/`, never deletes, never touches `settings.json`, `.mcp.json` or `~/.claude` | Adoption must be reversible with plain `mv`; user config is not ours to edit |
