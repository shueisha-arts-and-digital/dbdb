#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")/.."

types=(mysql postgresql mongodb redis memcached)
commands=(create create-start start stop restart port status connect delete)
failures=0

fail() {
  echo "FAIL: $1" 1>&2
  failures=$((failures + 1))
}

echo "# Test dbdb.sh --help"
./dbdb.sh --help | grep -q "^Usage:" || fail "dbdb.sh --help"

for type in "${types[@]}"; do
  for command in "${commands[@]}"; do
    script="./$type/$command.sh"
    echo "# Test $script --help"
    "$script" --help | grep -q "^Usage: $script" || fail "$script --help"
    "$script" -h | grep -q "^Usage: $script" || fail "$script -h"

    echo "# Test $script without arguments"
    if "$script" >/dev/null 2>&1; then
      fail "$script without arguments should exit non-zero"
    fi
    "$script" 2>&1 >/dev/null | grep -q "^Usage: $script" || fail "$script without arguments should print usage to stderr"
  done
done

if [ "$failures" -gt 0 ]; then
  echo "$failures failure(s)" 1>&2
  exit 1
fi
echo "All help tests passed."
