#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")/.."

types=(mysql postgresql mongodb redis memcached meilisearch)
commands=(create create-start start stop restart port status connect delete)
failures=0

fail() {
  echo "FAIL: $1" 1>&2
  failures=$((failures + 1))
}

# Pass when the command exits 0 and its stdout has a line starting with the expected usage.
expectHelp() {
  local expected=$1
  shift
  local output
  if ! output=$("$@"); then
    fail "$* should exit 0"
    return
  fi
  grep -q "^$expected" <<<"$output" || fail "$* should print '$expected'"
}

echo "# Test dbdb.sh --help"
expectHelp "Usage:" ./dbdb.sh --help

echo "# Test dbdb.sh --version"
expectHelp "$(cat VERSION)" ./dbdb.sh --version
expectHelp "$(cat VERSION)" ./dbdb.sh -v

for type in "${types[@]}"; do
  for command in "${commands[@]}"; do
    script="./$type/$command.sh"
    echo "# Test $script --help"
    expectHelp "Usage: $script" "$script" --help
    expectHelp "Usage: $script" "$script" -h

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
