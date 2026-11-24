#!/usr/bin/env bash
set -eu

TEST_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd -P)
ROOT=$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)
# shellcheck source=tests/lib.sh
. "$TEST_DIR/lib.sh"
new_project

relay="$ROOT/framework/scripts/relay.sh"
assert_file_contains "$ROOT/framework/templates/HANDOFF.md" 'Stop: none | done | human-gate'
assert_file_contains "$ROOT/framework/rules/session.md" 'SES-9'

write_handoff() { # <dir> <name> <stop line>
  mkdir -p "$1/docs/handoffs"
  cat >"$1/docs/handoffs/$2.md" <<EOT
# Handoff

\`\`\`
NEXT SESSION
Role: executor
Read: AGENTS.md, ARCHITECTURE.md, docs/handoffs/$2.md
Sub-spec: specs/01-x.md (master: specs/SPEC_MASTER.md)
First action: do the thing
Stop: $3
\`\`\`
EOT
}

new_proj() { # <name> -> project with one open master row and handoff #1
  p="$TEST_ROOT/$1"
  mkdir -p "$p/specs" "$p/.agents-fw"
  printf '| # | Sub-spec | Outcome | Status | Last |\n|---|---|---|---|---|\n| 01 | `specs/01-x.md` | x | in-progress | — |\n' >"$p/specs/SPEC_MASTER.md"
  write_handoff "$p" 20260101-0001-x none
}

# Stub host: records each prompt, writes the next handoff; call 3 raises a human gate.
stub="$TEST_ROOT/stub.sh"
cat >"$stub" <<'EOT'
#!/bin/sh
n=$(cat calls 2>/dev/null || echo 0)
n=$((n + 1))
printf '%s\n' "$n" >calls
cat >"prompt-$n"
stop=none
[ "$n" -lt 3 ] || stop='human-gate: migration'
{
  printf '# Handoff\n\n```\nNEXT SESSION\nRole: executor\nFirst action: step %s\nStop: %s\n```\n' "$n" "$stop"
} >"docs/handoffs/2026010${n}-0001-x.md"
EOT
chmod +x "$stub"

# 1. Missing command.
new_proj p1
if AGENTS_FW_RELAY_CMD='' "$relay" --root "$TEST_ROOT/p1" >"$TEST_ROOT/o1" 2>&1; then fail "relay ran without a command"; fi
assert_file_contains "$TEST_ROOT/o1" 'AGENTS_FW_RELAY_CMD'

# 2. Runs until a human gate.
new_proj p2
out=$(cd "$TEST_ROOT/p2" && AGENTS_FW_RELAY_CMD="$stub" "$relay" 2>&1)
assert_eq 3 "$(cat "$TEST_ROOT/p2/calls")" "calls until human gate"
assert_contains "$out" 'human-gate: migration'
assert_file_contains "$TEST_ROOT/p2/prompt-1" 'First action: do the thing'
assert_file_contains "$TEST_ROOT/p2/prompt-2" 'First action: step 1'

# 3. No new handoff -> exit 3 after one call.
new_proj p3
noop="$TEST_ROOT/noop.sh"
printf '#!/bin/sh\ncat >/dev/null\nn=$(cat calls 2>/dev/null || echo 0); echo $((n+1)) >calls\n' >"$noop"
chmod +x "$noop"
rc=0
(cd "$TEST_ROOT/p3" && AGENTS_FW_RELAY_CMD="$noop" "$relay" >/dev/null 2>&1) || rc=$?
assert_eq 3 "$rc" "no-progress exit code"
assert_eq 1 "$(cat "$TEST_ROOT/p3/calls")" "single call"

# 4. STOP file.
new_proj p4
touch "$TEST_ROOT/p4/.agents-fw/STOP"
(cd "$TEST_ROOT/p4" && AGENTS_FW_RELAY_CMD="$stub" "$relay" >/dev/null 2>&1)
assert_no_file "$TEST_ROOT/p4/calls"

# 5. --max reached -> exit 4.
new_proj p5
rc=0
(cd "$TEST_ROOT/p5" && AGENTS_FW_RELAY_CMD="$stub" "$relay" --max 2 >/dev/null 2>&1) || rc=$?
assert_eq 4 "$rc" "max exit code"
assert_eq 2 "$(cat "$TEST_ROOT/p5/calls")" "calls at max"

# 6. All master rows done -> nothing to run.
new_proj p6
sed -i.bak 's/in-progress/done/' "$TEST_ROOT/p6/specs/SPEC_MASTER.md"
(cd "$TEST_ROOT/p6" && AGENTS_FW_RELAY_CMD="$stub" "$relay" >/dev/null 2>&1)
assert_no_file "$TEST_ROOT/p6/calls"

# 7. Failing command -> exit 5.
new_proj p7
rc=0
(cd "$TEST_ROOT/p7" && AGENTS_FW_RELAY_CMD='cat >/dev/null; exit 7' "$relay" >/dev/null 2>&1) || rc=$?
assert_eq 5 "$rc" "failed command exit code"
