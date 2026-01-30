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
    rm -rf target .turbo/cache

# =============================================================================
# ビルド
# =============================================================================

# MoonBit ビルド
build-moon:
    moon build --target js
    @rm -f target/js/release/build/package.json

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
    @mkdir -p target/js/debug/test
    @echo '{"type": "commonjs"}' > target/js/debug/test/package.json

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

test-all: test test-ssg test-xplat test-e2e test-sol-app

# =============================================================================
# CLI
# =============================================================================

# Sol CLI
sol *args:
    @just build-moon
    node target/js/release/build/cli/cli.js {{args}}

# =============================================================================
# Examples
# =============================================================================

# sol_app 開発サーバー（フレームワークホットリロード付き）
dev-app:
    just build-moon
    cd examples/sol_app && node ../../target/js/release/build/cli/cli.js dev -f

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
    cd website && node ../target/js/release/build/cli/cli.js dev

# docs ビルド
build-doc *args:
    just build-moon
    node target/js/release/build/cli/cli.js build {{args}}

# docs lint
lint-doc:
    just build-moon
    node target/js/release/build/cli/cli.js lint

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

# =============================================================================
# カバレッジ
# =============================================================================

# MoonBit カバレッジ
coverage:
    rm -f target/moonbit_coverage_*.txt
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
ci: check test check-examples
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
