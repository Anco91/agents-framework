#!/usr/bin/env bash
set -eu

TEST_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd -P)
ROOT=$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)
# shellcheck source=tests/lib.sh
. "$TEST_DIR/lib.sh"
new_project

project="$TEST_ROOT/project"
mkdir -p "$project/specs"
cat >"$project/specs/example.md" <<'EOF'
---
id: 12-example
---
EOF
created=$(cd "$project" && "$ROOT/framework/scripts/new-handoff.sh" specs/example.md)
case "$created" in
  docs/handoffs/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]-12-example.md) ;;
  *) fail "unexpected handoff path: $created" ;;
esac
assert_file "$project/$created"
assert_file_contains "$project/$created" '# Handoff — 12-example — '
assert_file_contains "$project/$created" "Sub-spec: \`specs/example.md\`"
assert_file_contains "$project/$created" "Handoff: \`$created\`"

second=$(cd "$project" && "$ROOT/framework/scripts/new-handoff.sh" specs/example.md)
[ "$created" != "$second" ] || fail "handoff collision reused the same path"
case "$second" in
  *-12-example-2.md) ;;
  *) fail "unexpected collision suffix: $second" ;;
esac
assert_file "$project/$second"

printf 'No id metadata\n' >"$project/specs/fallback-name.md"
fallback=$(cd "$project" && "$ROOT/framework/scripts/new-handoff.sh" specs/fallback-name.md)
case "$fallback" in
  *-fallback-name.md) ;;
  *) fail "basename fallback was not used: $fallback" ;;
esac

if (cd "$project" && "$ROOT/framework/scripts/new-handoff.sh" specs/absent.md) >"$TEST_ROOT/missing.out" 2>&1; then
  fail "new-handoff accepted a missing sub-spec"
fi
[ ! -d "$project/docs/handoffs" ] || [ -z "$(find "$project/docs/handoffs" -name '*absent*' -print -quit)" ] || fail "missing sub-spec created a handoff"
