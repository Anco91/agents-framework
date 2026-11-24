#!/usr/bin/env bash
set -eu

TEST_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd -P)
ROOT=$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)
# shellcheck source=tests/lib.sh
. "$TEST_DIR/lib.sh"
new_project

export AGENTS_FW_STATE_DIR="$TEST_ROOT/state" AGENTS_FW_TOOL_LIMIT=3
gauge="$ROOT/framework/scripts/session-gauge.sh"

out=$("$gauge")
assert_eq '' "$out" "silent below the limit"
"$gauge" >/dev/null
out=$("$gauge")
assert_contains "$out" 'HANDOFF NOW'

hook_in='{"session_id":"abc-1","tool_name":"Bash"}'
printf '%s' "$hook_in" | "$gauge" --hook >/dev/null
printf '%s' "$hook_in" | "$gauge" --hook >/dev/null
out=$(printf '%s' "$hook_in" | "$gauge" --hook)
assert_contains "$out" '"additionalContext"'
assert_file "$AGENTS_FW_STATE_DIR/calls-abc-1"
