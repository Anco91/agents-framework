#!/usr/bin/env bash
set -eu

TEST_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd -P)
ROOT=$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)
# shellcheck source=tests/lib.sh
. "$TEST_DIR/lib.sh"
new_project

# The tool-order rule is delivered and cites the rules it orders.
assert_file_contains "$ROOT/framework/rules/context.md" '- **CTX-8 SHOULD**'
rule=$(awk '/^- \*\*CTX-8 /{f=1} f&&/^$/{exit} f{print}' "$ROOT/framework/rules/context.md")
assert_contains "$rule" 'CTX-2'
assert_contains "$rule" 'CTX-6'
assert_contains "$rule" 'CTX-7'
assert_contains "$rule" 'Context7'

# Adapter examples exist and carry the policy; no secret, no model slug.
settings="$ROOT/adapters/claude/settings.example.json"
mcp="$ROOT/adapters/claude/mcp.example.json"
assert_file "$settings"
assert_file "$mcp"
assert_file_contains "$settings" '"deny"'
assert_file_contains "$settings" '"Bash(git push --force:*)"'
assert_file_contains "$settings" '"Bash(git push -f:*)"'
assert_file_contains "$settings" '"Bash(ls -R:*)"'
assert_file_contains "$settings" '"Bash(find .:*)"'
assert_file_contains "$settings" '"Read(./.env)"'
assert_file_contains "$settings" '"Read(./.env.*)"'
assert_file_contains "$settings" 'session-gauge.sh --hook'
assert_file_contains "$mcp" '"context7"'
assert_file_contains "$mcp" '"mcpServers"'
for example in "$settings" "$mcp"; do
  if grep -E -i 'api[_-]?key|token|secret|sk-|claude-(opus|sonnet|haiku)' "$example" >/dev/null; then
    fail "secret or model slug in $example"
  fi
done

# Install with the claude host delivers the examples and never touches user config.
fresh="$TEST_ROOT/fresh"
mkdir "$fresh"
"$ROOT/init.sh" install "$fresh" --host claude >/dev/null
cmp "$settings" "$fresh/.agents-fw/adapters/claude/settings.example.json"
cmp "$mcp" "$fresh/.agents-fw/adapters/claude/mcp.example.json"
assert_file_contains "$fresh/.agents-fw/rules/context.md" 'CTX-8'
assert_no_file "$fresh/.claude/settings.json"
assert_no_file "$fresh/.mcp.json"

# Existing user config stays byte-identical across install and update.
kept="$TEST_ROOT/kept"
mkdir -p "$kept/.claude"
printf '{"permissions":{"allow":["Bash(make:*)"]}}\n' >"$kept/.claude/settings.json"
printf '{"mcpServers":{"mine":{}}}\n' >"$kept/.mcp.json"
cp "$kept/.claude/settings.json" "$TEST_ROOT/settings.expected"
cp "$kept/.mcp.json" "$TEST_ROOT/mcp.expected"
"$ROOT/init.sh" install "$kept" --host claude >/dev/null
"$ROOT/init.sh" update "$kept" >/dev/null
cmp "$TEST_ROOT/settings.expected" "$kept/.claude/settings.json"
cmp "$TEST_ROOT/mcp.expected" "$kept/.mcp.json"

# Other hosts do not receive the Claude examples.
other="$TEST_ROOT/other"
mkdir "$other"
"$ROOT/init.sh" install "$other" --host kilo >/dev/null
assert_no_file "$other/.agents-fw/adapters/claude/settings.example.json"
assert_no_file "$other/.agents-fw/adapters/claude/mcp.example.json"
