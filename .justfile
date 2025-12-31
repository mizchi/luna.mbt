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
    node target/js/release/build/sol/cli/cli.js {{args}}

# =============================================================================
# ドキュメント
# =============================================================================

# docs 開発サーバー
dev-doc:
    pnpm turbo run build:moon build:sol
    node target/js/release/build/sol/cli/cli.js dev

# docs ビルド
build-doc *args:
    pnpm turbo run build:doc -- {{args}}

# docs ビルド（内部用 - turbo から呼ばれる）
_build-doc-inner *args:
    @echo "Building demo..."
    pnpm vite build
    @echo "Building docs..."
    node target/js/release/build/sol/cli/cli.js build --parallel {{args}}
    @echo "Building search index..."
    @if [ -d website/dist-docs ] && [ -n "$(find website/dist-docs -name '*.html' -type f 2>/dev/null | head -1)" ]; then \
        pnpm pagefind --site website/dist-docs; \
    else \
        echo "⚠ Skipping pagefind: no HTML files in website/dist-docs"; \
    fi
    @echo "✓ Documentation built"

# docs デプロイ（Cloudflare Pages）
release-doc:
    pnpm turbo run deploy:doc

# docs lint
lint-doc:
    pnpm turbo run build:moon build:sol
    node target/js/release/build/sol/cli/cli.js lint

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

# Luna CLI (CSS utilities, project scaffolding)
luna *args:
    node js/luna/dist/cli.mjs {{args}}

# CSS 抽出
extract-css dir="src" *flags:
    just luna css extract {{dir}} --pretty {{flags}}

# CSS ミニファイ
minify-css input *flags:
    just luna css minify {{input}} {{flags}}

# CSS を HTML に注入
inject-css html src *flags:
    just luna css inject {{html}} --src {{src}} {{flags}}

# =============================================================================
# リリース
# =============================================================================

# CHANGELOG 再生成（全履歴、リリース時に使用）
changelog tag:
    git cliff --tag {{tag}} -o CHANGELOG.md

# CHANGELOG プレビュー（未リリース分のみ）
changelog-preview:
    git cliff --unreleased

# バージョンアップ (patch/minor/major または具体的なバージョン)
# 使用例: just vup patch, just vup 0.4.0, just vup minor --dry-run
vup version *args:
    #!/usr/bin/env bash
    set -e
    # バージョン更新
    node scripts/vup.mjs {{version}} {{args}}
    # dry-run でなければ changelog 更新
    if [[ ! " {{args}} " =~ " --dry-run " ]]; then
        # 更新後のバージョンを取得
        NEW_VERSION=$(node -p "require('./moon.mod.json').version")
        echo ""
        echo "Updating CHANGELOG.md..."
        git cliff --tag "v${NEW_VERSION}" -o CHANGELOG.md 2>/dev/null
        echo "  CHANGELOG.md updated for v${NEW_VERSION}"
    fi

# メトリクス
metrics *args:
    node scripts/metrics.ts {{args}}
