#!/usr/bin/env bash
set -eu

TEST_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd -P)
ROOT=$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)
# shellcheck source=tests/lib.sh
. "$TEST_DIR/lib.sh"
new_project

project="$TEST_ROOT/project"
mkdir -p "$project/src"
cat >"$project/ARCHITECTURE.md" <<'EOF'
<!--
## Declared folders
- `missing-comment/`
| `src/commented.ts` | fake | ignored |
-->
## Declared folders
- `src/`

## Reuse registry
| Path | Kind | Purpose |
|---|---|---|
| `src/` | module | reusable source |
EOF
printf 'module\n' >"$project/src/module.ts"
mkdir -p "$project/src/tests" "$project/src/__tests__"
printf 'ignored\n' >"$project/src/tests/helper.ts"
printf 'ignored\n' >"$project/src/__tests__/module.test.ts"
printf 'ignored\n' >"$project/src/.gitkeep"
printf 'ignored\n' >"$project/src/__init__.py"
(cd "$project" && "$ROOT/framework/scripts/arch-check.sh")

printf 'unregistered\n' >"$project/src/public.d.ts"
cat >"$project/ARCHITECTURE.md" <<'EOF'
## Declared folders
- `src/`

## Reuse registry
| Path | Kind | Purpose |
|---|---|---|
| `src/module.ts` | module | reusable source |
EOF
if (cd "$project" && "$ROOT/framework/scripts/arch-check.sh") >"$TEST_ROOT/unregistered.out" 2>&1; then
  fail "arch-check accepted an unregistered declaration file"
fi
assert_file_contains "$TEST_ROOT/unregistered.out" 'src/public.d.ts'
rm "$project/src/public.d.ts"

cat >"$project/ARCHITECTURE.md" <<'EOF'
## Declared folders
- `src/`

## Reuse registry
| Path | Kind | Purpose |
|---|---|---|
| `src/gone.ts` | helper | missing |
EOF
if (cd "$project" && "$ROOT/framework/scripts/arch-check.sh") >"$TEST_ROOT/missing-registry.out" 2>&1; then
  fail "arch-check accepted a missing registry path"
fi
assert_file_contains "$TEST_ROOT/missing-registry.out" 'src/gone.ts'

cat >"$project/ARCHITECTURE.md" <<'EOF'
## Declared folders
- `missing/`

## Reuse registry
| Path | Kind | Purpose |
|---|---|---|
EOF
if (cd "$project" && "$ROOT/framework/scripts/arch-check.sh") >"$TEST_ROOT/missing-folder.out" 2>&1; then
  fail "arch-check accepted a missing declared folder"
fi
assert_file_contains "$TEST_ROOT/missing-folder.out" 'missing/'

printf 'not a test\n' >"$project/src/other.ts"
cat >"$project/ARCHITECTURE.md" <<'EOF'
## Declared folders
- `src/`

## Reuse registry
| Path | Kind | Purpose |
|---|---|---|
EOF
if (cd "$project" && "$ROOT/framework/scripts/arch-check.sh") >"$TEST_ROOT/uncovered.out" 2>&1; then
  fail "arch-check accepted an uncovered source file"
fi
assert_file_contains "$TEST_ROOT/uncovered.out" 'src/module.ts'
