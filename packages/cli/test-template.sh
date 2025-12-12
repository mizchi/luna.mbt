#!/bin/bash
# Test script for CLI template generation and E2E testing
# This script:
# 1. Generates a new app from templates using CLI
# 2. Builds the MoonBit code
# 3. Bundles the client JS
# 4. Starts the server (kept running for E2E tests)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="$SCRIPT_DIR/tmp"
TEST_APP="$TMP_DIR/kaguya-test-app"

echo "=== Kaguya Template App Test ==="
echo "Script dir: $SCRIPT_DIR"
echo "Root dir: $ROOT_DIR"
echo "Test app: $TEST_APP"

# Kill any existing server on port 3000
lsof -ti:3000 | xargs kill -9 2>/dev/null || true

# Clean up previous test app
rm -rf "$TEST_APP"
mkdir -p "$TMP_DIR"

# Build CLI if needed
if [ ! -f "$SCRIPT_DIR/dist/index.js" ]; then
  echo ""
  echo "=== Building CLI ==="
  cd "$SCRIPT_DIR"
  pnpm build
fi

# Generate test project
echo ""
echo "=== Generating test project ==="
cd "$SCRIPT_DIR"
node dist/index.js new "$TEST_APP"

# Navigate to test app
cd "$TEST_APP"

# Update moon dependencies
echo ""
echo "=== Updating moon dependencies ==="
moon update

# Build MoonBit code
echo ""
echo "=== Building MoonBit code ==="
moon build --target js

# Bundle client JS using rolldown directly (since moon build was already done)
echo ""
echo "=== Bundling client JS ==="
cd "$TEST_APP"
npx rolldown -c rolldown.config.mjs

# Copy loader to static directory
echo ""
echo "=== Copying loader to static ==="
cp "$ROOT_DIR/packages/loader/loader.js" "$TEST_APP/static/kg-loader-v1.js"

# Start server (will be kept running for E2E tests)
echo ""
echo "=== Starting server on port 3000 ==="
cd "$TEST_APP"
exec node target/js/release/build/server/run/run.js
