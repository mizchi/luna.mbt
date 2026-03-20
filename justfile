# Sol SSR/SSG Framework - Task Runner
#
# Usage: just --list

default: check

# =============================================================================
# Daily Development
# =============================================================================

# Development environment setup
bootstrap:
    pnpm install
    moon update
    moon install

# Type check
check:
    moon check --target js

# Format
fmt:
    moon fmt

# Auto rebuild
watch:
    moon build --target js --watch

# Clean
clean:
    moon clean
    rm -rf _build target .turbo/cache

# Local verification (before PR)
verify: check test test-docs test-cli-golden build
    @echo "✓ Local verification passed"

# =============================================================================
# Build
# =============================================================================

# MoonBit build
build-moon:
    moon build --target js
    @rm -f _build/js/debug/build/package.json

# MoonBit debug build (with source maps)
build-debug:
    moon build --target js -g

# Full build
build:
    just build-moon

# =============================================================================
# Test
# =============================================================================

# MoonBit unit test
test: _setup-test-env
    moon test --target js

# CommonJS environment setup for moon test
_setup-test-env:
    @mkdir -p _build/js/debug/test
    @echo '{"type": "commonjs"}' > _build/js/debug/test/package.json

# SSG test
test-ssg: _setup-test-env
    moon test --target js src/ssg

# Cross-platform test (wasm, wasm-gc, native)
test-xplat:
    moon test --target wasm src/parser
    moon test --target wasm-gc src/parser
    moon test --target native src/parser

# E2E test
test-e2e:
    pnpm playwright test --config e2e/playwright.config.mts

# E2E test (UI mode)
test-e2e-ui:
    pnpm playwright test --config e2e/playwright.config.mts --ui

# sol_app E2E test
test-sol-app:
    cd examples/sol_app && pnpm test

# sol_app hydration E2E (Playwright — verifies island hydration works)
test-sol-app-hydration:
    pnpm playwright test --config e2e/playwright-sol-app.config.mts

# MoonBit Playwright E2E (requires sol_app server on :3457)
test-mbt-e2e:
    cd e2e/mbt_e2e && timeout 120 moon run src/ --target js

# Docs consistency test
test-docs:
    node --test docs/docs-index.test.js docs/docs-chapters.test.js docs/docs-build-paths.test.js docs/docs-ci.test.js

# CLI golden path E2E (new -> dev/build/deploy help)
test-cli-golden:
    node --test e2e/cli-golden-path.test.js e2e/luna-loader-sync.test.js e2e/template-check.test.js e2e/template-doc-check.test.js e2e/template-doc-serve.test.js

# Code generation E2E (sol generate output verification)
test-generate:
    node --test e2e/generate-codegen.test.js

test-all: test test-ssg test-xplat test-docs test-cli-golden test-generate test-e2e test-sol-app

# =============================================================================
# CLI
# =============================================================================

# Sol CLI
sol *args:
    @just build-moon
    node _build/js/debug/build/cli/cli.js {{args}}

# =============================================================================
# Examples
# =============================================================================

# Sync core/runtime assets from luna loader dist (loader only when security requirements are met)
sync-luna-assets luna_dir="../luna.mbt":
    node scripts/sync-luna-loader-assets.mjs --luna-dir {{luna_dir}}

# Verify luna sync state (check only, no updates)
check-luna-assets luna_dir="../luna.mbt":
    node scripts/sync-luna-loader-assets.mjs --luna-dir {{luna_dir}} --check

# sol_app dev server (with framework hot reload)
dev-app:
    just build-moon
    cd examples/sol_app && node ../../_build/js/debug/build/cli/cli.js dev -f

# Clean example caches
clean-examples:
    @rm -rf examples/sol_app/.mooncakes examples/sol_app/_build
    @rm -rf examples/sol_auth/.mooncakes examples/sol_auth/_build
    @rm -rf examples/sol_blog/.mooncakes examples/sol_blog/_build
    @rm -rf examples/sol_docs/.mooncakes examples/sol_docs/_build
    @rm -rf examples/sol_sqlite/.mooncakes examples/sol_sqlite/_build
    @rm -rf examples/sol_api/.mooncakes examples/sol_api/_build
    @rm -rf examples/sol_todo/.mooncakes examples/sol_todo/_build
    @echo "✓ Examples cache cleaned"

# Build check for each example
check-example-sol-app:
    @echo "=== Checking sol_app ==="
    @rm -rf examples/sol_app/.mooncakes examples/sol_app/_build
    cd examples/sol_app && moon check --target js

check-example-sol-auth:
    @echo "=== Checking sol_auth ==="
    @rm -rf examples/sol_auth/.mooncakes examples/sol_auth/_build
    cd examples/sol_auth && moon check --target js

check-example-sol-blog:
    @echo "=== Checking sol_blog ==="
    @rm -rf examples/sol_blog/.mooncakes examples/sol_blog/_build
    cd examples/sol_blog && moon check --target js

check-example-sol-docs:
    @echo "=== Checking sol_docs ==="
    @rm -rf examples/sol_docs/.mooncakes examples/sol_docs/_build
    cd examples/sol_docs && moon check --target js

check-example-sol-sqlite:
    @echo "=== Checking sol_sqlite ==="
    @rm -rf examples/sol_sqlite/.mooncakes examples/sol_sqlite/_build
    cd examples/sol_sqlite && moon check --target js

check-example-sol-api:
    @echo "=== Checking sol_api ==="
    @rm -rf examples/sol_api/.mooncakes examples/sol_api/_build
    cd examples/sol_api && moon check --target js

check-example-sol-todo:
    @echo "=== Checking sol_todo ==="
    @rm -rf examples/sol_todo/.mooncakes examples/sol_todo/_build
    cd examples/sol_todo && moon check --target js

# Check all examples
check-examples: check-example-sol-app check-example-sol-auth check-example-sol-blog check-example-sol-docs check-example-sol-sqlite check-example-sol-api check-example-sol-todo
    @echo "✓ All examples checked"

# =============================================================================
# Documentation
# =============================================================================

# Docs dev server
dev-doc:
    just build-moon
    cd website && node ../_build/js/debug/build/cli/cli.js dev

# Docs build
build-doc *args:
    just build-moon
    node _build/js/debug/build/cli/cli.js build {{args}}

# Docs smoke test
smoke-docs:
    test -f website/dist-docs/index.html
    test -s website/dist-docs/index.html
    grep -Eiq "<!doctype html|<!DOCTYPE html>" website/dist-docs/index.html

# Docs lint
lint-doc:
    just build-moon
    node _build/js/debug/build/cli/cli.js lint

# Docs preview
preview-doc:
    npx serve website/dist-docs

release-doc: build-doc
    pnpm wrangler deploy --config wrangler.json

# =============================================================================
# Benchmark
# =============================================================================

# Server benchmark
bench-server:
    #!/usr/bin/env bash
    set -e
    just build-moon
    cd examples/sol_app
    pnpm build
    pnpm serve &
    SERVER_PID=$!
    trap "kill $SERVER_PID 2>/dev/null || true" EXIT
    sleep 3
    for path in "/" "/form" "/api/health"; do
        echo "=== Benchmark: $path ==="
        npx autocannon -c 100 -d 10 "http://localhost:3000$path"
        echo ""
    done
    echo "✓ Benchmark completed"

# k6 benchmark (examples/sol_app)
bench-k6 vus="20" duration="30s" think_time="0.1" runs="1":
    #!/usr/bin/env bash
    set -euo pipefail
    just build-moon
    cd examples/sol_app
    node ../../_build/js/debug/build/cli/cli.js build
    SOL_BENCH_MODE=1 PORT=7777 node ../../_build/js/debug/build/cli/cli.js serve > /tmp/sol-bench-k6.log 2>&1 &
    SERVER_PID=$!
    trap "kill $SERVER_PID 2>/dev/null || true" EXIT

    for _ in {1..30}; do
        if curl -fsS "http://localhost:7777/api/health" > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    curl -fsS "http://localhost:7777/api/health" > /dev/null 2>&1

    cd ../..
    RUNS="{{runs}}"
    if ! [[ "$RUNS" =~ ^[0-9]+$ ]] || [ "$RUNS" -lt 1 ]; then
        echo "ERROR: runs must be an integer >= 1 (got: $RUNS)" >&2
        exit 1
    fi

    RESULT_FILES=()
    for i in $(seq 1 "$RUNS"); do
        if [ "$RUNS" -eq 1 ]; then
            RUN_RESULT_JSON="${RESULTS_JSON:-bench/k6/results/latest.json}"
        else
            RUN_RESULT_BASE="${RESULTS_JSON_BASE:-bench/k6/results/latest}"
            RUN_RESULT_JSON="${RUN_RESULT_BASE}_run${i}.json"
        fi

        mkdir -p "$(dirname "$RUN_RESULT_JSON")"
        echo "=== k6 run ${i}/${RUNS} ==="
        BASE_URL="http://localhost:7777" \
        VUS="{{vus}}" \
        DURATION="{{duration}}" \
        THINK_TIME="{{think_time}}" \
        RESULTS_JSON="$RUN_RESULT_JSON" \
        k6 run bench/k6/sol-app-mix.js
        RESULT_FILES+=("$RUN_RESULT_JSON")
    done

    if [ "$RUNS" -gt 1 ]; then
        node bench/k6/summarize-results.js "${RESULT_FILES[@]}"
    fi

    echo "✓ k6 benchmark completed"

# k6 quick benchmark
bench-k6-quick:
    @just bench-k6 5 10s 0.05

# k6 per-route profile
bench-k6-profile vus="10" duration="10s":
    #!/usr/bin/env bash
    set -euo pipefail
    BASE_URL="http://localhost:7777" VUS="{{vus}}" DURATION="{{duration}}" THINK_TIME=0.02 k6 run bench/k6/sol-app-route-profile.js

# k6 result comparison (mix / route / auto)
bench-k6-compare baseline candidate mode="auto":
    node bench/k6/compare.js "{{baseline}}" "{{candidate}}" "{{mode}}"

# =============================================================================
# Coverage
# =============================================================================

# MoonBit coverage
coverage:
    rm -f _build/moonbit_coverage_*.txt
    moon test --target js --enable-coverage
    moon coverage report -f summary

# Coverage clean
coverage-clean:
    rm -rf coverage/
    moon coverage clean

# =============================================================================
# CI
# =============================================================================

# CI check
ci: check test test-docs check-examples
    @echo "✓ All CI checks passed"

# =============================================================================
# Release
# =============================================================================

# Regenerate CHANGELOG
changelog tag:
    git cliff --tag {{tag}} -o CHANGELOG.md

# CHANGELOG preview (unreleased only)
changelog-preview:
    git cliff --unreleased
