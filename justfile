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
    pnpm turbo run test:moonbit test:vitest

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
    rm -rf _build target coverage .turbo/cache

# 強制テスト（キャッシュ無視）
retest *tasks="test:moonbit test:vitest":
    pnpm turbo run {{tasks}} --force

# =============================================================================
# ビルド
# =============================================================================

# MoonBit ビルド
build-moon:
    moon build --target js
    @rm -f _build/js/release/build/package.json

# MoonBit デバッグビルド（ソースマップ付き）
build-debug:
    moon build --target js -g

# Loader ビルド
build-loader:
    pnpm turbo run @luna_ui/luna-loader#build

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

# Vitest テスト
test-vitest:
    pnpm vitest run --project node --project browser

# E2E テスト
test-e2e:
    pnpm playwright test --config e2e/playwright.config.mts

# E2E テスト（UI モード）
test-e2e-ui:
    pnpm playwright test --config e2e/playwright.config.mts --ui

# クロスプラットフォームテスト (js, wasm-gc, native)
test-xplat:
    moon test --target all src/core/routes
    moon test --target all src/core/render
    moon test --target all src/core/serialize

# moon test 用 CommonJS 環境セットアップ
_setup-test-env:
    @mkdir -p _build/js/debug/test
    @echo '{"type": "commonjs"}' > _build/js/debug/test/package.json

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
    @find _build/js/release/build -name "*.js" -exec ls -lh {} \; 2>/dev/null | awk '{print $9 ": " $5}' | head -20

# Treeshake 後サイズ計測
treeshake-size:
    node scripts/treeshake-size.mjs --build

# Treeshake ベースライン更新
treeshake-baseline:
    node scripts/treeshake-size.mjs --build --write-baseline

# Treeshake ベースライン差分チェック
treeshake-check:
    node scripts/treeshake-size.mjs --build --check

# =============================================================================
# カバレッジ
# =============================================================================

# 全カバレッジ
coverage: coverage-moonbit coverage-vitest coverage-e2e
    node scripts/coverage.ts
    @echo "✓ Coverage reports in coverage/"

# MoonBit カバレッジ
coverage-moonbit:
    rm -f _build/moonbit_coverage_*.txt
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
    pnpm playwright test --config e2e/playwright.config.mts e2e/browser/coverage.test.mts

# カバレッジクリーン
coverage-clean:
    rm -rf coverage/
    moon coverage clean

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

# CSS ベンチマーク
bench-css scale="all":
    node src/x/css/benchmark.js --scale {{scale}}

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
