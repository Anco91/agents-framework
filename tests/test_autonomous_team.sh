#!/usr/bin/env bash
set -eu

TEST_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd -P)
ROOT=$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)
# shellcheck source=tests/lib.sh
. "$TEST_DIR/lib.sh"
new_project

project="$TEST_ROOT/proj"
mkdir -p "$project"
"$ROOT/init.sh" install "$project" --host claude >/dev/null

auto="$project/.agents-fw/rules/autonomy.md"
assert_file "$auto"
for id in AUTO-1 AUTO-2 AUTO-3 AUTO-4 AUTO-5 AUTO-6; do
  assert_file_contains "$auto" "$id MUST"
done
assert_file "$project/.agents-fw/procedures/kickoff.md"
assert_file "$project/.agents-fw/procedures/pm-loop.md"
assert_file_contains "$project/.agents-fw/rules/roles.md" 'ROLE-11 MUST'

# The human gates stay the only stop.
assert_file_contains "$auto" 'GIT-7'
assert_file_contains "$project/AGENTS.md" 'AUTO-1'
if grep -F 'no agent spawned unasked' "$project/AGENTS.md" >/dev/null; then
  fail "core still forbids spawning team agents"
fi

# Validation and blockers go to the PM, not to the human.
if grep -F 'validated by the human' "$project/.agents-fw/rules/workflow.md" >/dev/null; then
  fail "WF-1 still requires human validation"
fi
if grep -F 'stops and asks' "$project/.agents-fw/rules/roles.md" >/dev/null; then
  fail "ROLE-4 still asks the human"
fi

# Claude PM agent: tier alias, no provider slug.
pm="$project/.claude/agents/agents-fw-pm.md"
assert_file "$pm"
assert_file_contains "$pm" 'model: sonnet'
assert_file_contains "$pm" 'kickoff.md'
if grep -E '^model:.*/' "$pm" >/dev/null; then
  fail "PM agent uses a model slug"
fi
hosts=$("$ROOT/init.sh" hosts)
assert_contains "$hosts" 'agents-fw-pm.md'

bash "$ROOT/framework/scripts/lint-docs.sh" --root "$ROOT" "$ROOT/framework" >/dev/null
