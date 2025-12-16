# Default recipe
default: test

# === CI Commands ===

# Run all CI checks (use before PR)
ci: check test size-check
    @echo "✓ All CI checks passed"

# Type check
check:
    moon check --target js

# Check bundle sizes are within limits
size-check:
    #!/usr/bin/env bash
    set -e
    LOADER_SIZE=$(wc -c < js/loader/src/loader.js)
    echo "loader.js: ${LOADER_SIZE} bytes"
    if [ "$LOADER_SIZE" -gt 5120 ]; then
        echo "❌ loader.js exceeds 5KB limit"
        exit 1
    fi
    echo "✓ Bundle sizes OK"

# === Test Commands ===

# Run all tests
test: test-moonbit test-xplat test-vitest test-browser test-e2e test-examples
    @echo "✓ All tests passed"

test-examples:
    moon info
    moon build -C examples/sol_app

# Run MoonBit unit tests
test-moonbit:
    moon test --target js
    moon test --target all src/core/signal

# Run cross-platform tests (core modules on all targets: js, wasm-gc, native)
test-xplat:
    moon test --target all src/core/signal
    moon test --target all src/core/routes
    moon test --target all src/core/render
    moon test --target all src/core/serialize

# Run vitest tests
test-vitest: build-moon
    pnpm vitest run

# Run browser tests
test-browser: build-moon
    pnpm vitest run --config vitest.browser.config.ts

# Run E2E tests (playwright)
test-e2e: build-moon
    pnpm playwright test --config e2e/playwright.config.mts

# Run E2E tests with UI
test-e2e-ui: build-moon
    pnpm playwright test --config e2e/playwright.config.mts --ui

# Run E2E coverage tests
test-e2e-coverage: build-moon
    pnpm playwright test --config e2e/playwright.config.mts e2e/browser-app/coverage.test.ts

# Run sol new template test
test-sol-new: build-moon
    node scripts/test-sol-new.ts

# === Build Commands ===

# Build MoonBit only
build-moon:
    moon build --target js

# Build loader with rolldown
build-loader:
    pnpm exec rolldown -c rolldown.config.mjs

# Build all (MoonBit + loader + Vite)
build: build-moon build-loader
    pnpm vite build

# Clean build artifacts
clean:
    moon clean
    rm -rf target

# Format code
fmt:
    moon fmt

# === Utility Commands ===

# Show bundle sizes
size:
    @echo "=== Bundle Sizes ==="
    @ls -lh js/loader/*.js 2>/dev/null | awk '{print $9 ": " $5}'
    @echo ""
    @echo "=== MoonBit Output Sizes ==="
    @find target/js/release/build -name "*.js" -exec ls -lh {} \; 2>/dev/null | awk '{print $9 ": " $5}' | head -20

# Run benchmarks
bench:
    node bench/run.js

# Run benchmarks with happydom
bench-happydom:
    node bench/run-happydom.js

# === Metrics Commands ===

# Build, collect metrics, and show trend
metrics:
    node scripts/metrics.ts

# Show metrics trend only (no build)
metrics-show:
    node scripts/metrics.ts show

# Watch and rebuild
watch:
    moon build --target js --watch

[parallel]
dev: watch

# === Sol CLI Commands ===

# Run sol CLI
sol *args:
    node target/js/release/build/sol/cli/cli.js {{args}}

# Create new sol project
sol-new name:
    node target/js/release/build/sol/cli/cli.js new {{name}}

# === Coverage Commands ===

# Build MoonBit with debug info (generates source maps)
build-debug:
    moon build --target js -g

# Run MoonBit tests with coverage
coverage-moonbit:
    rm -f target/moonbit_coverage_*.txt
    moon test --target js --enable-coverage
    moon coverage report -f cobertura -o coverage/moonbit-coverage.xml
    moon coverage report -f summary

# Run vitest with V8 coverage (uses debug build for source maps)
coverage-vitest: build-debug
    pnpm vitest run --coverage --coverage.provider=v8 --coverage.reporter=json --coverage.reportsDirectory=coverage/vitest

# Run E2E tests with V8 coverage (uses debug build for source maps)
coverage-e2e: build-debug
    rm -rf coverage/e2e-v8
    pnpm playwright test --config e2e/playwright.config.mts e2e/browser-app/coverage.test.mts

# Generate coverage report (uses source maps to map JS -> .mbt)
coverage-report:
    node scripts/coverage.ts

# Generate HTML coverage report
coverage-html:
    node scripts/coverage.ts html

# Run all tests with coverage and generate report
coverage: coverage-moonbit coverage-vitest coverage-e2e coverage-report
    @echo "✓ Coverage reports generated in coverage/"

# Clean coverage data
coverage-clean:
    rm -rf coverage/
    moon coverage clean

