#!/bin/bash
# E2E Protocol Test: Verify Native and JS servers return identical JSON responses
# Usage: ./bench/e2e_protocol_test.sh
set -euo pipefail

NATIVE_PORT=7800
JS_PORT=7801
NATIVE_BIN="_build/native/release/build/bench_native_api/bench_native_api.exe"
JS_BIN="_build/js/release/build/bench_js_api/bench_js_api.js"
PASS=0
FAIL=0

cleanup() {
  kill $NATIVE_PID $JS_PID 2>/dev/null || true
}
trap cleanup EXIT

# Build
echo "Building..."
moon build --target native src/bench_native_api --release 2>&1 | tail -1
moon build --target js src/bench_js_api --release 2>&1 | tail -1

# Kill any lingering processes
lsof -ti:$NATIVE_PORT 2>/dev/null | xargs kill -9 2>/dev/null || true
lsof -ti:$JS_PORT 2>/dev/null | xargs kill -9 2>/dev/null || true
sleep 1

# Start servers
$NATIVE_BIN &
NATIVE_PID=$!
node $JS_BIN &
JS_PID=$!
sleep 2

assert_body_identical() {
  local endpoint="$1"
  local native_body js_body
  native_body=$(curl -sf "http://localhost:$NATIVE_PORT$endpoint" 2>/dev/null) || native_body="__CURL_FAIL__"
  js_body=$(curl -sf "http://localhost:$JS_PORT$endpoint" 2>/dev/null) || js_body="__CURL_FAIL__"

  if [ "$native_body" = "__CURL_FAIL__" ] || [ "$js_body" = "__CURL_FAIL__" ]; then
    echo "FAIL $endpoint — request failed (native=$native_body, js=$js_body)"
    FAIL=$((FAIL + 1))
    return
  fi

  if [ "$native_body" = "$js_body" ]; then
    echo "PASS $endpoint — body identical"
    PASS=$((PASS + 1))
  else
    echo "FAIL $endpoint — body differs"
    echo "  Native: $native_body"
    echo "  JS:     $js_body"
    FAIL=$((FAIL + 1))
  fi
}

assert_status() {
  local method="$1" endpoint="$2" expected="$3"
  local native_status js_status
  native_status=$(curl -sf -X "$method" -o /dev/null -w "%{http_code}" "http://localhost:$NATIVE_PORT$endpoint" 2>/dev/null) || native_status=$(curl -s -X "$method" -o /dev/null -w "%{http_code}" "http://localhost:$NATIVE_PORT$endpoint")
  js_status=$(curl -sf -X "$method" -o /dev/null -w "%{http_code}" "http://localhost:$JS_PORT$endpoint" 2>/dev/null) || js_status=$(curl -s -X "$method" -o /dev/null -w "%{http_code}" "http://localhost:$JS_PORT$endpoint")

  if [ "$native_status" = "$expected" ] && [ "$js_status" = "$expected" ]; then
    echo "PASS $method $endpoint — both $expected"
    PASS=$((PASS + 1))
  else
    echo "FAIL $method $endpoint — expected $expected, got native=$native_status js=$js_status"
    FAIL=$((FAIL + 1))
  fi
}

assert_content_type() {
  local endpoint="$1" expected="$2"
  local native_ct js_ct
  native_ct=$(curl -sf -o /dev/null -w "%{content_type}" "http://localhost:$NATIVE_PORT$endpoint" 2>/dev/null) || native_ct="FAIL"
  js_ct=$(curl -sf -o /dev/null -w "%{content_type}" "http://localhost:$JS_PORT$endpoint" 2>/dev/null) || js_ct="FAIL"

  if echo "$native_ct" | grep -q "$expected" && echo "$js_ct" | grep -q "$expected"; then
    echo "PASS $endpoint — Content-Type contains $expected"
    PASS=$((PASS + 1))
  else
    echo "FAIL $endpoint — Content-Type: native=$native_ct js=$js_ct (expected $expected)"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "=== E2E Protocol Test ==="
echo ""

# JSON body identity
assert_body_identical "/api/health"
assert_body_identical "/api/items"
assert_body_identical "/api/echo/hello"
assert_body_identical "/api/echo/with%20space"
assert_body_identical "/api/echo/special-chars_123"

# Status codes
assert_status GET "/api/health" "200"
assert_status GET "/api/items" "200"
assert_status GET "/nonexistent" "404"

# Content-Type
assert_content_type "/api/health" "application/json"
assert_content_type "/api/items" "application/json"

# JSON validity (parse both)
echo ""
echo "--- JSON validity ---"
for endpoint in "/api/health" "/api/items" "/api/echo/test"; do
  native_valid=$(curl -sf "http://localhost:$NATIVE_PORT$endpoint" | python3 -c "import sys,json; json.load(sys.stdin); print('ok')" 2>/dev/null || echo "invalid")
  js_valid=$(curl -sf "http://localhost:$JS_PORT$endpoint" | python3 -c "import sys,json; json.load(sys.stdin); print('ok')" 2>/dev/null || echo "invalid")
  if [ "$native_valid" = "ok" ] && [ "$js_valid" = "ok" ]; then
    echo "PASS $endpoint — valid JSON on both"
    PASS=$((PASS + 1))
  else
    echo "FAIL $endpoint — JSON invalid (native=$native_valid js=$js_valid)"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
