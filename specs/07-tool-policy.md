---
id: 07-tool-policy
status: ready
branch: feat/07-tool-policy
locked_at: 35bee6f
locked_tests:
  - tests/test_tool_policy.sh
tier: medium
---

# 07 — Tool policy

Master: `specs/SPEC_MASTER.md` · Rules: WF-3, WF-7, ROLE-1..4, TEST-1..5, CTX-2, CTX-6, CTX-7

## Goal

An agent picks tools in a fixed, cheap order, and a Claude project gets ready-to-merge examples
for `permissions.deny` and the Context7 MCP server. The framework never edits user configuration.

## Acceptance criteria

1. `framework/rules/context.md` gains `CTX-8 SHOULD`: tool order is registry in `ARCHITECTURE.md`, then ranged read or LSP/Serena, then a search limited to a declared folder, then Context7 or official docs for library APIs. The rule cites CTX-2, CTX-6 and CTX-7 and does not restate them.
2. `adapters/claude/settings.example.json` keeps its hook and adds `permissions.deny` with exactly: `Bash(git push --force:*)`, `Bash(git push -f:*)`, `Bash(ls -R:*)`, `Bash(find .:*)`, `Read(./.env)`, `Read(./.env.*)`.
3. `adapters/claude/mcp.example.json` is new: one `mcpServers.context7` entry launched with `npx`. No API key, token or model slug in either example.
4. `init.sh install` and `update` with host `claude` copy both examples to `.agents-fw/adapters/claude/`. Other hosts do not receive them. `print_hosts` lists the two paths on the `claude:` line.
5. `.claude/settings.json` and `.mcp.json` are never created, edited or removed by `init.sh`. Existing ones stay byte-identical.
6. The French guide gains a section "Politique d'outils": the order, how to merge the two examples by hand (no `jq`), and that Kilo and Aider are out of scope.
7. `tests/test_tool_policy.sh` passes; `tests/run.sh`, shellcheck, `lint-docs.sh` and `arch-check.sh` stay green.

## Frame

### Create

| Path | Role | Exports (signatures) |
|---|---|---|
| `adapters/claude/mcp.example.json` | Context7 MCP server example | — |

### Modify

| Path | Change |
|---|---|
| `framework/rules/context.md` | add `CTX-8 SHOULD` after CTX-7, with a `Why:` line, same layout as CTX-1..7 |
| `adapters/claude/settings.example.json` | add `permissions.deny` beside `hooks`; keep the hook untouched |
| `init.sh` | in `list_static_host_pairs`, `claude` case: add two `printf` pairs to `.agents-fw/adapters/claude/`; update the `claude:` line of `print_hosts` |
| `docs/guide-utilisation.md` | new French section "Politique d'outils" |
| `ARCHITECTURE.md` | one Decisions row: examples are shipped, user config is never merged by the framework |
| `CHANGELOG.md`, `specs/SPEC_MASTER.md` | entry; row 07 to `done` at delivery |

### Read (allow-list)

- `AGENTS.md`, `ARCHITECTURE.md`, `tests/test_tool_policy.sh`, `tests/lib.sh`
- `framework/rules/context.md`, `adapters/claude/settings.example.json`
- `init.sh` — `grep -n` and ranged reads: `list_static_host_pairs` (about line 168) and `print_hosts` (about line 211)
- `tests/test_hosts.sh` lines 1-15 (assertion on the `claude:` line)
- `docs/guide-utilisation.md` — section headings only, then the section you insert after

### Reuse (from the registry)

- `init.sh` `list_static_host_pairs` — existing pair mechanism, as used for the Kilo example

### Style exemplars

- `init.sh` Kilo `printf` pair in `list_static_host_pairs` — same form for the Claude pairs
- `framework/rules/context.md` CTX-6 — rule layout, one line of `Why:`

### Libraries

- None. The Context7 package name comes from Context7 or its official docs (CTX-7).

### Forbidden

- Any file not listed above. Editing `tests/test_tool_policy.sh`.
- Creating or editing `.claude/settings.json`, `.mcp.json` or anything under `~/.claude`.
- `jq`, prompts, network, `npx` calls from `init.sh`.
- Raising a line budget or changing an existing MUST rule.
- Merging the PR: see Delivery gate.

## Delivery gate

This slice changes permissions configuration. GIT-7 makes that a human gate: open the PR, state the
reason, and wait for the human. Do not merge.

## Tests

### Locked (written by the Advisor, failing before execution)

- `tests/test_tool_policy.sh` — pins CTX-8 text, deny entries, MCP example, install copies, user-config immutability, host scoping.

Proof of failure: `bash tests/test_tool_policy.sh` → `FAIL: expected .../framework/rules/context.md to contain '- **CTX-8 SHOULD**'`

### Proposed by the Executor

| Path | What it covers | Status |
|---|---|---|

### Test change requests

| Test | Reason | Proposal | Decision |
|---|---|---|---|

## Out of scope

- Kilo and Aider tool policy.
- Merging examples into a user's `settings.json` or `.mcp.json`.
- Per-project locked-test deny paths (a static file cannot name them; `test-lock.sh` stays the guard).

## Handoffs
