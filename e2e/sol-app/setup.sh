#!/bin/bash
# Setup script for sol-app E2E test
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$ROOT_DIR/examples/sol-app"
CLI_PATH="$ROOT_DIR/target/js/release/build/sol/cli/cli.js"
PORT="${PORT:-3457}"

echo "=== Sol App E2E Setup ==="
echo "ROOT_DIR: $ROOT_DIR"
echo "APP_DIR: $APP_DIR"
echo "PORT: $PORT"

# Build CLI first
echo "Building sol CLI..."
cd "$ROOT_DIR"
moon build --target js

# Setup example project
cd "$APP_DIR"

# Install dependencies
echo "Installing npm dependencies..."
npm install --silent

echo "Installing moon dependencies..."
moon install

# Run sol generate
echo "Running sol generate..."
node "$CLI_PATH" generate

# Build MoonBit
echo "Building MoonBit..."
moon build --target js

# Bundle with rolldown
echo "Bundling with rolldown..."
npx rolldown -c rolldown.config.mjs

# Start server
echo "Starting server on port $PORT..."
export PORT="$PORT"
exec node target/js/release/build/server/run/run.js
