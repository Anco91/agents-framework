#!/usr/bin/env bash
set -eu

TEST_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd -P)
ROOT=$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)
# shellcheck source=tests/lib.sh
. "$TEST_DIR/lib.sh"
new_project

snapshot() {
  (cd "$1" && find . -type f -exec cksum {} + | sort)
}

project="$TEST_ROOT/legacy"
mkdir -p "$project/.claude/rules" "$project/.claude/agents" "$project/.claude/skills/old-skill" \
  "$project/.cursor/rules" "$project/.kilocode/rules" "$project/.github"
printf 'Build: make test\nStack: Go 1.22\n' >"$project/CLAUDE.md"
printf 'Domain: invoices\n' >"$project/.claude/rules/stack.md"
printf 'old agent\n' >"$project/.claude/agents/old.md"
printf 'old skill\n' >"$project/.claude/skills/old-skill/SKILL.md"
printf 'cursor legacy\n' >"$project/.cursorrules"
printf 'cursor rule\n' >"$project/.cursor/rules/a.mdc"
printf 'kilo rule\n' >"$project/.kilocode/rules/k.md"
printf 'copilot rule\n' >"$project/.github/copilot-instructions.md"
printf 'aider conventions\n' >"$project/CONVENTIONS.md"
printf '{"permissions":{}}\n' >"$project/.claude/settings.json"
printf '{"mcpServers":{}}\n' >"$project/.mcp.json"
printf '# My project\n\nKeep this line.\n' >"$project/AGENTS.md"
git_init "$project"

# Missing project and unknown option fail with usage.
if "$ROOT/init.sh" adopt >"$TEST_ROOT/missing.out" 2>&1; then
  fail "adopt accepted a missing project argument"
fi
assert_file_contains "$TEST_ROOT/missing.out" 'usage:'
if "$ROOT/init.sh" adopt "$project" --bogus >"$TEST_ROOT/bogus.out" 2>&1; then
  fail "adopt accepted an unknown option"
fi
assert_file_contains "$TEST_ROOT/bogus.out" 'usage:'

# Dry run: prints the plan and the old rule content, changes nothing.
before=$(snapshot "$project")
dry=$("$ROOT/init.sh" adopt "$project" --host claude)
after=$(snapshot "$project")
assert_eq "$before" "$after" "dry run changed files"
assert_no_file "$project/.agents-fw"
assert_contains "$dry" 'would move  CLAUDE.md'
assert_contains "$dry" 'would move  .claude/rules/stack.md'
assert_contains "$dry" 'would move  .claude/agents/old.md'
assert_contains "$dry" 'would move  .claude/skills/old-skill'
assert_contains "$dry" 'would move  .cursorrules'
assert_contains "$dry" 'would move  .cursor/rules/a.mdc'
assert_contains "$dry" 'would move  .kilocode/rules/k.md'
assert_contains "$dry" 'would move  .github/copilot-instructions.md'
assert_contains "$dry" 'would move  CONVENTIONS.md'
assert_contains "$dry" 'left alone  .claude/settings.json'
assert_contains "$dry" 'left alone  .mcp.json'
assert_contains "$dry" 'Build: make test'
assert_contains "$dry" 'Domain: invoices'
assert_contains "$dry" '--apply'

# Apply: framework installed, originals in backup, user files untouched.
out=$("$ROOT/init.sh" adopt "$project" --host claude --apply)
assert_contains "$out" 'moved  CLAUDE.md'
backup_count=$(find "$project/.agents-fw/backup" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
assert_eq 1 "$backup_count" "one backup directory"
backup=$(find "$project/.agents-fw/backup" -mindepth 1 -maxdepth 1 -type d)
assert_file_contains "$backup/CLAUDE.md" 'Build: make test'
assert_file_contains "$backup/.claude/rules/stack.md" 'Domain: invoices'
assert_file_contains "$backup/.claude/agents/old.md" 'old agent'
assert_file_contains "$backup/.claude/skills/old-skill/SKILL.md" 'old skill'
assert_file_contains "$backup/.cursorrules" 'cursor legacy'
assert_file_contains "$backup/.cursor/rules/a.mdc" 'cursor rule'
assert_file_contains "$backup/.kilocode/rules/k.md" 'kilo rule'
assert_file_contains "$backup/.github/copilot-instructions.md" 'copilot rule'
assert_file_contains "$backup/CONVENTIONS.md" 'aider conventions'
assert_no_file "$project/.claude/rules/stack.md"
assert_no_file "$project/.claude/agents/old.md"
assert_no_file "$project/.claude/skills/old-skill"
assert_no_file "$project/.cursorrules"
assert_no_file "$project/.cursor/rules/a.mdc"
assert_no_file "$project/.kilocode/rules/k.md"
assert_no_file "$project/.github/copilot-instructions.md"
assert_no_file "$project/CONVENTIONS.md"
assert_file_contains "$project/CLAUDE.md" '@AGENTS.md'
assert_file "$project/.claude/agents/agents-fw-executor.md"
assert_file "$project/.agents-fw/MANIFEST"
assert_file "$project/ARCHITECTURE.md"
assert_file_contains "$project/AGENTS.md" 'Keep this line.'
assert_file_contains "$project/AGENTS.md" '<!-- agents-fw:start -->'
assert_eq '{"permissions":{}}' "$(cat "$project/.claude/settings.json")" "settings.json changed"
assert_eq '{"mcpServers":{}}' "$(cat "$project/.mcp.json")" "mcp.json changed"

# Second apply: nothing to move, framework files stay, no new backup.
before=$(snapshot "$project")
again=$("$ROOT/init.sh" adopt "$project" --host claude --apply)
assert_contains "$again" 'nothing to adopt'
assert_file "$project/.claude/agents/agents-fw-executor.md"
backup_count=$(find "$project/.agents-fw/backup" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
assert_eq 1 "$backup_count" "no second backup directory"
assert_eq "$before" "$(snapshot "$project")" "second apply changed files"

# Project without legacy files: dry run reports it and writes nothing.
clean="$TEST_ROOT/clean"
mkdir "$clean"
out=$("$ROOT/init.sh" adopt "$clean")
assert_contains "$out" 'nothing to adopt'
assert_no_file "$clean/.agents-fw"
