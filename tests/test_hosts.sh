#!/usr/bin/env bash
set -eu

TEST_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd -P)
ROOT=$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)
# shellcheck source=tests/lib.sh
. "$TEST_DIR/lib.sh"
new_project

hosts_output=$("$ROOT/init.sh" hosts)
assert_contains "$hosts_output" 'claude: CLAUDE.md'
assert_contains "$hosts_output" '.kilo/agents/agents-fw-advisor.md'
assert_contains "$hosts_output" '.kilo/agents/agents-fw-executor.md'
assert_contains "$hosts_output" 'aider: .aider.conf.yml'
assert_contains "$hosts_output" '.agents/skills/agents-fw-write-sub-spec/SKILL.md'

project="$TEST_ROOT/unknown-host"
mkdir "$project"
if "$ROOT/init.sh" install "$project" --host unknown >"$TEST_ROOT/unknown-host.out" 2>&1; then
  fail "install accepted an unknown host"
fi
assert_file_contains "$TEST_ROOT/unknown-host.out" 'usage:'
[ -z "$(find "$project" -mindepth 1 -print -quit)" ] || fail "unknown host wrote project files"

project="$TEST_ROOT/claude"
mkdir "$project"
"$ROOT/init.sh" install "$project" --host claude >/dev/null
assert_file "$project/CLAUDE.md"
assert_file_contains "$project/CLAUDE.md" '@AGENTS.md'
assert_eq 'hosts claude' "$(sed -n '2p' "$project/.agents-fw/MANIFEST")" "Claude manifest hosts"
assert_no_file "$project/.aider.conf.yml"
assert_no_file "$project/.kilo/agents/agents-fw-advisor.md"
assert_no_file "$project/.agents/skills"

project="$TEST_ROOT/kilo"
mkdir -p "$project/.kilo/agents"
printf 'user Kilo config\n' >"$project/kilo.jsonc"
cp "$TEST_DIR/fixtures/advisor.md" "$project/.kilo/agents/advisor.md"
cp "$project/kilo.jsonc" "$TEST_ROOT/kilo-config.expected"
cp "$project/.kilo/agents/advisor.md" "$TEST_ROOT/kilo-advisor.expected"
"$ROOT/init.sh" install "$project" --host kilo >"$TEST_ROOT/kilo.out"
assert_file "$project/.kilo/agents/agents-fw-advisor.md"
assert_file "$project/.kilo/agents/agents-fw-executor.md"
assert_file "$project/.agents-fw/adapters/kilo/kilo.jsonc.example"
cmp "$ROOT/adapters/kilo/kilo.jsonc.example" "$project/.agents-fw/adapters/kilo/kilo.jsonc.example"
assert_file_contains "$project/.kilo/agents/agents-fw-advisor.md" 'description: Writes sub-specs, frames and locked tests; never production code'
assert_file_contains "$project/.kilo/agents/agents-fw-advisor.md" 'mode: primary'
assert_file_contains "$project/.kilo/agents/agents-fw-advisor.md" '"**/*.test.*": "allow"'
assert_file_contains "$project/.kilo/agents/agents-fw-executor.md" 'description: Implements one ready sub-spec inside its Frame'
assert_file_contains "$project/.kilo/agents/agents-fw-executor.md" '"**/*.test.*": "deny"'
if grep -F 'model:' "$project/.kilo/agents/agents-fw-advisor.md" "$project/.kilo/agents/agents-fw-executor.md" >/dev/null; then
  fail "Kilo agent files set a model"
fi
assert_file_contains "$TEST_ROOT/kilo.out" 'Kilo model configuration example: .agents-fw/adapters/kilo/kilo.jsonc.example'
cmp "$TEST_ROOT/kilo-config.expected" "$project/kilo.jsonc"
cmp "$TEST_ROOT/kilo-advisor.expected" "$project/.kilo/agents/advisor.md"
assert_no_file "$project/.kilo/kilo.jsonc"
assert_no_file "$project/.aider.conf.yml"
assert_no_file "$project/CLAUDE.md"
assert_no_file "$project/.agents/skills"

project="$TEST_ROOT/aider"
mkdir "$project"
"$ROOT/init.sh" install "$project" --host aider >/dev/null
assert_eq 'read: [AGENTS.md, ARCHITECTURE.md]' "$(cat "$project/.aider.conf.yml")" "Aider read list"
assert_no_file "$project/CLAUDE.md"
assert_no_file "$project/.kilo/agents/agents-fw-advisor.md"
assert_no_file "$project/.agents/skills"

project="$TEST_ROOT/skills"
mkdir "$project"
"$ROOT/init.sh" install "$project" --host skills >/dev/null
procedure_count=$(find "$ROOT/framework/procedures" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
skill_count=$(find "$project/.agents/skills" -type f -name SKILL.md | wc -l | tr -d ' ')
assert_eq "$procedure_count" "$skill_count" "generated skill count"
for procedure in "$ROOT"/framework/procedures/*.md; do
  name=${procedure##*/}
  name=${name%.md}
  skill="$project/.agents/skills/agents-fw-$name/SKILL.md"
  assert_file "$skill"
  assert_file_contains "$skill" "name: agents-fw-$name"
  expected_description=$(awk '
    /^Use when: / {
      value = substr($0, 11)
      sub(/\. Role:.*/, "", value)
      print value
      exit
    }
  ' "$procedure")
  actual_description=$(sed -n '3s/^description: //p' "$skill")
  assert_eq "$expected_description" "$actual_description" "skill description for $name"
  tail -n +6 "$skill" >"$TEST_ROOT/skill-body"
  cmp "$procedure" "$TEST_ROOT/skill-body"
done
assert_no_file "$project/CLAUDE.md"
assert_no_file "$project/.aider.conf.yml"
assert_no_file "$project/.kilo/agents/agents-fw-advisor.md"

project="$TEST_ROOT/claude-conflict"
mkdir "$project"
printf 'user-owned CLAUDE.md\n' >"$project/CLAUDE.md"
cp "$project/CLAUDE.md" "$TEST_ROOT/claude.expected"
"$ROOT/init.sh" install "$project" --host claude >/dev/null
cmp "$TEST_ROOT/claude.expected" "$project/CLAUDE.md"
assert_file "$project/CLAUDE.md.new"
"$ROOT/init.sh" update "$project" --host claude --force >/dev/null
cmp "$ROOT/adapters/claude/CLAUDE.md" "$project/CLAUDE.md"
assert_no_file "$project/CLAUDE.md.new"

source_repo="$TEST_ROOT/source"
cp -R "$ROOT" "$source_repo"
project="$TEST_ROOT/recorded-hosts"
mkdir "$project"
"$source_repo/init.sh" install "$project" --host claude,skills >/dev/null
assert_eq 'hosts claude,skills' "$(sed -n '2p' "$project/.agents-fw/MANIFEST")" "recorded hosts"
printf 'Use when: changed procedure trigger. Role: Advisor.\n\nUpdated procedure body.\n' \
  >"$source_repo/framework/procedures/write-sub-spec.md"
"$source_repo/init.sh" update "$project" >/dev/null
assert_file "$project/CLAUDE.md"
skill="$project/.agents/skills/agents-fw-write-sub-spec/SKILL.md"
assert_file_contains "$skill" 'description: changed procedure trigger'
assert_file_contains "$skill" 'Updated procedure body.'

project="$TEST_ROOT/legacy-manifest"
mkdir "$project"
"$ROOT/init.sh" install "$project" --host claude >/dev/null
awk 'NR != 2 && $0 !~ /  CLAUDE\.md$/ { print }' "$project/.agents-fw/MANIFEST" \
  >"$TEST_ROOT/legacy-manifest-file"
mv "$TEST_ROOT/legacy-manifest-file" "$project/.agents-fw/MANIFEST"
"$ROOT/init.sh" update "$project" >/dev/null
assert_file "$project/CLAUDE.md"
case "$(cat "$project/.agents-fw/MANIFEST")" in
  *'hosts '*) fail "legacy manifest unexpectedly retained hosts" ;;
esac

project="$TEST_ROOT/removed-hosts"
mkdir "$project"
"$source_repo/init.sh" install "$project" --host claude,kilo,aider,skills >/dev/null
"$source_repo/init.sh" update "$project" --host aider >/dev/null
assert_file "$project/.aider.conf.yml"
assert_no_file "$project/CLAUDE.md"
assert_no_file "$project/.kilo/agents/agents-fw-advisor.md"
assert_no_file "$project/.kilo/agents/agents-fw-executor.md"
assert_no_file "$project/.agents-fw/adapters/kilo/kilo.jsonc.example"
skill_files=$(find "$project/.agents/skills" -type f -name SKILL.md -print 2>/dev/null || true)
assert_eq '' "$skill_files" "removed generated skills"
assert_eq 'hosts aider' "$(sed -n '2p' "$project/.agents-fw/MANIFEST")" "reduced host list"
