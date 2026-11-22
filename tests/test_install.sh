#!/usr/bin/env bash
set -eu

TEST_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd -P)
ROOT=$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)
# shellcheck source=tests/lib.sh
. "$TEST_DIR/lib.sh"
new_project

home="$TEST_ROOT/home"
mkdir "$home"
if HOME="$home" "$ROOT/init.sh" install "$home" >"$TEST_ROOT/out" 2>&1; then
  fail "install accepted HOME"
fi
[ -z "$(find "$home" -mindepth 1 -print -quit)" ] || fail "HOME was modified"

if "$ROOT/init.sh" install >"$TEST_ROOT/out" 2>&1; then
  fail "install accepted a missing project argument"
fi
if "$ROOT/init.sh" install / >"$TEST_ROOT/out" 2>&1; then
  fail "install accepted /"
fi
if "$ROOT/init.sh" install "$TEST_ROOT/missing" >"$TEST_ROOT/out" 2>&1; then
  fail "install accepted a missing project directory"
fi
[ -z "$(find "$TEST_ROOT" -mindepth 1 -maxdepth 1 -name 'missing*' -print -quit)" ] || fail "missing project was created"
if "$ROOT/init.sh" install "$TEST_ROOT" --unknown >"$TEST_ROOT/unknown.out" 2>&1; then
  fail "install accepted an unknown option"
fi
assert_file_contains "$TEST_ROOT/unknown.out" 'usage:'

if [ "$(id -u)" -ne 0 ]; then
  project="$TEST_ROOT/unwritable-specs"
  mkdir -p "$project/specs"
  chmod 555 "$project/specs"
  if "$ROOT/init.sh" install "$project" >"$TEST_ROOT/unwritable-specs.out" 2>&1; then
    chmod 755 "$project/specs"
    fail "install succeeded with an unwritable specs directory"
  fi
  chmod 755 "$project/specs"
  case "$(cat "$TEST_ROOT/unwritable-specs.out")" in
    *'created  specs/SPEC_MASTER.md'*) fail "reported a project file created after copy failure" ;;
  esac
  assert_no_file "$project/specs/SPEC_MASTER.md"
fi

project="$TEST_ROOT/empty"
mkdir "$project"
"$ROOT/init.sh" install "$project" >"$TEST_ROOT/install.out"
assert_file "$project/.agents-fw/MANIFEST"
assert_file "$project/AGENTS.md"
assert_file "$project/ARCHITECTURE.md"
assert_file "$project/specs/SPEC_MASTER.md"
assert_file "$project/docs/handoffs/.gitkeep"
assert_file "$project/.agents-fw/scripts/test-lock.sh"
[ -x "$project/.agents-fw/scripts/test-lock.sh" ] || fail "installed scripts lost executable bits"
assert_eq "version $(cat "$ROOT/VERSION")" "$(head -n 1 "$project/.agents-fw/MANIFEST")" "manifest version"
assert_file_contains "$project/AGENTS.md" '<!-- agents-fw:start -->'
assert_file_contains "$project/AGENTS.md" '<!-- agents-fw:end -->'

project="$TEST_ROOT/no-markers"
mkdir "$project"
printf 'Project-owned prefix\nsecond line\n' >"$project/AGENTS.md"
cp "$project/AGENTS.md" "$TEST_ROOT/agents.prefix"
"$ROOT/init.sh" install "$project" >/dev/null
head -c "$(wc -c <"$TEST_ROOT/agents.prefix" | tr -d ' ')" "$project/AGENTS.md" >"$TEST_ROOT/agents.actual"
cmp "$TEST_ROOT/agents.prefix" "$TEST_ROOT/agents.actual"

project="$TEST_ROOT/markers"
mkdir "$project"
printf 'before\n<!-- agents-fw:start -->\nold managed content\n<!-- agents-fw:end -->\nafter\n' >"$project/AGENTS.md"
printf 'before\n' >"$TEST_ROOT/before"
printf 'after\n' >"$TEST_ROOT/after"
"$ROOT/init.sh" install "$project" >/dev/null
awk '$0 == "<!-- agents-fw:start -->" { exit } { print }' "$project/AGENTS.md" >"$TEST_ROOT/before.actual"
awk 'found { print } $0 == "<!-- agents-fw:end -->" { found = 1; next }' "$project/AGENTS.md" >"$TEST_ROOT/after.actual"
cmp "$TEST_ROOT/before" "$TEST_ROOT/before.actual"
cmp "$TEST_ROOT/after" "$TEST_ROOT/after.actual"

project="$TEST_ROOT/untouched"
mkdir -p "$project/skills" "$project/.kilo/agents"
printf 'project skill\n' >"$project/skills/foo.md"
cp "$TEST_DIR/fixtures/advisor.md" "$project/.kilo/agents/advisor.md"
cp "$project/skills/foo.md" "$TEST_ROOT/skill.expected"
cp "$project/.kilo/agents/advisor.md" "$TEST_ROOT/advisor.expected"
"$ROOT/init.sh" install "$project" >/dev/null
cmp "$TEST_ROOT/skill.expected" "$project/skills/foo.md"
cmp "$TEST_ROOT/advisor.expected" "$project/.kilo/agents/advisor.md"

printf 'owned architecture\n' >"$project/ARCHITECTURE.md"
cp "$project/ARCHITECTURE.md" "$TEST_ROOT/architecture.expected"
"$ROOT/init.sh" install "$project" >/dev/null
cmp "$TEST_ROOT/architecture.expected" "$project/ARCHITECTURE.md"
assert_eq "1" "$(grep -cF '<!-- agents-fw:start -->' "$project/AGENTS.md")" "managed block count"
