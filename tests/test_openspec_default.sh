#!/usr/bin/env bash
set -eu

TEST_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd -P)
ROOT=$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)
# shellcheck source=tests/lib.sh
. "$TEST_DIR/lib.sh"
new_project

project="$TEST_ROOT/proj"
mkdir -p "$project"
"$ROOT/init.sh" install "$project" >/dev/null

# Framework files are installed.
assert_file "$project/.agents-fw/procedures/openspec-flow.md"
assert_file "$project/.agents-fw/templates/FRAME.md"
assert_file_contains "$project/.agents-fw/rules/workflow.md" 'WF-9 MUST'
assert_file_contains "$project/AGENTS.md" 'OpenSpec'
flow=$(cat "$project/.agents-fw/procedures/openspec-flow.md")
for needle in 'openspec init' 'openspec-explore' 'openspec-propose' 'openspec-apply-change' \
  'openspec-archive-change' 'frame.md' 'tasks.md'; do
  assert_contains "$flow" "$needle"
done
frame=$(cat "$project/.agents-fw/templates/FRAME.md")
assert_contains "$frame" 'locked_tests'
assert_contains "$frame" '### Create'

# Scripts accept a frame.md inside an OpenSpec change folder.
git_init "$project"
change="$project/openspec/changes/add-charges"
mkdir -p "$change" "$project/tests"
printf 'test source\n' >"$project/tests/t.sh"
git -C "$project" add tests/t.sh
git -C "$project" commit -qm 'lock tests'
sha=$(git -C "$project" rev-parse HEAD)
cat >"$change/frame.md" <<EOT
---
id: add-charges
status: ready
tier: small
locked_at: $sha
locked_tests:
  - tests/t.sh
---
# frame
EOT
(cd "$project" && .agents-fw/scripts/test-lock.sh openspec/changes/add-charges/frame.md)
created=$(cd "$project" && .agents-fw/scripts/new-handoff.sh openspec/changes/add-charges/frame.md)
case "$created" in
  docs/handoffs/*-add-charges.md) ;;
  *) fail "unexpected handoff path: $created" ;;
esac
assert_file "$project/$created"

# The docs say OpenSpec is the default.
section=$(awk '/^## Coexister avec OpenSpec/{f=1;next} f&&/^## /{exit} f{print}' "$ROOT/docs/guide-utilisation.md")
assert_contains "$section" 'par défaut'
bash "$ROOT/framework/scripts/lint-docs.sh" --root "$ROOT" "$ROOT/framework" >/dev/null
