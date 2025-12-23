#!/bin/bash
# Setup script for sol-app E2E test
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$ROOT_DIR/examples/sol_app"
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

# Run sol generate with dev mode
echo "Running sol generate --mode dev..."
node "$CLI_PATH" generate --mode dev

# Patch __gen__/server files to include Server Action support
echo "Patching Server Action support..."
cat > app/__gen__/server/moon.pkg.json << 'MOON_PKG_EOF'
{
  "supported-targets": ["js"],
  "is-main": true,
  "import": [
    { "path": "mizchi/luna/sol", "alias": "sol" },
    { "path": "mizchi/luna/sol/router", "alias": "router" },
    { "path": "mizchi/luna/sol/action", "alias": "action" },
    { "path": "mizchi/js/core", "alias": "core" },
    { "path": "example/sol-app/server", "alias": "app_server" }
  ],
  "link": {
    "js": {
      "exports": ["configure_app"],
      "format": "esm"
    }
  },
  "warn-list": "-29"
}
MOON_PKG_EOF

cat > app/__gen__/server/main.mbt << 'MAIN_MBT_EOF'
///| Server entry point with Server Action support

pub fn configure_app(app : @sol.App) -> @sol.App {
  let routes = @app_server.routes()
  let config = @app_server.config()
  let app = @router.register_sol_routes(app, routes, config=config)

  // Register Server Actions
  let registry = @app_server.action_registry()
  let app = @action.register_actions(app, registry)

  @sol.serve_static(app)
}

fn main {
  @sol.run(configure_app)
}
MAIN_MBT_EOF

# Build MoonBit
echo "Building MoonBit..."
moon build --target js

# Bundle with rolldown using manifest.json
echo "Bundling with rolldown..."
node --input-type=module -e "
import { readFileSync } from 'node:fs';
import { build } from 'rolldown';
const manifest = JSON.parse(readFileSync('.sol/dev/manifest.json', 'utf-8'));
const input = {};
for (const island of manifest.islands) { input[island.name] = island.entry_path; }
await build({ input, output: { dir: manifest.output_dir, format: 'esm', entryFileNames: '[name].js', chunkFileNames: '_shared/[name]-[hash].js' } });
"

# Start server
echo "Starting server on port $PORT..."
export PORT="$PORT"
exec node .sol/dev/server/main.js
