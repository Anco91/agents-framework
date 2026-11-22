#!/usr/bin/env bash
set -eu

TEST_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd -P)
ROOT=$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)
# shellcheck source=tests/lib.sh
. "$TEST_DIR/lib.sh"
new_project

source_repo="$TEST_ROOT/source"
cp -R "$ROOT" "$source_repo"
printf 'source v1\n' >"$source_repo/framework/update-sample.md"
project="$TEST_ROOT/project"
mkdir "$project"
"$source_repo/init.sh" install "$project" >/dev/null
manifest="$project/.agents-fw/MANIFEST"

printf 'source v2\n' >"$source_repo/framework/update-sample.md"
out=$("$source_repo/init.sh" update "$project")
assert_contains "$out" 'updated  .agents-fw/update-sample.md'
assert_eq 'source v2' "$(cat "$project/.agents-fw/update-sample.md")" "updated source"

printf 'local edit\n' >"$project/.agents-fw/update-sample.md"
out=$("$source_repo/init.sh" update "$project")
assert_contains "$out" 'kept (.new)  .agents-fw/update-sample.md'
assert_eq 'local edit' "$(cat "$project/.agents-fw/update-sample.md")" "preserved local edit"
assert_eq 'source v2' "$(cat "$project/.agents-fw/update-sample.md.new")" "new upstream version"

"$source_repo/init.sh" update "$project" --force >/dev/null
assert_eq 'source v2' "$(cat "$project/.agents-fw/update-sample.md")" "forced update"

printf 'remove unchanged\n' >"$source_repo/framework/remove-sample.md"
"$source_repo/init.sh" update "$project" >/dev/null
rm "$source_repo/framework/remove-sample.md"
out=$("$source_repo/init.sh" update "$project")
assert_contains "$out" 'removed  .agents-fw/remove-sample.md'
assert_no_file "$project/.agents-fw/remove-sample.md"

printf 'remove modified\n' >"$source_repo/framework/modified-remove.md"
"$source_repo/init.sh" update "$project" >/dev/null
printf 'local retained\n' >"$project/.agents-fw/modified-remove.md"
rm "$source_repo/framework/modified-remove.md"
out=$("$source_repo/init.sh" update "$project")
assert_contains "$out" 'kept (modified, removed upstream)  .agents-fw/modified-remove.md'
assert_eq 'local retained' "$(cat "$project/.agents-fw/modified-remove.md")" "retained removed file"

printf 'managed core v2\n' >"$source_repo/framework/core.md"
printf 'outside before\n<!-- agents-fw:start -->\nold\n<!-- agents-fw:end -->\noutside after\n' >"$project/AGENTS.md"
printf 'outside before\n' >"$TEST_ROOT/update.before"
printf 'outside after\n' >"$TEST_ROOT/update.after"
"$source_repo/init.sh" update "$project" >/dev/null
assert_file_contains "$project/AGENTS.md" 'managed core v2'
awk '$0 == "<!-- agents-fw:start -->" { exit } { print }' "$project/AGENTS.md" >"$TEST_ROOT/update.before.actual"
awk 'found { print } $0 == "<!-- agents-fw:end -->" { found = 1; next }' "$project/AGENTS.md" >"$TEST_ROOT/update.after.actual"
cmp "$TEST_ROOT/update.before" "$TEST_ROOT/update.before.actual"
cmp "$TEST_ROOT/update.after" "$TEST_ROOT/update.after.actual"

printf 'project-owned architecture\n' >"$project/ARCHITECTURE.md"
mkdir -p "$project/specs" "$project/docs/handoffs"
printf 'project-owned spec\n' >"$project/specs/SPEC_MASTER.md"
printf 'keep\n' >"$project/docs/handoffs/keep.md"
cp "$project/ARCHITECTURE.md" "$TEST_ROOT/architecture"
cp "$project/specs/SPEC_MASTER.md" "$TEST_ROOT/spec-master"
"$source_repo/init.sh" update "$project" >/dev/null
cmp "$TEST_ROOT/architecture" "$project/ARCHITECTURE.md"
cmp "$TEST_ROOT/spec-master" "$project/specs/SPEC_MASTER.md"
assert_file "$project/docs/handoffs/keep.md"

if [ "$(id -u)" -ne 0 ]; then
  cp "$manifest" "$TEST_ROOT/manifest.before"
  chmod 000 "$source_repo/framework/update-sample.md"
  if "$source_repo/init.sh" update "$project" >"$TEST_ROOT/interrupted.out" 2>&1; then
    chmod 644 "$source_repo/framework/update-sample.md"
    fail "update succeeded with an unreadable source"
  fi
  cmp "$TEST_ROOT/manifest.before" "$manifest"
  chmod 644 "$source_repo/framework/update-sample.md"
  "$source_repo/init.sh" update "$project" >/dev/null
fi

assert_eq "1" "$(grep -cF '<!-- agents-fw:start -->' "$project/AGENTS.md")" "managed block count after update"
