#!/usr/bin/env bash
set -eu

TEST_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd -P)
ROOT=$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)
# shellcheck source=tests/lib.sh
. "$TEST_DIR/lib.sh"
new_project

project="$TEST_ROOT/repo"
mkdir -p "$project/specs" "$project/tests"
git_init "$project"
printf 'test source\n' >"$project/tests/example.test.sh"
git -C "$project" add tests/example.test.sh
git -C "$project" commit -qm 'Add locked test'
locked_at=$(git -C "$project" rev-parse HEAD)

cat >"$project/specs/valid.md" <<EOF
---
locked_at: $locked_at
locked_tests:
  - tests/example.test.sh
---
Body
EOF
(cd "$project" && "$ROOT/framework/scripts/test-lock.sh" specs/valid.md)

cat >"$project/specs/empty.md" <<'EOF'
---
locked_tests: []
---
EOF
out=$(cd "$project" && "$ROOT/framework/scripts/test-lock.sh" specs/empty.md)
assert_contains "$out" 'no locked tests'

printf 'changed\n' >>"$project/tests/example.test.sh"
if (cd "$project" && "$ROOT/framework/scripts/test-lock.sh" specs/valid.md) >"$TEST_ROOT/changed.out" 2>&1; then
  fail "test-lock accepted a changed locked test"
fi
assert_file_contains "$TEST_ROOT/changed.out" 'tests/example.test.sh'
printf 'test source\n' >"$project/tests/example.test.sh"
printf 'staged change\n' >"$project/tests/example.test.sh"
git -C "$project" add tests/example.test.sh
if (cd "$project" && "$ROOT/framework/scripts/test-lock.sh" specs/valid.md) >/dev/null 2>&1; then
  fail "test-lock accepted a staged locked-test change"
fi
printf 'committed change\n' >"$project/tests/example.test.sh"
git -C "$project" add tests/example.test.sh
git -C "$project" commit -qm 'Restore locked test'
if (cd "$project" && "$ROOT/framework/scripts/test-lock.sh" specs/valid.md) >/dev/null 2>&1; then
  fail "test-lock accepted a committed locked-test change"
fi

cat >"$project/specs/no-frontmatter.md" <<'EOF'
No metadata
EOF
if (cd "$project" && "$ROOT/framework/scripts/test-lock.sh" specs/no-frontmatter.md) >"$TEST_ROOT/no-frontmatter.out" 2>&1; then
  fail "test-lock accepted missing front matter"
fi
assert_file_contains "$TEST_ROOT/no-frontmatter.out" 'locked_tests'

cat >"$project/specs/no-key.md" <<EOF
---
locked_at: $locked_at
---
EOF
if (cd "$project" && "$ROOT/framework/scripts/test-lock.sh" specs/no-key.md) >/dev/null 2>&1; then
  fail "test-lock accepted a missing locked_tests key"
fi

cat >"$project/specs/no-lock.md" <<'EOF'
---
locked_at:
locked_tests:
  - tests/example.test.sh
---
EOF
if (cd "$project" && "$ROOT/framework/scripts/test-lock.sh" specs/no-lock.md) >/dev/null 2>&1; then
  fail "test-lock accepted an empty locked_at"
fi

cat >"$project/specs/invalid-lock.md" <<'EOF'
---
locked_at: not-a-commit
locked_tests:
  - tests/example.test.sh
---
EOF
if (cd "$project" && "$ROOT/framework/scripts/test-lock.sh" specs/invalid-lock.md) >/dev/null 2>&1; then
  fail "test-lock accepted a non-commit locked_at"
fi

cat >"$project/specs/missing-working-tree.md" <<EOF
---
locked_at: $locked_at
locked_tests:
  - tests/missing.test.sh
---
EOF
if (cd "$project" && "$ROOT/framework/scripts/test-lock.sh" specs/missing-working-tree.md) >"$TEST_ROOT/missing-working.out" 2>&1; then
  fail "test-lock accepted a test missing from the working tree"
fi
assert_file_contains "$TEST_ROOT/missing-working.out" 'tests/missing.test.sh'

printf 'added after lock\n' >"$project/tests/added.test.sh"
cat >"$project/specs/missing-at-lock.md" <<EOF
---
locked_at: $locked_at
locked_tests:
  - tests/added.test.sh
---
EOF
if (cd "$project" && "$ROOT/framework/scripts/test-lock.sh" specs/missing-at-lock.md) >"$TEST_ROOT/missing-lock.out" 2>&1; then
  fail "test-lock accepted a path absent at locked_at"
fi
assert_file_contains "$TEST_ROOT/missing-lock.out" 'tests/added.test.sh'
