# Luna UI Framework - Task Runner
#
# テストはピラミッド構造:
#   test-unit        → 最速・最多 (MoonBit, TypeScript)
#   test-integration → 中間 (Vitest, Browser)
#   test-e2e         → 最遅・最少 (Playwright)

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
    rm -rf target coverage

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

# js/luna ビルド
build-luna:
    cd js/luna && pnpm build

# js/astra ビルド
build-astra:
    cd js/astra && pnpm build

# フルビルド
build: build-moon build-loader build-luna build-astra
    pnpm vite build

# CSS 静的抽出（全.mbtファイルからCSS宣言を抽出）
extract-css dir="src" output="":
    #!/usr/bin/env bash
    if [ -z "{{output}}" ]; then
        node src/luna/css/extract.js {{dir}} --pretty
    else
        node src/luna/css/extract.js {{dir}} --output {{output}} --pretty --verbose
    fi

# CSS 静的抽出（JSON形式 - マッピング情報付き）
extract-css-json dir="src" output="":
    #!/usr/bin/env bash
    if [ -z "{{output}}" ]; then
        node src/luna/css/extract.js {{dir}} --json --pretty
    else
        node src/luna/css/extract.js {{dir}} --json --output {{output}} --pretty --verbose
    fi

# CSS 静的抽出（警告なし）
extract-css-quiet dir="src" output="":
    #!/usr/bin/env bash
    if [ -z "{{output}}" ]; then
        node src/luna/css/extract.js {{dir}} --pretty --no-warn
    else
        node src/luna/css/extract.js {{dir}} --output {{output}} --pretty --verbose --no-warn
    fi

# CSS 静的抽出（strict - 警告があればエラー終了）
extract-css-strict dir="src":
    node src/luna/css/extract.js {{dir}} --strict --pretty

# CSS ユーティリティを main.css に追加（ビルド統合用）
inject-utility-css:
    #!/usr/bin/env bash
    set -e
    UTILITY_CSS=$(node src/luna/css/extract.js src --no-warn 2>/dev/null)
    if [ -n "$UTILITY_CSS" ]; then
        echo "" >> src/astra/assets/styles/main.css
        echo "/* === CSS Utilities (auto-generated) === */" >> src/astra/assets/styles/main.css
        echo "$UTILITY_CSS" >> src/astra/assets/styles/main.css
        echo "✓ Injected utility CSS into main.css"
    else
        echo "No utility CSS to inject"
    fi

# =============================================================================
# テスト（ピラミッド構造）
# =============================================================================

# 全テスト（ピラミッド順: unit → integration → e2e）
test: test-unit test-integration test-e2e test-examples test-sol-example
    @echo "✓ All tests passed"

# --- Layer 1: Unit Tests (最速・最多) ---
test-unit: test-moonbit test-xplat test-ts

# --- Layer 2: Integration Tests (中間) ---
test-integration: test-vitest test-browser

# --- Layer 3: E2E Tests (最遅・最少) ---
test-e2e: build-moon
    pnpm playwright test --config e2e/playwright.config.mts

# =============================================================================
# テスト（ピラミッド軸 - カテゴリ別）
# =============================================================================

# MoonBit ユニットテスト
test-moonbit: _setup-test-env
    moon test --target js

# moon test 用の CommonJS 環境をセットアップ (moon test が CJS を出力するため)
_setup-test-env:
    @mkdir -p target/js/debug/test
    @echo '{"type": "commonjs"}' > target/js/debug/test/package.json

# クロスプラットフォームテスト (js, wasm-gc, native)
test-xplat:
    moon test --target all src/luna/signal
    moon test --target all src/luna/routes
    moon test --target all src/luna/render
    moon test --target all src/luna/serialize
    moon test --target all src/core/parser

# TypeScript 型チェック
test-ts:
    pnpm tsc -p .

# Vitest テスト
test-vitest: build-moon
    pnpm vitest run

# ブラウザテスト (Vitest)
test-browser: build-moon
    pnpm vitest run --config vitest.browser.config.ts

# E2E UI モード
test-e2e-ui: build-moon
    pnpm playwright test --config e2e/playwright.config.mts --ui

# サンプルプロジェクトテスト
test-examples:
    moon info
    moon build -C examples/sol_app

# =============================================================================
# テスト（プロダクト軸）
# =============================================================================

# --- Astra (SSG) ---
# Astra 全テスト
test-astra: test-astra-unit test-astra-e2e
    @echo "✓ All Astra tests passed"

# Astra ユニットテスト (MoonBit)
test-astra-unit: _setup-test-env
    moon test --target js src/astra/shiki
    moon test --target js src/astra/markdown
    moon test --target js src/astra/routes
    moon test --target js src/astra/tree

# Astra E2E テスト (Playwright)
test-astra-e2e: build-moon
    pnpm playwright test --config e2e/astra/playwright.config.ts

# --- Sol (SSR Framework) ---
# Sol 全テスト
test-sol: test-sol-unit test-sol-e2e
    @echo "✓ All Sol tests passed"

# Sol ユニットテスト (MoonBit)
test-sol-unit: _setup-test-env
    moon test --target js src/sol

# Sol E2E テスト
test-sol-e2e: build-moon test-sol-new test-sol-example

# Sol new テンプレートテスト
test-sol-new: build-moon
    node scripts/test-sol-new.ts

# Sol example E2E テスト
test-sol-example: build-moon
    cd examples/sol_app && pnpm test:e2e

# Sol セキュリティテスト
test-security: build-moon
    cd examples/sol_app && pnpm vitest run tests/security.test.ts tests/security-headers.test.ts

# --- Luna (Core UI Library) ---
# Luna 全テスト
test-luna: test-luna-unit test-luna-browser
    @echo "✓ All Luna tests passed"

# Luna ユニットテスト (MoonBit, クロスプラットフォーム)
test-luna-unit: _setup-test-env
    moon test --target all src/luna/signal
    moon test --target all src/luna/routes
    moon test --target all src/luna/render
    moon test --target all src/luna/serialize

# Luna ブラウザテスト
test-luna-browser: build-moon
    pnpm vitest run --config vitest.browser.config.ts

# =============================================================================
# CI
# =============================================================================

# PR前チェック
ci: check test size-check
    @echo "✓ All CI checks passed"

# バンドルサイズチェック
size-check:
    #!/usr/bin/env bash
    set -e
    LOADER_SIZE=$(wc -c < js/loader/dist/loader.js)
    echo "loader.js: ${LOADER_SIZE} bytes"
    if [ "$LOADER_SIZE" -gt 5120 ]; then
        echo "❌ loader.js exceeds 5KB limit"
        exit 1
    fi
    echo "✓ Bundle sizes OK"

# バンドルサイズ表示
size:
    @echo "=== Bundle Sizes ==="
    @ls -lh js/loader/dist/*.js 2>/dev/null | awk '{print $9 ": " $5}'
    @echo ""
    @echo "=== MoonBit Output Sizes ==="
    @find target/js/release/build -name "*.js" -exec ls -lh {} \; 2>/dev/null | awk '{print $9 ": " $5}' | head -20

# =============================================================================
# カバレッジ
# =============================================================================

# 全カバレッジ（レポート生成）
coverage: coverage-moonbit coverage-vitest coverage-e2e coverage-report
    @echo "✓ Coverage reports generated in coverage/"

# MoonBit カバレッジ
coverage-moonbit:
    rm -f target/moonbit_coverage_*.txt
    moon test --target js --enable-coverage
    moon coverage report -f cobertura -o coverage/moonbit-coverage.xml
    moon coverage report -f summary

# Vitest カバレッジ
coverage-vitest: build-debug
    pnpm vitest run --coverage --coverage.provider=v8 --coverage.reporter=json --coverage.reportsDirectory=coverage/vitest

# E2E カバレッジ
coverage-e2e: build-debug
    rm -rf coverage/e2e-v8
    pnpm playwright test --config e2e/playwright.config.mts e2e/browser-app/coverage.test.mts

# カバレッジレポート生成
coverage-report:
    node scripts/coverage.ts

# HTML カバレッジレポート
coverage-html:
    node scripts/coverage.ts html

# カバレッジクリーン
coverage-clean:
    rm -rf coverage/
    moon coverage clean

# =============================================================================
# CLI
# =============================================================================

# Sol CLI
sol *args: build-moon
    node target/js/release/build/sol/cli/cli.js {{args}}

# Astra CLI
astra *args: build-moon
    node target/js/release/build/astra/cli/cli.js {{args}}

# =============================================================================
# 開発サーバー
# =============================================================================

# Sol 開発サーバー（examples/sol_app）
dev-sol: build-moon
    cd examples/sol_app && pnpm dev

# =============================================================================
# ドキュメント
# =============================================================================

# docs 開発サーバー（インクリメンタルビルド）
dev-doc: build-moon
    node target/js/release/build/astra/cli/cli.js dev

# docs ビルド (例: just build-doc -j 4)
build-doc *args: build-moon
    @echo "Linting docs..."
    -node target/js/release/build/astra/cli/cli.js lint
    @echo ""
    @echo "Building demo..."
    pnpm vite build
    # Move demo-src contents up one level (vite outputs with demo-src/ prefix)
    mv docs/public/demo/demo-src/* docs/public/demo/
    rm -rf docs/public/demo/demo-src
    @echo "Building docs..."
    node target/js/release/build/astra/cli/cli.js build --parallel {{args}}
    @echo "✓ Documentation built in dist/"

# docs lint のみ
lint-doc: build-moon
    node target/js/release/build/astra/cli/cli.js lint

# docs プレビュー
preview-doc:
    npx serve dist

# SSG ビルド（シンタックスハイライト付き）
ssg-build output="dist": build-moon
    node target/js/release/build/astra/cli/cli.js build -o {{output}}
    npx tsx scripts/shiki-highlight.ts {{output}}

# SSG ビルド（高速、ハイライトなし）
ssg-build-fast output="dist": build-moon
    node target/js/release/build/astra/cli/cli.js build -o {{output}}

# =============================================================================
# ベンチマーク
# =============================================================================

# bench-moonbit: build-moon

# サーバーベンチマーク（autocannon）
bench-server: build-moon
    #!/usr/bin/env bash
    set -e
    cd examples/sol_app
    echo "Starting server..."
    pnpm serve &
    SERVER_PID=$!
    sleep 3

    echo ""
    echo "=== Benchmark: / (SSR) ==="
    npx autocannon -c 100 -d 10 http://localhost:3000/

    echo ""
    echo "=== Benchmark: /form (SSR) ==="
    npx autocannon -c 100 -d 10 http://localhost:3000/form

    echo ""
    echo "=== Benchmark: /api/health (JSON) ==="
    npx autocannon -c 100 -d 10 http://localhost:3000/api/health

    kill $SERVER_PID 2>/dev/null || true
    echo ""
    echo "✓ Benchmark completed"

# =============================================================================
# リンクチェック（Chaos Crawler）
# =============================================================================

# ドキュメントのリンクチェック（ローカルサーバー起動 → クロール → 終了）
test-docs-links: build-doc
    #!/usr/bin/env bash
    set -e
    echo "Starting docs server..."
    npx serve dist-docs -p 3355 &
    SERVER_PID=$!
    sleep 2

    echo "Running chaos crawler..."
    cd js/playwright-chaos
    npx tsx src/cli.ts http://localhost:3355 \
        --max-pages 100 \
        --max-actions 0 \
        --ignore-analytics \
        --exclude "/public/demo/" \
        --compact \
        --output chaos-report.json \
        || EXIT_CODE=$?

    kill $SERVER_PID 2>/dev/null || true

    if [ "${EXIT_CODE:-0}" -ne 0 ]; then
        echo ""
        echo "❌ Dead links found. See chaos-report.json for details."
        exit 1
    fi
    echo "✓ All links OK"

# ドキュメントのリンクチェック（strictモード - コンソールエラーも検出）
test-docs-links-strict: build-doc
    #!/usr/bin/env bash
    set -e
    echo "Starting docs server..."
    npx serve dist-docs -p 3355 &
    SERVER_PID=$!
    sleep 2

    echo "Running chaos crawler (strict mode)..."
    cd js/playwright-chaos
    npx tsx src/cli.ts http://localhost:3355 \
        --max-pages 100 \
        --max-actions 0 \
        --ignore-analytics \
        --exclude "/public/demo/" \
        --strict \
        --compact \
        --output chaos-report.json \
        || EXIT_CODE=$?

    kill $SERVER_PID 2>/dev/null || true

    if [ "${EXIT_CODE:-0}" -ne 0 ]; then
        echo ""
        echo "❌ Issues found. See chaos-report.json for details."
        exit 1
    fi
    echo "✓ All checks passed"

# =============================================================================
# メトリクス
# =============================================================================

# メトリクス収集
metrics:
    node scripts/metrics.ts

# メトリクス表示
metrics-show:
    node scripts/metrics.ts show

# =============================================================================
# リリース
# =============================================================================

# CHANGELOG 生成（未リリース分）
changelog:
    git-cliff --unreleased --prepend CHANGELOG.md 2>/dev/null

# CHANGELOG 全体再生成
changelog-all:
    git-cliff -o CHANGELOG.md 2>/dev/null

# CHANGELOG プレビュー（未リリース分）
changelog-preview:
    git-cliff --unreleased 2>/dev/null
