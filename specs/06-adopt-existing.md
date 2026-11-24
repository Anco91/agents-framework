---
id: 06-adopt-existing
status: done
branch: feat/06-adopt-existing
locked_at: 9c1aaad
locked_tests:
  - tests/test_adopt.sh
tier: medium
---

# 06 — Adopt an existing project

Master: `specs/SPEC_MASTER.md` · Rules: WF-3, ROLE-1..4, TEST-1..5

## Goal

A project that already has agent rules (Claude, Cursor, Kilo, Copilot, Aider) switches to the framework
without losing anything: `init.sh adopt <project>` shows a plan, `--apply` backs up and installs.

## Acceptance criteria

1. `init.sh adopt <project> [--host <list>]` is a dry run: prints `would move  <path>` per item, `left alone  <path>` for `.claude/settings.json` and `.mcp.json` when present, the content of each moved file (so the Advisor can fold project facts into `ARCHITECTURE.md`), and the hint to re-run with `--apply`. It changes no file.
2. `--apply` moves each item to `.agents-fw/backup/<timestamp>/<same relative path>` (never deletes), prints `moved  <path>`, then runs the `install` flow with the same `--host`. Manifest, managed block and project files follow `install`.
3. Items: `CLAUDE.md`, children of `.claude/rules`, `.claude/agents`, `.claude/skills`, `.cursorrules`, children of `.cursor/rules` and `.kilocode/rules`, `.github/copilot-instructions.md`, `CONVENTIONS.md`. Skip names starting `agents-fw-` and a `CLAUDE.md` identical to `adapters/claude/CLAUDE.md`.
4. Nothing to move: print `nothing to adopt`, create no backup. A second `--apply` therefore changes nothing.
5. Missing project or unknown option: `usage:` on stderr, exit 1. `usage` text lists `adopt`.
6. `tests/test_adopt.sh` passes; `tests/run.sh`, shellcheck and `lint-docs.sh` stay green.

## Frame

### Create

| Path | Role | Exports (signatures) |
|---|---|---|
| `docs/guide-utilisation.md` section | French guide "Adopter dans un projet existant" | — |

### Modify

| Path | Change |
|---|---|
| `init.sh` | add `adopt` action: `list_adopt_items`, `print_adopt_plan`, `apply_adopt`; parse `--apply`; `usage` text. Reuse `resolve_project`, `check_path_links`, `normalize_host_list` |
| `docs/guide-utilisation.md` | new section after section 2: adopt flow, manual steps for `settings.json`, `.mcp.json`, `~/.claude` (no `jq`), and a new-project path |
| `ARCHITECTURE.md` | one Decisions row: adopt moves, never deletes |
| `CHANGELOG.md`, `specs/SPEC_MASTER.md` | entry; row 06 to `done` at delivery |

### Read (allow-list)

- `AGENTS.md`, `ARCHITECTURE.md`, `tests/test_adopt.sh`, `tests/lib.sh`
- `init.sh` — use `grep -n` and ranged reads; `main()` is at the end (about line 708)
- `docs/guide-utilisation.md` sections 2 and 10

### Reuse (from the registry)

- `init.sh` `resolve_project`, `check_path_links`, `safe_relative_path`, `sha256` helper — path safety and hashing

### Style exemplars

- `init.sh` `update_managed_pair` — error handling, `printf` output, no `jq`, bash 3.2

### Libraries

- None. POSIX tools only (`mv`, `mkdir -p`, `find`, `date`, `cmp`).

### Forbidden

- Any file not listed above. Editing `tests/test_adopt.sh`.
- Deleting user files, touching `settings.json`, `.mcp.json` or `~/.claude`.
- `jq`, prompts, network, associative arrays.
- Raising a line budget in `lint-docs.sh`.

## Out of scope

- Merging old rules into `ARCHITECTURE.md` automatically; the Advisor does it from the printed content.
- Restore command. Backup is plain files; the guide says `mv` them back.

## Handoffs
