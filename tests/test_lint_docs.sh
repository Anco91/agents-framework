#!/usr/bin/env bash
set -eu

TEST_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd -P)
ROOT=$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)
# shellcheck source=tests/lib.sh
. "$TEST_DIR/lib.sh"
new_project

framework="$TEST_ROOT/framework"
mkdir -p "$framework/rules" "$framework/standards" "$framework/procedures" "$framework/templates"
cat >"$framework/core.md" <<'EOF'
# Core
[link](target.md)
[external](https://example.com) [anchor](#section)
<!-- [ignored](absent.md) -->
```md
[fenced](absent-fenced.md)
```
`[inline](absent-inline.md)`
EOF
printf 'target\n' >"$framework/target.md"
printf '%s\n' '- **WF-1 MUST** — workflow rule.' >"$framework/rules/workflow.md"
printf '%s\n' '- **ARCH-1 SHOULD** — architecture rule.' >"$framework/standards/architecture.md"
cat >"$framework/templates/HANDOFF.md" <<'EOF'
# Handoff

```
NEXT SESSION
Role: <advisor|executor|reviewer>
Read: AGENTS.md, ARCHITECTURE.md, <path>
Sub-spec: <path>
First action: <sentence>
```
EOF
cp "$framework/templates/HANDOFF.md" "$framework/procedures/handoff.md"
"$ROOT/framework/scripts/lint-docs.sh" "$framework"

printf '%s\n' '- **WF-1 MAY** — duplicate.' >"$framework/standards/duplicate.md"
if "$ROOT/framework/scripts/lint-docs.sh" "$framework" >"$TEST_ROOT/duplicate.out" 2>&1; then
  fail "lint-docs accepted a duplicate rule ID"
fi
assert_file_contains "$TEST_ROOT/duplicate.out" 'WF-1'
rm "$framework/standards/duplicate.md"

printf '[missing](absent.md)\n' >>"$framework/rules/workflow.md"
if "$ROOT/framework/scripts/lint-docs.sh" "$framework" >"$TEST_ROOT/link.out" 2>&1; then
  fail "lint-docs accepted a broken Markdown link"
fi
assert_file_contains "$TEST_ROOT/link.out" 'absent.md'
printf '%s\n' '- **WF-1 MUST** — workflow rule.' >"$framework/rules/workflow.md"

i=0
while [ "$i" -lt 81 ]; do
  printf 'line\n' >>"$framework/procedures/long.md"
  i=$((i + 1))
done
if "$ROOT/framework/scripts/lint-docs.sh" "$framework" >"$TEST_ROOT/budget.out" 2>&1; then
  fail "lint-docs accepted a procedure over the line budget"
fi
assert_file_contains "$TEST_ROOT/budget.out" 'long.md'
rm "$framework/procedures/long.md"

i=0
: >"$framework/procedures/unterminated.md"
while [ "$i" -lt 81 ]; do
  if [ "$i" -eq 0 ]; then
    printf 'line' >>"$framework/procedures/unterminated.md"
  else
    printf '\nline' >>"$framework/procedures/unterminated.md"
  fi
  i=$((i + 1))
done
if "$ROOT/framework/scripts/lint-docs.sh" "$framework" >"$TEST_ROOT/unterminated.out" 2>&1; then
  fail "lint-docs accepted an unterminated last line over the budget"
fi
assert_file_contains "$TEST_ROOT/unterminated.out" 'unterminated.md'
rm "$framework/procedures/unterminated.md"

i=0
: >"$framework/procedures/unterminated-ok.md"
while [ "$i" -lt 80 ]; do
  if [ "$i" -eq 0 ]; then
    printf 'line' >>"$framework/procedures/unterminated-ok.md"
  else
    printf '\nline' >>"$framework/procedures/unterminated-ok.md"
  fi
  i=$((i + 1))
done
"$ROOT/framework/scripts/lint-docs.sh" "$framework"
rm "$framework/procedures/unterminated-ok.md"

printf 'different block\n' >"$framework/procedures/handoff.md"
if "$ROOT/framework/scripts/lint-docs.sh" "$framework" >"$TEST_ROOT/block.out" 2>&1; then
  fail "lint-docs accepted a different handoff block"
fi
assert_file_contains "$TEST_ROOT/block.out" 'NEXT SESSION'
rm "$framework/procedures/handoff.md"
out=$("$ROOT/framework/scripts/lint-docs.sh" "$framework" 2>&1)
assert_contains "$out" 'warning'
