# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: semver.

## [Unreleased]

### Added
- Claude host: `agents-fw-executor` (sonnet), `agents-fw-executor-small` (haiku), `agents-fw-reviewer`;
  `tier: small|medium` in the sub-spec header; ROLE-9 (named agents only, no inherited strong model).
- `core.md`: host global rules do not override TEST-1..3 or the role split.
- `docs/guide-utilisation.md`: installation, first sub-spec, Executor/Reviewer sessions, updates and troubleshooting.

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
