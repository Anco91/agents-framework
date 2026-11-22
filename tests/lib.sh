#!/usr/bin/env bash
set -eu

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_eq() {
  expected=$1
  actual=$2
  message=${3:-values differ}
  [ "$expected" = "$actual" ] || fail "$message (expected '$expected', got '$actual')"
}

assert_file() {
  [ -f "$1" ] || fail "expected file: $1"
}

assert_no_file() {
  [ ! -e "$1" ] || fail "unexpected file: $1"
}

assert_contains() {
  text=$1
  needle=$2
  case "$text" in
    *"$needle"*) ;;
    *) fail "expected '$text' to contain '$needle'" ;;
  esac
}

assert_file_contains() {
  file=$1
  needle=$2
  if ! grep -F "$needle" "$file" >/dev/null 2>&1; then
    fail "expected $file to contain '$needle'"
  fi
}

new_project() {
  TEST_ROOT=$(mktemp -d)
  trap 'rm -rf "$TEST_ROOT"' EXIT
}

git_init() {
  repo=$1
  git -C "$repo" init -q
  git -C "$repo" config user.name "Test User"
  git -C "$repo" config user.email "test@example.com"
}
