# Luna UI Framework - Task Runner
#
# デフォルト: インクリメンタルテスト（turbo キャッシュ有効）
# 使い方: just --list

default: test-incremental

# =============================================================================
# 日常開発
# =============================================================================

# インクリメンタルテスト（キャッシュ済みはスキップ）
test-incremental:
    pnpm turbo run test:moonbit test:ts test:vitest test:browser

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
    rm -rf target coverage .turbo/cache

# 強制テスト（キャッシュ無視）
retest *tasks="test:moonbit test:ts test:vitest test:browser":
    pnpm turbo run {{tasks}} --force

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

# Loader ビルド
build-loader:
    pnpm exec rolldown -c rolldown.config.mjs

# フルビルド（turbo経由）
build:
    pnpm turbo run build
    pnpm vite build

# =============================================================================
# テスト（個別ランナー - turbo から呼ばれる）
# =============================================================================

# MoonBit ユニットテスト
test-moonbit: _setup-test-env
    moon test --target js

# TypeScript 型チェック
test-ts:
    pnpm tsc -p .

# Vitest テスト
test-vitest:
    pnpm vitest run

# ブラウザテスト
test-browser:
    pnpm vitest run --config vitest.browser.config.ts

# E2E テスト
test-e2e:
    pnpm playwright test --config e2e/playwright.config.mts

# E2E テスト（UI モード）
test-e2e-ui:
    pnpm playwright test --config e2e/playwright.config.mts --ui

# クロスプラットフォームテスト (js, wasm-gc, native)
test-xplat:
    moon test --target all src/luna/signal
    moon test --target all src/luna/routes
    moon test --target all src/luna/render
    moon test --target all src/luna/serialize
    moon test --target all src/core/parser

# moon test 用 CommonJS 環境セットアップ
_setup-test-env:
    @mkdir -p target/js/debug/test
    @echo '{"type": "commonjs"}' > target/js/debug/test/package.json

# =============================================================================
# テスト（プロダクト別）
# =============================================================================

# Astra テスト
test-astra: _setup-test-env
    moon test --target js src/astra/shiki src/astra/markdown src/astra/routes src/astra/tree
    pnpm playwright test --config e2e/astra/playwright.config.ts

# Sol テスト
test-sol: _setup-test-env
    moon test --target js src/sol
    cd examples/sol_app && pnpm test:e2e

# セキュリティテスト
test-security:
    cd examples/sol_app && pnpm vitest run tests/security.test.ts tests/security-headers.test.ts

# サンプルプロジェクトビルド確認
test-examples:
    moon info
    moon build -C examples/sol_app

# =============================================================================
# CI
# =============================================================================

# CI チェック
ci: check test-incremental size-check
    @echo "✓ All CI checks passed"

# バンドルサイズチェック
size-check:
    #!/usr/bin/env bash
    set -e
    LOADER_SIZE=$(wc -c < js/loader/dist/loader.js)
    echo "loader.js: ${LOADER_SIZE} bytes"
    [ "$LOADER_SIZE" -le 5120 ] || { echo "❌ Exceeds 5KB limit"; exit 1; }
    echo "✓ Bundle sizes OK"

# バンドルサイズ表示
size:
    @echo "=== Bundle Sizes ==="
    @ls -lh js/loader/dist/*.js 2>/dev/null | awk '{print $9 ": " $5}'
    @echo ""
    @echo "=== MoonBit Output ==="
    @find target/js/release/build -name "*.js" -exec ls -lh {} \; 2>/dev/null | awk '{print $9 ": " $5}' | head -20

# =============================================================================
# CLI
# =============================================================================

# Sol CLI
sol *args:
    @just build-moon
    node target/js/release/build/sol/cli/cli.js {{args}}

# Astra CLI
astra *args:
    @just build-moon
    node target/js/release/build/astra/cli/cli.js {{args}}

# =============================================================================
# ドキュメント
# =============================================================================

# docs 開発サーバー
dev-doc:
    @just build-moon
    node target/js/release/build/astra/cli/cli.js dev

# docs ビルド
build-doc *args:
    @just build-moon
    @echo "Building demo..."
    pnpm vite build
    mv website/public/demo/demo-src/* website/public/demo/ && rm -rf website/public/demo/demo-src
    @echo "Building docs..."
    node target/js/release/build/astra/cli/cli.js build --parallel {{args}}
    @echo "✓ Documentation built"

# docs lint
lint-doc:
    @just build-moon
    node target/js/release/build/astra/cli/cli.js lint

# docs プレビュー
preview-doc:
    npx serve dist

# docs リンクチェック (--strict でコンソールエラーも検出)
test-docs-links *flags:
    #!/usr/bin/env bash
    set -e
    just build-doc
    echo "Starting server..."
    npx serve dist-docs -p 3355 &
    SERVER_PID=$!
    trap "kill $SERVER_PID 2>/dev/null || true" EXIT
    sleep 2
    cd js/playwright-chaos
    npx tsx src/cli.ts http://localhost:3355 \
        --max-pages 100 --max-actions 0 --ignore-analytics \
        --exclude "/public/demo/" --compact --output chaos-report.json {{flags}}
    echo "✓ All links OK"

# =============================================================================
# カバレッジ
# =============================================================================

# 全カバレッジ
coverage: coverage-moonbit coverage-vitest coverage-e2e
    node scripts/coverage.ts
    @echo "✓ Coverage reports in coverage/"

# MoonBit カバレッジ
coverage-moonbit:
    rm -f target/moonbit_coverage_*.txt
    moon test --target js --enable-coverage
    moon coverage report -f cobertura -o coverage/moonbit-coverage.xml
    moon coverage report -f summary

# Vitest カバレッジ
coverage-vitest:
    @just build-debug
    pnpm vitest run --coverage --coverage.provider=v8 --coverage.reporter=json --coverage.reportsDirectory=coverage/vitest

# E2E カバレッジ
coverage-e2e:
    @just build-debug
    rm -rf coverage/e2e-v8
    pnpm playwright test --config e2e/playwright.config.mts e2e/browser-app/coverage.test.mts

# カバレッジクリーン
coverage-clean:
    rm -rf coverage/
    moon coverage clean

# =============================================================================
# ベンチマーク
# =============================================================================

# サーバーベンチマーク
bench-server:
    #!/usr/bin/env bash
    set -e
    just build-moon
    cd examples/sol_app
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

# CSS ベンチマーク
bench-css scale="all":
    node src/luna/css/benchmark.js --scale {{scale}}

# =============================================================================
# CSS ユーティリティ
# =============================================================================

# CSS 抽出 (--json, --strict, --no-warn オプション対応)
extract-css dir="src" *flags:
    node src/luna/css/extract.js {{dir}} --pretty {{flags}}

# CSS ミニファイ
minify-css input *flags:
    node src/luna/css/minify.js {{input}} {{flags}}

# =============================================================================
# リリース
# =============================================================================

# CHANGELOG 更新
changelog:
    git-cliff --unreleased --prepend CHANGELOG.md 2>/dev/null

# CHANGELOG プレビュー
changelog-preview:
    git-cliff --unreleased 2>/dev/null

# メトリクス
metrics *args:
    node scripts/metrics.ts {{args}}
