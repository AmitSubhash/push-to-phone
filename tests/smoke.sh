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
  && pass "URL -> Click+Actions headers" \
  || fail "URL -> Click+Actions headers" "$out"

echo "5) Dry-run with --tag composes Tags header"
out=$("$BIN" --dry-run --tag rocket,green_circle -m hi)
grep -q "Tags: rocket,green_circle" <<<"$out" \
  && pass "--tag -> Tags header" || fail "--tag -> Tags header" "$out"

echo "6) Dry-run with --at composes At header"
out=$("$BIN" --dry-run --at "tomorrow 9am" -m hi)
grep -q "At: tomorrow 9am" <<<"$out" \
  && pass "--at -> At header" || fail "--at -> At header" "$out"

echo "7) Dry-run with --markdown composes Markdown header"
out=$("$BIN" --dry-run --markdown -m "**hi**")
grep -q "Markdown: yes" <<<"$out" \
  && pass "--markdown -> Markdown header" || fail "--markdown -> Markdown header" "$out"

echo "8) Dry-run with --copy composes Actions: copy"
out=$("$BIN" --dry-run --copy "secret-123" -m "OTP")
grep -q "Actions: copy, Copy, secret-123" <<<"$out" \
  && pass "--copy -> Actions header" || fail "--copy -> Actions header" "$out"

echo "9) --token adds Authorization header"
out=$("$BIN" --dry-run --token "tk_abc" -m hi)
grep -q "Authorization: Bearer tk_abc" <<<"$out" \
  && pass "--token -> Authorization header" || fail "--token -> Authorization header" "$out"

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

echo "12) --batch + --attach is rejected"
set +e
out=$("$BIN" --batch --attach /tmp/nope 2>&1); rc=$?
set -e
[[ "$rc" -eq 2 && "$out" == *"cannot be combined"* ]] \
  && pass "batch+attach conflict rejected" \
  || fail "batch+attach conflict rejected" "rc=$rc out=$out"

echo "13) Newline in title is sanitized (no CR/LF in dry-run headers)"
out=$("$BIN" --dry-run -t $'Evil\r\nInjected: header' https://example.com)
# The dry-run prints header lines; they should NOT contain CR or a stray 'Injected:' as a separate header
if grep -q $'\r' <<<"$out"; then fail "newline sanitize" "CR leaked through"
elif grep -qE '^  header: Injected:' <<<"$out"; then fail "newline sanitize" "LF split into extra header"
else pass "CRLF stripped from title"
fi

echo "14a) Multi-line message body passes through without config-parser error"
# Uses the curl-spy to confirm: (a) a data-binary @file arg is present,
# (b) the contents of that file exactly match our multi-line message.
spydir=$(mktemp -d -t spy2.XXXXXX)
cat > "$spydir/curl" <<'SPY'
#!/usr/bin/env bash
# Accept -K <cfg> -o <out> -w <fmt> ; echo 200 on stdout, pass.
cfg_arg=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -K) cfg_arg="$2"; shift 2 ;;
    -o) : > "$2"; shift 2 ;;
    *)  shift ;;
  esac
done
cp "$cfg_arg" "$SPY_CFG_OUT"
# Find data-binary @file and copy its contents
datafile=$(sed -n 's/^data-binary = "@\(.*\)"$/\1/p' "$cfg_arg" | head -1)
[[ -f "$datafile" ]] && cp "$datafile" "$SPY_DATA_OUT"
echo "200"
SPY
chmod +x "$spydir/curl"
export SPY_CFG_OUT="$spydir/cfg.txt"
export SPY_DATA_OUT="$spydir/data.txt"
msg=$'alpha\nbeta with "quotes"\ngamma'
PATH="$spydir:$PATH" "$BIN" -t "multiline" -m "$msg" >/dev/null || true
data_got=$(cat "$SPY_DATA_OUT" 2>/dev/null || echo "")
if [[ "$data_got" == "$msg" ]]; then
  pass "multi-line body round-trips byte-exact"
else
  fail "multi-line body round-trips byte-exact" "expected=$msg got=$data_got"
fi
rm -rf "$spydir"; unset SPY_CFG_OUT SPY_DATA_OUT

echo "14) Topic does not appear in curl argv (no argv leak on send)"
# With the refactor, curl runs as:  curl -K <config> -o <out> -w <fmt>
# Topic lives inside the config file, not on argv. We spy by wrapping curl.
spydir=$(mktemp -d -t spy.XXXXXX)
cat > "$spydir/curl" <<'SPY'
#!/usr/bin/env bash
# Record our argv so the test can inspect it
printf '%s\n' "$@" > "$SPY_ARGV_OUT"
# Succeed with a fake 200 response
: > "${2:-/dev/null}"   # -o <file>, keep output empty
echo "200"
SPY
chmod +x "$spydir/curl"
export NTFY_TOPIC="leak-canary-abc123"
export SPY_ARGV_OUT="$spydir/argv.txt"
PATH="$spydir:$PATH" "$BIN" -t "t" -m "msg" https://example.com >/dev/null || true
argv=$(cat "$SPY_ARGV_OUT" 2>/dev/null || echo "")
if grep -q "leak-canary-abc123" <<<"$argv"; then
  fail "topic leak via argv" "argv: $argv"
else
  pass "topic not in argv"
fi
rm -rf "$spydir"
unset SPY_ARGV_OUT
export NTFY_TOPIC="test-topic"

echo
if (( fail == 0 )); then
  echo "ALL SMOKE TESTS PASSED"
else
  echo "$fail TEST(S) FAILED"
  exit 1
fi
