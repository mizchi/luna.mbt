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

# MoonBit デバッグビルド（ソースマップ付き）
build-debug:
    moon build --target js -g

# Loader ビルド
build-loader:
    pnpm exec rolldown -c rolldown.config.mjs

# フルビルド
build: build-moon build-loader
    pnpm vite build

# =============================================================================
# テスト（ピラミッド構造）
# =============================================================================

# 全テスト（ピラミッド順: unit → integration → e2e）
test: test-unit test-integration test-e2e test-examples
    @echo "✓ All tests passed"

# --- Layer 1: Unit Tests (最速・最多) ---
test-unit: test-moonbit test-xplat test-ts

# --- Layer 2: Integration Tests (中間) ---
test-integration: test-vitest test-browser

# --- Layer 3: E2E Tests (最遅・最少) ---
test-e2e: build-moon
    pnpm playwright test --config e2e/playwright.config.mts

# =============================================================================
# テスト（カテゴリ別）
# =============================================================================

# MoonBit ユニットテスト
test-moonbit:
    moon test --target js

# クロスプラットフォームテスト (js, wasm-gc, native)
test-xplat:
    moon test --target all src/core/signal
    moon test --target all src/core/routes
    moon test --target all src/core/render
    moon test --target all src/core/serialize
    moon test --target all src/core/ssg

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
    rm -f target/js/release/check/check.moon_db
    moon info
    moon build -C examples/sol_app

# Sol new テンプレートテスト
test-sol-new: build-moon
    node scripts/test-sol-new.ts

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
    LOADER_SIZE=$(wc -c < js/loader/src/loader.js)
    echo "loader.js: ${LOADER_SIZE} bytes"
    if [ "$LOADER_SIZE" -gt 5120 ]; then
        echo "❌ loader.js exceeds 5KB limit"
        exit 1
    fi
    echo "✓ Bundle sizes OK"

# バンドルサイズ表示
size:
    @echo "=== Bundle Sizes ==="
    @ls -lh js/loader/*.js 2>/dev/null | awk '{print $9 ": " $5}'
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
# ドキュメント
# =============================================================================

# docs 開発サーバー
doc: build-moon
    node target/js/release/build/astra/cli/cli.js dev

# docs ビルド
build-doc: build-moon
    @echo "Building demo..."
    pnpm vite build
    @echo "Building docs..."
    node target/js/release/build/astra/cli/cli.js build
    @echo "✓ Documentation built in dist/"

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
# ベンチマーク・メトリクス
# =============================================================================

# ベンチマーク実行
bench:
    node bench/run.js

# ベンチマーク (happydom)
bench-happydom:
    node bench/run-happydom.js

# メトリクス収集
metrics:
    node scripts/metrics.ts

# メトリクス表示
metrics-show:
    node scripts/metrics.ts show
