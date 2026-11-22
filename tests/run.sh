#!/usr/bin/env bash
set -eu

TEST_DIR=$(CDPATH='' cd -- "$(dirname "$0")" && pwd -P)
failed=0

for test_file in "$TEST_DIR"/test_*.sh; do
  if bash "$test_file"; then
    printf 'PASS %s\n' "$(basename "$test_file")"
  else
    printf 'FAIL %s\n' "$(basename "$test_file")"
    failed=1
  fi
done

exit "$failed"
