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

printf 'baseline v1\n' >"$source_repo/framework/manifest-baseline.md"
"$source_repo/init.sh" update "$project" >/dev/null
printf 'baseline local edit\n' >"$project/.agents-fw/manifest-baseline.md"
printf 'baseline v2\n' >"$source_repo/framework/manifest-baseline.md"
out=$("$source_repo/init.sh" update "$project")
assert_contains "$out" 'kept (.new)  .agents-fw/manifest-baseline.md'
assert_eq 'baseline local edit' "$(cat "$project/.agents-fw/manifest-baseline.md")" "preserved baseline edit"
assert_eq 'baseline v2' "$(cat "$project/.agents-fw/manifest-baseline.md.new")" "first .new baseline"
printf 'baseline v3\n' >"$source_repo/framework/manifest-baseline.md"
out=$("$source_repo/init.sh" update "$project")
assert_contains "$out" 'kept (.new)  .agents-fw/manifest-baseline.md'
assert_eq 'baseline local edit' "$(cat "$project/.agents-fw/manifest-baseline.md")" "preserved baseline edit on retry"
assert_eq 'baseline v3' "$(cat "$project/.agents-fw/manifest-baseline.md.new")" "refreshed .new baseline"
rm "$source_repo/framework/manifest-baseline.md"
out=$("$source_repo/init.sh" update "$project")
assert_contains "$out" 'kept (modified, removed upstream)  .agents-fw/manifest-baseline.md'
assert_eq 'baseline local edit' "$(cat "$project/.agents-fw/manifest-baseline.md")" "preserved edit after removal"
rm -f "$project/.agents-fw/manifest-baseline.md.new"

"$source_repo/init.sh" update "$project" --force >/dev/null
assert_eq 'source v2' "$(cat "$project/.agents-fw/update-sample.md")" "forced update"
rm -f "$project/.agents-fw/update-sample.md.new"

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

printf 'absent remove\n' >"$source_repo/framework/absent-remove.md"
"$source_repo/init.sh" update "$project" >/dev/null
rm "$project/.agents-fw/absent-remove.md"
rm "$source_repo/framework/absent-remove.md"
out=$("$source_repo/init.sh" update "$project")
case "$out" in
  *".agents-fw/absent-remove.md"*) fail "update reported an already-absent destination" ;;
esac

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
  printf 'partial update\n' >>"$source_repo/framework/core.md"
  cp "$source_repo/framework/core.md" "$project/.agents-fw/core.md"
  chmod 000 "$source_repo/framework/update-sample.md"
  if "$source_repo/init.sh" update "$project" >"$TEST_ROOT/interrupted.out" 2>&1; then
    chmod 644 "$source_repo/framework/update-sample.md"
    fail "update succeeded with an unreadable source"
  fi
  cmp "$TEST_ROOT/manifest.before" "$manifest"
  chmod 644 "$source_repo/framework/update-sample.md"
  "$source_repo/init.sh" update "$project" >/dev/null
  new_files=$(find "$project" -name '*.new' -print)
  assert_eq '' "$new_files" "no .new files after interrupted update"
fi

assert_eq "1" "$(grep -cF '<!-- agents-fw:start -->' "$project/AGENTS.md")" "managed block count after update"
