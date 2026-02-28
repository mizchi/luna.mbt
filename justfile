# Luna UI Framework - Task Runner
#
# Default: incremental test (turbo cache enabled)
# Usage: just --list

default: test-incremental

# =============================================================================
# Daily Development
# =============================================================================

# Incremental test (skip already-cached tasks)
test-incremental:
    pnpm turbo run test:moonbit test:vitest

check:
    moon check --target js

fmt:
    moon fmt

watch:
    moon build --target js --watch

clean:
    moon clean
    rm -rf _build target coverage .turbo/cache

# Force test (ignore cache)
retest *tasks="test:moonbit test:vitest":
    pnpm turbo run {{tasks}} --force

# =============================================================================
# Build
# =============================================================================

# MoonBit debug build (with source maps)
build-debug:
    moon build --target js -g src
    moon build --target js -g src/js/api
    moon build --target js -g src/js/api_signals

build-moon:
    moon build --target js --release src
    moon build --target js --release src/js/api
    moon build --target js --release src/js/api_signals
    @rm -f _build/js/release/build/package.json

build-loader:
    pnpm turbo run @luna_ui/luna-loader#build

# Full build (via turbo)
build:
    pnpm turbo run build
    pnpm vite build

# =============================================================================
# Test (individual runners - called from turbo)
# =============================================================================

test-moonbit: _setup-test-env
    moon test --target js

test-vitest:
    pnpm vitest run --project node --project browser

test-e2e:
    pnpm playwright test --config e2e/playwright.config.mts

# E2E test (UI mode)
test-e2e-ui:
    pnpm playwright test --config e2e/playwright.config.mts --ui

# Cross-platform test (js, wasm-gc, native)
test-xplat:
    moon test --target all src/core/routes
    moon test --target all src/core/render
    moon test --target all src/core/serialize

# CommonJS environment setup for moon test
_setup-test-env:
    @mkdir -p _build/js/debug/test
    @echo '{"type": "commonjs"}' > _build/js/debug/test/package.json

# =============================================================================
# CI
# =============================================================================

ci: check test-incremental size-check
    @echo "✓ All CI checks passed"

# Bundle size check (loader.js must be < 5KB)
size-check:
    #!/usr/bin/env bash
    set -e
    LOADER_SIZE=$(wc -c < js/loader/dist/loader.js)
    echo "loader.js: ${LOADER_SIZE} bytes"
    [ "$LOADER_SIZE" -le 5120 ] || { echo "❌ Exceeds 5KB limit"; exit 1; }
    echo "✓ Bundle sizes OK"

size:
    @echo "=== Bundle Sizes ==="
    @ls -lh js/loader/dist/*.js 2>/dev/null | awk '{print $9 ": " $5}'
    @echo ""
    @echo "=== MoonBit Output ==="
    @find _build/js/release/build -name "*.js" -exec ls -lh {} \; 2>/dev/null | awk '{print $9 ": " $5}' | head -20

treeshake-size:
    node scripts/treeshake-size.mjs --build

# Update treeshake baseline
treeshake-baseline:
    node scripts/treeshake-size.mjs --build --write-baseline

# Diff check against treeshake baseline
treeshake-check:
    node scripts/treeshake-size.mjs --build --check

# =============================================================================
# Coverage
# =============================================================================

coverage: coverage-moonbit coverage-vitest coverage-e2e
    node scripts/coverage.ts
    @echo "✓ Coverage reports in coverage/"

coverage-moonbit:
    rm -f _build/moonbit_coverage_*.txt
    moon test --target js --enable-coverage
    moon coverage report -f cobertura -o coverage/moonbit-coverage.xml
    moon coverage report -f summary

coverage-vitest:
    @just build-debug
    pnpm vitest run --coverage --coverage.provider=v8 --coverage.reporter=json --coverage.reportsDirectory=coverage/vitest

coverage-e2e:
    @just build-debug
    rm -rf coverage/e2e-v8
    pnpm playwright test --config e2e/playwright.config.mts e2e/browser/coverage.test.mts

coverage-clean:
    rm -rf coverage/
    moon coverage clean

# =============================================================================
# CSS Utilities
# =============================================================================

luna *args:
    node js/luna/dist/cli.mjs {{args}}

extract-css dir="src" *flags:
    just luna css extract {{dir}} --pretty {{flags}}

minify-css input *flags:
    just luna css minify {{input}} {{flags}}

inject-css html src *flags:
    just luna css inject {{html}} --src {{src}} {{flags}}

bench-css scale="all":
    node src/x/css/benchmark.js --scale {{scale}}

# =============================================================================
# Release
# =============================================================================

# Regenerate CHANGELOG (full history, use on release)
changelog tag:
    git cliff --tag {{tag}} -o CHANGELOG.md

# CHANGELOG preview (unreleased only)
changelog-preview:
    git cliff --unreleased

# Version bump (patch/minor/major or explicit version)
# Usage: just vup patch, just vup 0.4.0, just vup minor --dry-run
vup version *args:
    #!/usr/bin/env bash
    set -e
    # Update version
    node scripts/vup.mjs {{version}} {{args}}
    # Update changelog unless dry-run
    if [[ ! " {{args}} " =~ " --dry-run " ]]; then
        # Get updated version
        NEW_VERSION=$(node -p "require('./moon.mod.json').version")
        echo ""
        echo "Updating CHANGELOG.md..."
        git cliff --tag "v${NEW_VERSION}" -o CHANGELOG.md 2>/dev/null
        echo "  CHANGELOG.md updated for v${NEW_VERSION}"
    fi

metrics *args:
    node scripts/metrics.ts {{args}}
