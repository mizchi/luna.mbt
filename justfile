# Sol SSR/SSG Framework - Task Runner
#
# 使い方: just --list

default: check

# =============================================================================
# 日常開発
# =============================================================================

# 型チェック
check:
    moon check --target js

# フォーマット
fmt:
    moon fmt

# 自動リビルド
watch:
    moon build --target js --watch

# クリーン
clean:
    moon clean
    rm -rf _build target .turbo/cache

# =============================================================================
# ビルド
# =============================================================================

# MoonBit ビルド
build-moon:
    moon build --target js
    @rm -f _build/js/debug/build/package.json

# MoonBit デバッグビルド（ソースマップ付き）
build-debug:
    moon build --target js -g

# フルビルド
build:
    just build-moon

# =============================================================================
# テスト
# =============================================================================

# MoonBit ユニットテスト
test: _setup-test-env
    moon test --target js

# moon test 用 CommonJS 環境セットアップ
_setup-test-env:
    @mkdir -p _build/js/debug/test
    @echo '{"type": "commonjs"}' > _build/js/debug/test/package.json

# SSG テスト
test-ssg: _setup-test-env
    moon test --target js src/ssg

# クロスプラットフォームテスト (wasm, wasm-gc, native)
test-xplat:
    moon test --target wasm src/parser
    moon test --target wasm-gc src/parser
    moon test --target native src/parser

# E2E テスト
test-e2e:
    pnpm playwright test --config e2e/playwright.config.mts

# E2E テスト (UI モード)
test-e2e-ui:
    pnpm playwright test --config e2e/playwright.config.mts --ui

# sol_app E2E テスト
test-sol-app:
    cd examples/sol_app && pnpm test

# docs 整合テスト
test-docs:
    node --test docs/docs-index.test.js docs/docs-chapters.test.js docs/docs-build-paths.test.js docs/docs-ci.test.js

test-all: test test-ssg test-xplat test-docs test-e2e test-sol-app

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

# sol_app 開発サーバー（フレームワークホットリロード付き）
dev-app:
    just build-moon
    cd examples/sol_app && node ../../_build/js/debug/build/cli/cli.js dev -f

# examples のキャッシュクリーン
clean-examples:
    @rm -rf examples/sol_app/.mooncakes examples/sol_app/_build
    @rm -rf examples/sol_auth/.mooncakes examples/sol_auth/_build
    @rm -rf examples/sol_blog/.mooncakes examples/sol_blog/_build
    @rm -rf examples/sol_docs/.mooncakes examples/sol_docs/_build
    @rm -rf examples/sol_sqlite/.mooncakes examples/sol_sqlite/_build
    @rm -rf examples/sol_api/.mooncakes examples/sol_api/_build
    @echo "✓ Examples cache cleaned"

# 各 example のビルドチェック
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

# すべての examples をチェック
check-examples: check-example-sol-app check-example-sol-auth check-example-sol-blog check-example-sol-docs check-example-sol-sqlite check-example-sol-api
    @echo "✓ All examples checked"

# =============================================================================
# ドキュメント
# =============================================================================

# docs 開発サーバー
dev-doc:
    just build-moon
    cd website && node ../_build/js/debug/build/cli/cli.js dev

# docs ビルド
build-doc *args:
    just build-moon
    node _build/js/debug/build/cli/cli.js build {{args}}

# docs lint
lint-doc:
    just build-moon
    node _build/js/debug/build/cli/cli.js lint

# docs プレビュー
preview-doc:
    npx serve website/dist-docs

release-doc: build-doc
    pnpm wrangler publish --config wrangler.json 

# =============================================================================
# ベンチマーク
# =============================================================================

# サーバーベンチマーク
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

# k6 ベンチマーク (examples/sol_app)
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

# k6 クイックベンチマーク
bench-k6-quick:
    @just bench-k6 5 10s 0.05

# k6 ルート別プロファイル
bench-k6-profile vus="10" duration="10s":
    #!/usr/bin/env bash
    set -euo pipefail
    BASE_URL="http://localhost:7777" VUS="{{vus}}" DURATION="{{duration}}" THINK_TIME=0.02 k6 run bench/k6/sol-app-route-profile.js

# k6 結果比較（mix / route / auto）
bench-k6-compare baseline candidate mode="auto":
    node bench/k6/compare.js "{{baseline}}" "{{candidate}}" "{{mode}}"

# =============================================================================
# カバレッジ
# =============================================================================

# MoonBit カバレッジ
coverage:
    rm -f _build/moonbit_coverage_*.txt
    moon test --target js --enable-coverage
    moon coverage report -f summary

# カバレッジクリーン
coverage-clean:
    rm -rf coverage/
    moon coverage clean

# =============================================================================
# CI
# =============================================================================

# CI チェック
ci: check test test-docs check-examples
    @echo "✓ All CI checks passed"

# =============================================================================
# リリース
# =============================================================================

# CHANGELOG 再生成
changelog tag:
    git cliff --tag {{tag}} -o CHANGELOG.md

# CHANGELOG プレビュー（未リリース分のみ）
changelog-preview:
    git cliff --unreleased
