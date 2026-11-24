#!/usr/bin/env bash
set -eu

TEST_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd -P)
ROOT=$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)
# shellcheck source=tests/lib.sh
. "$TEST_DIR/lib.sh"
new_project

guide="$ROOT/docs/guide-utilisation.md"
assert_file_contains "$guide" '## Coexister avec OpenSpec'
section=$(awk '/^## Coexister avec OpenSpec/{f=1;next} f&&/^## /{exit} f{print}' "$guide")
assert_contains "$section" 'openspec/'
assert_contains "$section" 'specs/SPEC_MASTER.md'
assert_contains "$section" 'npx'

# init.sh never runs npx.
if grep -n 'npx' "$ROOT/init.sh" >/dev/null; then
  fail "init.sh mentions npx"
fi

# Install and update leave an existing openspec/ tree byte-identical.
project="$TEST_ROOT/proj"
mkdir -p "$project/openspec/specs/auth" "$project/openspec/changes"
printf '## Purpose\nAuth spec\n' >"$project/openspec/specs/auth/spec.md"
printf 'proposal\n' >"$project/openspec/changes/p.md"
before=$(cd "$project" && find openspec -type f -exec cksum {} + | sort)
"$ROOT/init.sh" install "$project" >/dev/null
"$ROOT/init.sh" update "$project" >/dev/null
after=$(cd "$project" && find openspec -type f -exec cksum {} + | sort)
assert_eq "$before" "$after" "openspec/ changed"
