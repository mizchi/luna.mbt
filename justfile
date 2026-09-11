# Luna UI Framework - Task Runner
#
# デフォルト: インクリメンタルテスト（turbo キャッシュ有効）
# 使い方: just --list

default: test-incremental

# =============================================================================
# 日常開発
# =============================================================================

# インクリメンタルテスト（キャッシュ済みはスキップ）
test-incremental: generate-examples
    pnpm turbo run test:moonbit test:vitest

# 型チェック
check: generate-examples
    moon check --target js

# Sol サンプルの生成コードを準備（クリーン checkout から実行可能）
generate-examples:
    node scripts/generate-examples.mjs

# ワークスペース登録・設定形式・サンプル単体の検証
test-workspace:
    node --test tests/integration/moon-workspace.test.js tests/integration/examples_matrix.test.js

# フォーマット
fmt:
    moon fmt

# 自動リビルド
watch: generate-examples
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
build-moon: generate-examples
    moon build --target js --release luna/src
    moon build --target js --release luna/src/js/api
    moon build --target js --release luna/src/js/api_signals
    moon build --target js --release luna/src/js/api_resource_lite
    moon build --target js --release luna/src/js/api_router_lite
    @rm -f _build/js/release/build/package.json

# MoonBit デバッグビルド（ソースマップ付き）
build-debug: generate-examples
    moon build --target js -g luna/src
    moon build --target js -g luna/src/js/api
    moon build --target js -g luna/src/js/api_signals
    moon build --target js -g luna/src/js/api_resource_lite
    moon build --target js -g luna/src/js/api_router_lite

# Loader ビルド
build-loader:
    pnpm turbo run @luna_ui/luna-loader#build

# フルビルド（turbo経由）
build: generate-examples
    pnpm turbo run build
    pnpm vite build --config luna/vite.config.ts

# =============================================================================
# テスト（個別ランナー - turbo から呼ばれる）
# =============================================================================

# MoonBit ユニットテスト
test-moonbit: generate-examples _setup-test-env
    moon test --target js

# Vitest テスト
test-vitest:
    pnpm vitest run --config luna/vitest.config.ts --project node --project browser

# E2E テスト
test-e2e:
    env -u NO_COLOR pnpm playwright test --config luna/e2e/playwright.config.mts

# animation / easing デモ: http://127.0.0.1:4179/animation.html
demo-animation:
    pnpm --filter examples-luna exec vite --host 127.0.0.1 --port 4179 --strictPort

test-animation-demo:
    pnpm --filter examples-luna exec playwright test --config animation.playwright.config.ts

# E2E テスト（UI モード）
test-e2e-ui:
    env -u NO_COLOR pnpm playwright test --config luna/e2e/playwright.config.mts --ui

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

# astra/examples/<name> の Playwright VRT (screenshot diff)
# package 命名規約: dir 名 (underscore 区切り) → @luna_ui/<dir-with-hyphens>-example
# 比較: just test-vrt-astra <name>                 (現在のホスト OS のベースライン)
# 更新: just test-vrt-astra <name> --update          (host OS 用)
# 更新: just test-vrt-astra <name> --update --linux  (docker で linux 用を seed)
# 例:   just test-vrt-astra sol_landing
#       just test-vrt-astra sol_changelog --update --linux
test-vrt-astra name *args:
    #!/usr/bin/env bash
    set -e
    pkg_name="$(echo {{name}} | tr '_' '-')"
    pkg="@luna_ui/${pkg_name}-example"
    if [[ " {{args}} " =~ " --update " ]]; then
        if [[ " {{args}} " =~ " --linux " ]]; then
            # CI 互換の linux ベースラインを docker で seed する。
            docker run --rm -v "$(pwd):/work" -w /work \
                mcr.microsoft.com/playwright:v1.61.1-noble \
                bash -c "corepack enable && cd astra/examples/{{name}} && \
                  pnpm exec playwright test --config e2e/playwright.config.mts --update-snapshots"
        else
            pnpm -F "${pkg}" test:e2e:update
        fi
    else
        pnpm -F "${pkg}" test:e2e
    fi

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

# Static CSS preprocessing before either debug or release MoonBit builds
compile-css input output:
    pnpm exec tsx js/luna/bin/cli.ts css compile {{quote(input)}} --output-dir {{quote(output)}}

# Run the self-contained MoonBit CSS command (Node.js target)
css *args:
    moon run --target js luna/src/cmd/css -- {{args}}

# Embed the shared compiler into the distributable Mooncake CLI
generate-css-cli:
    node scripts/generate-css-cli.mjs

# Measure static CSS preprocessing separately from MoonBit compilation
bench-css-compile files="1000":
    node scripts/bench-css-compile.mjs {{files}}

# Composable CSS: portable logic, extraction, SSR, and hydration
test-css: _setup-test-env
    node scripts/generate-css-properties.mjs --check
    node scripts/generate-css-pseudos.mjs --check
    node scripts/generate-css-cli.mjs --check
    moon test --target js luna/src/x/css
    moon test --target native luna/src/x/css
    moon test --target wasm-gc luna/src/x/css
    moon test --target js luna/src/tests/css_styles
    node luna/src/x/css/extract.test.js
    pnpm exec vitest run --config luna/vitest.config.ts --project node js/luna/tests/cli-style-compose.test.ts js/luna/tests/cli-style-compile.test.ts js/luna/tests/cli-css-vite.test.ts js/luna/tests/cli-moon-css.test.ts
    env -u NO_COLOR pnpm exec playwright test --config luna/e2e/playwright.config.mts luna/e2e/css-styles.test.mts luna/e2e/css-watch.test.mts

# Regenerate the typed CSS property API and extractor mapping from the pinned catalog
generate-css-properties:
    node scripts/generate-css-properties.mjs

# Regenerate typed pseudo selectors and their extraction mapping
generate-css-pseudos:
    node scripts/generate-css-pseudos.mjs

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

# npm パッケージのみビルド（サンプルは除外）
build-npm:
    pnpm build:npm

# 公開アーカイブ・workspace 公開対象の検証
test-npm-pack:
    pnpm test:npm-pack

# 未公開バージョンの npm パッケージを一括公開
# 例: just release-npm --dry-run, just release-npm
release-npm *args:
    pnpm publish -r {{args}}

# CHANGELOG 再生成（全履歴、リリース時に使用）
changelog tag:
    git cliff --tag {{tag}} -o CHANGELOG.md

# CHANGELOG プレビュー（未リリース分のみ）
changelog-preview:
    git cliff --unreleased

# mooncakes 6 連 publish (dep-order + 各 publish 後に moon update)
# 例: just release-mooncakes, just release-mooncakes --dry-run
release-mooncakes *args:
    bash scripts/release-mooncakes.sh {{args}}

# バージョンアップ (patch/minor/major or 0.X.Y)
# Bumps MoonBit mooncakes in lockstep; npm wrappers are release-please-managed.
# 例: just vup patch, just vup 0.4.0, just vup patch --dry-run, just vup patch --release
vup version *args:
    #!/usr/bin/env bash
    set -e
    node luna/scripts/vup.mjs {{version}} {{args}}
    if [[ ! " {{args}} " =~ " --dry-run " ]]; then
        # Per-package CHANGELOGs (each package owns its own version + cliff config).
        for pkg in luna luna_components sol sol_adapter_cloudflare sol_adapter_node astra; do
            if [[ -f "${pkg}/cliff.toml" ]]; then
                NEW_VERSION=$(node -e "const fs=require('fs'); const m=fs.readFileSync('./${pkg}/moon.mod','utf8').match(/^version\\s*=\\s*\\\"([^\\\"]+)\\\"/m); if(!m) process.exit(1); console.log(m[1])")
                echo ""
                echo "Updating ${pkg}/CHANGELOG.md..."
                git cliff --config "${pkg}/cliff.toml" --tag "${pkg}-v${NEW_VERSION}" -o "${pkg}/CHANGELOG.md" 2>/dev/null || true
            fi
        done
    fi

# メトリクス
metrics *args:
    node luna/scripts/metrics.ts {{args}}
