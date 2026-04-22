#!/usr/bin/env bash
# Smoke tests for push-to-phone.
# Uses --dry-run so no real notifications go out, and asserts the
# script composes the right headers and exit codes.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HERE/../bin/push-to-phone"
fail=0

pass() { printf "  ok  %s\n" "$1"; }
fail() { printf "  FAIL %s\n    %s\n" "$1" "$2"; fail=$((fail+1)); }

# Isolate from any real config / env
export PUSH_TO_PHONE_CONFIG="/nonexistent"
unset NTFY_TOPIC NTFY_TOKEN NTFY_SERVER NTFY_PRIORITY

echo "1) Fails clearly when NTFY_TOPIC is unset"
out=$("$BIN" https://example.com 2>&1 || true)
grep -q "NTFY_TOPIC is not set" <<<"$out" && pass "shows the missing-topic error" \
  || fail "shows missing-topic error" "got: $out"

echo "2) --help exits 0 and shows usage"
"$BIN" --help | grep -q "push-to-phone:" && pass "--help works" || fail "--help works" "did not print usage"

echo "3) --version prints version"
"$BIN" --version | grep -qE '^push-to-phone [0-9]+\.[0-9]+\.[0-9]+$' \
  && pass "--version works" || fail "--version works" "unexpected output"

export NTFY_TOPIC="test-topic"

echo "4) Dry-run single URL composes Click + view action"
out=$("$BIN" --dry-run -t "title" https://example.com)
grep -q "Click: https://example.com" <<<"$out" && grep -q "Actions: view," <<<"$out" \
  && pass "URL → Click+Actions headers" \
  || fail "URL → Click+Actions headers" "$out"

echo "5) Dry-run with --tag composes Tags header"
out=$("$BIN" --dry-run --tag rocket,green_circle -m hi)
grep -q "Tags: rocket,green_circle" <<<"$out" \
  && pass "--tag → Tags header" || fail "--tag → Tags header" "$out"

echo "6) Dry-run with --at composes At header"
out=$("$BIN" --dry-run --at "tomorrow 9am" -m hi)
grep -q "At: tomorrow 9am" <<<"$out" \
  && pass "--at → At header" || fail "--at → At header" "$out"

echo "7) Dry-run with --markdown composes Markdown header"
out=$("$BIN" --dry-run --markdown -m "**hi**")
grep -q "Markdown: yes" <<<"$out" \
  && pass "--markdown → Markdown header" || fail "--markdown → Markdown header" "$out"

echo "8) Dry-run with --copy composes Actions: copy"
out=$("$BIN" --dry-run --copy "secret-123" -m "OTP")
grep -q "Actions: copy, Copy, secret-123" <<<"$out" \
  && pass "--copy → Actions header" || fail "--copy → Actions header" "$out"

echo "9) --token adds Authorization header"
out=$("$BIN" --dry-run --token "tk_abc" -m hi)
grep -q "Authorization: Bearer tk_abc" <<<"$out" \
  && pass "--token → Authorization header" || fail "--token → Authorization header" "$out"

echo "10) wrap runs a successful command and returns its exit code"
export NTFY_TOPIC="test-topic"
set +e
out=$("$BIN" wrap -- true 2>&1); rc=$?
set -e
(( rc == 0 )) && pass "wrap: true exits 0" || fail "wrap: true exits 0" "rc=$rc"

echo "11) wrap forwards non-zero exit"
set +e
out=$("$BIN" wrap -- bash -c 'exit 7' 2>&1); rc=$?
set -e
(( rc == 7 )) && pass "wrap: exit 7 propagates" || fail "wrap: exit 7 propagates" "rc=$rc"

echo
if (( fail == 0 )); then
  echo "ALL SMOKE TESTS PASSED"
else
  echo "$fail TEST(S) FAILED"
  exit 1
fi
