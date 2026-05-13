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
    moon build --target js --release luna/src
    moon build --target js --release luna/src/js/api
    moon build --target js --release luna/src/js/api_signals
    moon build --target js --release luna/src/js/api_resource_lite
    moon build --target js --release luna/src/js/api_router_lite
    @rm -f _build/js/release/build/package.json

# MoonBit デバッグビルド（ソースマップ付き）
build-debug:
    moon build --target js -g luna/src
    moon build --target js -g luna/src/js/api
    moon build --target js -g luna/src/js/api_signals
    moon build --target js -g luna/src/js/api_resource_lite
    moon build --target js -g luna/src/js/api_router_lite

# Loader ビルド
build-loader:
    pnpm turbo run @luna_ui/luna-loader#build

# フルビルド（turbo経由）
build:
    pnpm turbo run build
    pnpm vite build --config luna/vite.config.ts

# =============================================================================
# テスト（個別ランナー - turbo から呼ばれる）
# =============================================================================

# MoonBit ユニットテスト
test-moonbit: _setup-test-env
    moon test --target js

# Vitest テスト
test-vitest:
    pnpm vitest run --config luna/vitest.config.ts --project node --project browser

# E2E テスト
test-e2e:
    pnpm playwright test --config luna/e2e/playwright.config.mts

# E2E テスト（UI モード）
test-e2e-ui:
    pnpm playwright test --config luna/e2e/playwright.config.mts --ui

# luna-examples worker のデプロイ後 smoke (LUNA_EXAMPLES_URL で URL 上書き可)
test-deployed-luna:
    pnpm playwright test --config luna/e2e/deployed/playwright.config.mts

# Luna UI website のデプロイ後 smoke (WEBSITE_URL で URL 上書き可)
# astra ローカル node_modules の playwright を使うため astra から実行
test-deployed-website:
    cd astra && pnpm exec playwright test --config e2e/deployed/playwright.config.mts

# 全 deployed smoke (luna-examples + website)
test-deployed: test-deployed-luna test-deployed-website

# sol_app の遷移を chaosbringer で crawl (sol/e2e のローカル dev サーバー使用)
test-sol-chaos:
    pnpm -F @luna_ui/sol-workspace exec playwright test --config "$(pwd)/sol/e2e/playwright-sol-app-chaos.config.mts"

# クロスプラットフォームテスト (js, wasm-gc, native)
test-xplat:
    moon test --target all luna/src/core/routes
    moon test --target all luna/src/core/render
    moon test --target all luna/src/core/serialize

# moon test 用 CommonJS 環境セットアップ
_setup-test-env:
    @mkdir -p _build/js/debug/test
    @echo '{"type": "commonjs"}' > _build/js/debug/test/package.json

# =============================================================================
# CI
# =============================================================================

# CI チェック
ci: check test-incremental size-check runtime-check moonbench-check
    @echo "✓ All CI checks passed"

# バンドルサイズチェック
size-check: bundle-check
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

# Loader bundle サイズ計測
bundle-size:
    node luna/scripts/bundle-size.mjs --build

# Loader bundle ベースライン更新
bundle-baseline:
    node luna/scripts/bundle-size.mjs --build --write-baseline

# Loader bundle ベースライン差分チェック
bundle-check:
    node luna/scripts/bundle-size.mjs --build --check

# Treeshake 後サイズ計測
treeshake-size:
    node luna/scripts/treeshake-size.mjs --build

# Luna と Preact のユースケース別サイズ比較
preact-size:
    node luna/scripts/preact-size-compare.mjs --build

# Luna と Preact のユースケース別サイズ比較 (JSON)
preact-size-json:
    node luna/scripts/preact-size-compare.mjs --build --json

# Treeshake ベースライン更新
treeshake-baseline:
    node luna/scripts/treeshake-size.mjs --build --write-baseline

# Treeshake ベースライン差分チェック
treeshake-check:
    node luna/scripts/treeshake-size.mjs --build --check

# Runtime benchmark 計測
runtime-bench:
    node luna/scripts/runtime-bench.mjs --build

# Runtime benchmark ベースライン更新
runtime-baseline:
    node luna/scripts/runtime-bench.mjs --build --write-baseline

# Runtime benchmark ベースライン差分チェック
runtime-check:
    node luna/scripts/runtime-bench.mjs --build --check

# MoonBit benchmark ベースライン更新
moonbench-baseline:
    node luna/scripts/moonbench-check.mjs --write-baseline

# MoonBit benchmark ベースライン差分チェック
moonbench-check:
    node luna/scripts/moonbench-check.mjs --check

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
    pnpm playwright test --config luna/e2e/playwright.config.mts luna/e2e/browser/coverage.test.mts

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
extract-css dir="luna/src" *flags:
    just luna css extract {{dir}} --pretty {{flags}}

# CSS ミニファイ
minify-css input *flags:
    just luna css minify {{input}} {{flags}}

# CSS を HTML に注入
inject-css html src *flags:
    just luna css inject {{html}} --src {{src}} {{flags}}

# CSS ベンチマーク
bench-css scale="all":
    node luna/src/x/css/benchmark.js --scale {{scale}}

# =============================================================================
# リリース
# =============================================================================

# CHANGELOG 再生成（全履歴、リリース時に使用）
changelog tag:
    git cliff --tag {{tag}} -o CHANGELOG.md

# CHANGELOG プレビュー（未リリース分のみ）
changelog-preview:
    git cliff --unreleased

# バージョンアップ (patch/minor/major or 0.X.Y)
# Bumps MoonBit mooncakes in lockstep; npm wrappers are release-please-managed.
# 例: just vup patch, just vup 0.4.0, just vup patch --dry-run, just vup patch --release
vup version *args:
    #!/usr/bin/env bash
    set -e
    node luna/scripts/vup.mjs {{version}} {{args}}
    if [[ ! " {{args}} " =~ " --dry-run " ]]; then
        # Per-package CHANGELOGs (each package owns its own version + cliff config).
        for pkg in luna luna_components sol sol_adapter_cloudflare astra; do
            if [[ -f "${pkg}/cliff.toml" ]]; then
                NEW_VERSION=$(node -p "require('./${pkg}/moon.mod.json').version")
                echo ""
                echo "Updating ${pkg}/CHANGELOG.md..."
                git cliff --config "${pkg}/cliff.toml" --tag "${pkg}-v${NEW_VERSION}" -o "${pkg}/CHANGELOG.md" 2>/dev/null || true
            fi
        done
    fi

# メトリクス
metrics *args:
    node luna/scripts/metrics.ts {{args}}
