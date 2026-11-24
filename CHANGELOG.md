# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: semver.

## [Unreleased]

Sub-specs 02 to 07 and 09 are delivered; 08 was dropped (the Decisions table is the changes log).

### Added
- Session relay (12): `scripts/relay.sh` starts each next session headless from the latest handoff (`AGENTS_FW_RELAY_CMD`, no default, no permission bypass); `Stop:` line in the resume block; SES-9.
- Autonomous team (11): `rules/autonomy.md` (AUTO-1..6), ROLE-11 PM, `procedures/kickoff.md`, `procedures/pm-loop.md`, Claude agent `agents-fw-pm`. The human no longer validates or chooses; WF-1, WF-7, ROLE-3, ROLE-4 route to the PM/Advisor. GIT-7 gates unchanged.
- OpenSpec is the default spec workflow (WF-9, 10): a sub-spec is an OpenSpec change plus a `frame.md`; new `procedures/openspec-flow.md` and `templates/FRAME.md`. `init.sh` still never touches `openspec/`.
- CTX-8: tool order (registry, ranged read or LSP, folder-limited search, library docs). Claude host ships `settings.example.json` with `permissions.deny` and `mcp.example.json` (Context7) in `.agents-fw/adapters/claude/`; user config is never edited.
- `init.sh adopt <project> [--host <list>] [--apply]`: dry-run plan, then backup to `.agents-fw/backup/<timestamp>/` and install; never deletes.
- Claude host: `agents-fw-executor` (sonnet), `agents-fw-executor-small` (haiku), `agents-fw-reviewer`;
  `tier: small|medium` in the sub-spec header; ROLE-9 (named agents only, no inherited strong model).
- `session-gauge.sh` and a Claude PostToolUse hook snippet: warns `HANDOFF NOW` at the SES-2 tool-call limit; never blocks.
- GIT-7: the agent commits, pushes, opens and merges its PR on green checks without asking; it stops only at a listed human gate.
- ROLE-10: House style section in `ARCHITECTURE.md`, "Style exemplars" in the Frame; the Reviewer blocks code that drifts from the project's style.
- `core.md`: host global rules do not override TEST-1..3 or the role split.
- `docs/guide-utilisation.md`: installation, first sub-spec, Executor/Reviewer sessions, updates and troubleshooting.
- `docs/guide-utilisation.md`: section "Coexister avec OpenSpec" (09). Documentation only: `init.sh` never touches `openspec/` and never calls `npx`.

## [1.0.0] — 2026-11-23

### Added
- `.devin/blueprint.yaml`: Devin environment (shellcheck) and knowledge entries mirroring CI.
- Root `AGENTS.md`: repository commands, ground rules and layout for coding agents.
- Self-hosted spec workflow: `ARCHITECTURE.md` registry, `specs/SPEC_MASTER.md`, one sub-spec and
  session handoffs under `docs/handoffs/`.

### Fixed
- `lint-docs.sh` line budgets counted an unterminated last line as absent; now counted with `awk`.

## [1.0.0-rc.1] — 2026-11-22

### Added
- `framework/`: core block, rules (WF, ROLE, SES, TEST, CTX, GIT), standards (ARCH, BE, FE, LIB,
  TypeScript, Python) with reference code compiled in a witness project, procedures, templates, examples.
- `init.sh install|update|hosts` with manifest-based safe updates and `--host claude,kilo,aider,skills`.
- Control scripts: `test-lock.sh`, `arch-check.sh`, `new-handoff.sh`, `lint-docs.sh`.
- Host adapters and `docs/hosts.md` (official-doc evidence per host).
- Behaviour test suite, CI on Linux and macOS, bash 3.2 compatible.
- French README.

## [0.1.0] — 2026-11-22

### Added
- Validated design spec v4.1, implementation plan v4, audit of spec v3, decisions log.
