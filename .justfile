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
    LOADER_SIZE=$(wc -c < packages/loader/ln-loader-v1.js)
    LOADER_MIN_SIZE=$(wc -c < packages/loader/loader.min.js)
    echo "ln-loader-v1.js: ${LOADER_SIZE} bytes"
    echo "loader.min.js: ${LOADER_MIN_SIZE} bytes"
    if [ "$LOADER_SIZE" -gt 5120 ]; then
        echo "❌ ln-loader-v1.js exceeds 5KB limit"
        exit 1
    fi
    if [ "$LOADER_MIN_SIZE" -gt 1024 ]; then
        echo "❌ loader.min.js exceeds 1KB limit"
        exit 1
    fi
    echo "✓ Bundle sizes OK"

# === Test Commands ===

# Run all tests
test: test-moonbit test-xplat test-vitest test-browser test-e2e
    @echo "✓ All tests passed"

# Run MoonBit unit tests
test-moonbit:
    moon test --target js
    moon test --target all src/core/signal

# Run cross-platform tests (core modules on all targets: js, wasm-gc, native)
test-xplat:
    moon test --target all src/core/signal
    moon test --target all src/core/routes
    moon test --target all src/core/render

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

# Build all (MoonBit + Vite)
build: build-moon
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
    @ls -lh packages/loader/*.js 2>/dev/null | awk '{print $9 ": " $5}'
    @echo ""
    @echo "=== MoonBit Output Sizes ==="
    @find target/js/release/build -name "*.js" -exec ls -lh {} \; 2>/dev/null | awk '{print $9 ": " $5}' | head -20

# Minify loader
minify-loader:
    pnpm terser packages/loader/loader.js --module --compress --mangle -o packages/loader/loader.min.js

# Run benchmarks
bench:
    node bench/run.js

# Run benchmarks with happydom
bench-happydom:
    node bench/run-happydom.js

# === Metrics Commands ===

# Record build metrics (time + sizes)
metrics-record:
    node scripts/metrics.ts record

# Record with clean build
metrics-record-clean:
    node scripts/metrics.ts record --clean

# Record with benchmarks
metrics-record-bench:
    node scripts/metrics.ts record --bench

# Record full (clean build + benchmarks)
metrics-record-full:
    node scripts/metrics.ts record --clean --bench

# Show recent metrics
metrics-report *n:
    node scripts/metrics.ts report {{n}}

# Compare with previous build
metrics-compare *hash:
    node scripts/metrics.ts compare {{hash}}

# Show trend graph
metrics-trend *metric:
    node scripts/metrics.ts trend {{metric}}

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

