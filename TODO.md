# mars thin wrapper 向けリファクタ TODO

## 方針

- `sol` は `mars` の薄いラッパーに寄せる
- `sol` の責務は「file based routing の割り当て」「SSR」「アセットローダー」に限定する
- `mbtx` / `wasip2` / `wagi` 前提の `.wasm` マウント統合は `mars` との境界を明確にして実装する

## 進捗

- [x] `moon clean` 実施
- [x] ベースライン確認（`moon test --target js src/router`, `moon test --target js src/action`）
- [x] `router` を責務分割（`router_config` / `route_params` / `route_registration` / `route_rendering` / `router_hmr`）
- [x] `register_routes` / `register_server_routes` の config 解決を `resolve_router_config` に統一
- [x] `runtime` を起動境界で分割（`runtime_bootstrap` / `runtime_app_export` / `runtime_env_mount`）
- [x] `runtime` の SSR/Island/Streaming/Static Serving をファイル分割（`runtime` / `runtime_island` / `runtime_streaming` / `runtime_static_serving`）
- [x] `sol` / `mars` で共有しやすい Hot Reload API を `hot_reload` パッケージへ分離（port 解決・script 注入・HTML 注入）
- [x] `sol_routes` の API method 登録を `handle_compiled_api_route` + 共通登録ヘルパに統一
- [x] `routes/file_router.mbt` の catch-all 動的パラメータ処理を実装（値正規化/空値対応）
- [x] `Layout` の扱いを仕様化（`register_routes` は path grouping のみ、合成は `sol_routes`）
- [x] catch-all パラメータの URL エンコード/デコード規約を仕様化（`%2F` を含むケース）
- [x] `register_routes` と `register_sol_routes` の使い分けを README に反映

## 優先タスク

- [x] [P1] `Context` の params 抽出を `mars` 公開 API 経由に統一する  
  対応: `extract_route_params` を `Context::param` ベースに変更し、`c.params?.data` 依存を削除

- [x] [P2] JSON レスポンス送信を共通ファサードに寄せる（`router`/`action` 重複削減）  
  対応: `src/internal/mars_response/mars_response.mbt` を追加し、`router`/`action` から利用

- [x] [P2] ルート登録の重複削減  
  対応: `register_routes_inner` / `register_server_routes_inner` を廃止し、`register_route_tree` + 共通 API 登録ヘルパへ統合

- [x] [P2] `runtime` の起動責務を `mars` adapter 前提へ再編成する  
  対応: `export_runtime_app` / `maybe_start_server` / `with_initialized_fs` へ起動境界を集約

- [x] [P3] wasm hint/manifest の責務整理  
  対応: `generate_mars_adapter_hints` を追加し、`mars` adapter の `manifest_hint` / `binding_hint` を利用して `.sol/wasm/mars-adapter.hints` を出力

- [x] [P2] middleware 実行を `mars.compose` ベースへ統一  
  対応: `middleware.pipeline` を `@mars.compose` ベースへ変更し、`action` / `sol_routes` の独自 middleware ループを削除

## 次の概念整理候補

- [x] [P1] `runtime` の `mars` 重複 API を縮小（`create_app` / `api` / `api_post` / `get_request_path`）  
  対応: `src/runtime.mbt` から重複 API を削除し、CLI 生成コード/E2E 参照を `@mars.Server::new` と `app.get/post` へ移行
- [x] [P2] `source_path` 動的パラメータ形式を `k=v&...` 前提で複数パラメータ対応するか検討  
  対応: `file_router` の `source_path` 生成を主パラメータ + 追加パラメータの `k=v&...` 形式に拡張し、`page_generator` 側の複数クエリ復元テストを追加
- [x] [P3] `docs/` と README のルーティング仕様記述を一本化（重複削減）  
  対応: `docs/routing.md` を単一ソースとして追加し、`README` と既存ルーティング文書を参照ベースに統合
- [x] [P2] middleware 実行時の 500 エラーハンドリングを共通化  
  対応: `@middleware.run_or_500` を追加し、`action` / `sol_routes` のローカル実装を削除して統一
- [x] [P2] 500 JSON エラーレスポンス送信を共通ヘルパへ統一  
  対応: `@mars_response.send_internal_error` を追加し、`action` / `sol_routes` の 500 応答分岐を統一
- [x] [P3] `middleware.to_handler` を段階的縮小（deprecated 化）  
  対応: `to_handler` を `#deprecated` 指定し、公開 API 縮小の移行フェーズを開始

## 追加で潰した項目（2026-02-18）

- [x] [P2] SSR page shell テンプレ処理の重複削減  
  対応: `src/internal/page_shell` を追加し、`runtime` / `router` の document/template 組み立てを統一
- [x] [P2] JavaScript object 生成の重複削減  
  対応: `src/internal/js_any` を追加し、`runtime` / `router` の `json_obj` 実装を統一
- [x] [P2] `router` 側 HMR 中継層の削除  
  対応: `src/router/router_hmr.mbt` を廃止し、`@hot_reload.with_dev_head_script` へ統一
- [x] [P3] HMR メッセージ型の導入と timestamp overflow 修正  
  対応: `HmrMessage` を追加し、`notify_update` の timestamp を `Double` で送信
- [x] [P3] `just sol` の CLI エントリパス不整合を修正  
  対応: `justfile` の参照先を `_build/js/debug/build/cli/cli.js` に統一
- [x] [P3] deprecated warning の解消  
  対応: `create_app_then` / `serve` の内部実装を分離し、内部呼び出しから deprecated シンボルを除去
- [x] [P3] static css/js 配信ロジックの重複削減  
  対応: `serve_static_text_file` へ統合
- [x] [P2] `mars` ユーザー向け段階移行ガイドを整備  
  対応: `docs/migrate-from-mars.md` を追加し、README から導線を追加

## 次の候補（未着手）

- [x] [P2] `runtime_env_mount` の `get_hmr_script` / `get_hmr_port` を deprecated 化し `@hot_reload` 直接利用へ寄せる  
  対応: `get_port` を `@hot_reload.app_port_from_env` に統一し、`get_hmr_script` / `get_hmr_port` / `set_env` は互換維持のまま deprecated 化
- [x] [P2] `runtime_static_serving` の `text_response` / `js_response` / `static_response` の使用実態を確認し、不要公開 API を縮小する  
  対応: 3 API と `read_file_sync` を deprecated 化し、内部は `read_file_text` に移行して警告なしで互換維持

## 物理削除（breaking）

- [x] [P1] deprecated 公開APIの物理削除  
  対応: `create_app_then` / `serve` / `get_hmr_script` / `get_hmr_port` / `set_env` / `text_response` / `js_response` / `static_response` / `read_file_sync` / `middleware.to_handler` / `get_port` を削除
- [x] [P1] `@sol.App` / `@sol.Ctx` の公開型エイリアスを削除  
  対応: `@mars.Server` / `@mars.Context` 直接利用へ統一し、テンプレートと移行ドキュメントを更新

## 追加で潰した項目（2026-02-19）

- [x] [P3] k6 benchmark mode でデバッグ API 応答を最小化して計測ノイズを削減  
  対応: `SOL_BENCH_MODE=1` 時は `/api/middleware-test` と `/api/test/[...path]` のレスポンスを軽量化

## 次フェーズ（未着手）

- [x] [P1] k6 計測を「複数回実行 + median 採用」に標準化する  
  対応: `just bench-k6` に `runs` 引数を追加し、`bench/k6/summarize-results.js` で中央値を集計

- [x] [P1] route profile と mix profile の差分レポートを自動生成する  
  対応: `bench/k6/compare.js` と `just bench-k6-compare` を追加し、`p95/avg/error/rate` 差分表を出力

- [x] [P2] `SOL_BENCH_MODE` の挙動説明を docs 側にも統一して反映する  
  対応: `docs/benchmarking.md` を単一ソースとして追加し、`README.md` / `bench/k6/README.md` から参照

- [x] [P2] `examples/sol_app` のベンチ用途 API をデバッグ用途 API から分離する  
  対応: `/api/bench/*` 系エンドポイントを追加し、k6 はベンチ専用 API を使用

- [x] [P3] 高負荷時のばらつき切り分け手順を文書化する  
  対応: CPU 固定、ウォームアップ、再計測回数（`runs=5`）とばらつき判定基準を `bench/k6/README.md` / `docs/benchmarking.md` に追加

## レビュー起点の改善（2026-02-19）

- [x] [P2] docs 整合テストを `just` / `ci` に組み込む  
  対応: `test-docs` ターゲットを追加し、`ci` / `test-all` と `.github/workflows/check.yaml` に組み込み（`docs-index` / `docs-chapters` / `docs-ci`）

- [x] [P3] ルート README の Quick Start を scaffold 前提（`pnpm install` / `pnpm dev`）に統一する  
  対応: Playground と Quick Start の依存導入/起動コマンドを `pnpm` ベースへ統一

- [x] [P2] GitHub Actions の build 出力パス（`_build`）とローカル開発（`target`）の整合を確認し統一する  
  対応: `justfile` / `check.yaml` / `README` / `src/cli` / `src/ssg` / `examples/sol_auth` の参照を `_build` 基準に統一し、`target` は互換 cleanup のみ維持

- [x] [P1] `sol clean --all` と `sol dev --clean` で `target -> _build` 環境の cleanup 順序を修正する  
  対応: legacy `target` を先に削除してから `_build` を削除する順序に統一し、壊れ symlink 残留リスクを除去

- [x] [P2] `register_sol_routes` の streaming 出力を実レスポンスとして検証する  
  対応: `sol_routes_wbtest` に stream を `Response.text()` で読むテストを追加し、header/body/footer 連結を保証

- [x] [P1] streaming 応答で `set_header` 済みヘッダーが欠落する不整合を修正する  
  対応: `ffi_set_streaming_response` で `ctx.response_headers` を引き継ぎ、`X-Sol-Cache-Strategy` などを保持

- [x] [P2] `register_sol_routes` の streaming/fragment/ISR 分岐を黒箱で固定化する  
  対応: `app.to_handler` 経由テストを追加し、full-page は streaming、fragment/ISR は non-streaming を検証

- [x] [P1] `mars.to_handler` の `reschedule` 参照欠落を `sol` 側互換レイヤで吸収する  
  対応: `register_routes` / `register_server_routes` / `register_sol_routes` で互換シンボルを初期化し、wbtest 側 polyfill を削除

- [x] [P2] streaming SSR で `root_template` を利用する
  対応: `__LUNA_MAIN__` で template を header/footer に分割して streaming へ適用、placeholder 不在時は built-in shell にフォールバック

## Type-Safe API Migration (2026-03)

Goal: Replace string-based APIs with type-safe alternatives via `sol generate` code generation.

### A. Immediate (leverages existing `sol generate` infrastructure)

#### A1. `wc_island` → ComponentRef-based (Low effort)

Current: `wc_island("my-counter", "/static/my_counter.js", styles, state, children)`
Target: `@sol.island(@types.wc_counter(props), children)` — already works via `cref.wc == true`

- [x] `island()` already supports `wc: true` through ComponentRef
- [x] Rename `wc_island` → `wc_island_raw`, `wc_island_with` → `wc_island_with_raw`
- [x] Update docs referencing `wc_island`

#### A2. Route params: `get_param("slug")` → typed accessor (Medium effort)

Current: `props.get_param("slug")` — typo-prone, returns `String?`
Target: typed param struct generated from route path patterns

- [x] Extract param names from route path patterns (`:slug`, `[id]`, `[...path]`, `[[...slug]]`)
- [x] Generate `pub let param_slug : String = "slug"` constants via `sol generate`
- [ ] Design typed params approach (per-route struct vs shared typed map)
- [ ] Keep `get_param(String)` as escape hatch

#### A3. Action IDs → ActionRef (Medium effort)

Current: `ActionDef::new("create-user", handler)` / `registry.get("create-user")`
Target: `ActionRef` type with generated factory functions (like ComponentRef)

- [x] Define `ActionRef` type with `id`, `base_path` fields and `url()` method
- [x] Add `ActionRef::to_def(handler)` → `ActionDef`
- [x] Add `ActionRegistry::register_ref(aref, handler)`
- [x] Add `invoke_action_ref(aref, payload, callback)`
- [x] Add `create_action_invoker_ref(aref)`
- [x] Add `ActionFormConfig::from_ref(aref)`
- [x] Extend `sol generate` to collect action definitions and generate factory functions

### B. Medium-term (requires design decisions)

#### B1. Route paths → typed route builder

Current: `page("/blog/:slug", handler)` — string path patterns
Target: `page(@routes.blog_slug, handler)` — generated route constants

- [x] Generate `pub let route_blog_slug : String = "/blog/:slug"` constants via `sol generate`
- [x] Parse route paths from `routes.mbt` at Step 1.5 (early text scan)
- [ ] Decide if file-based routing should auto-generate typed routes
- [ ] Integrate with A2 (typed params derived from route paths)

#### B2. `invoke_action(url, ...)` → typed client action

Current: `invoke_action("/_action/create-user", payload, callback)`
Target: `invoke_action_ref(@actions.create_user(), payload, callback)`

- [x] Add `invoke_action_ref` accepting `ActionRef`
- [x] Add `create_action_invoker_ref(ActionRef)`
- [x] Add `ActionFormConfig::from_ref(ActionRef)` constructor
- [x] Generate ActionRef factories via `sol generate`

#### B3. Locale codes → Locale enum

Current: `build_localized_url(path, "ja", i18n)` — string locale codes
Target: `build_localized_url(path, @locale.Ja, i18n)` — generated enum

- [x] Generate `pub enum Locale { En; Ja }` with `code()` and `label()` methods via `sol generate`
- [ ] Keep String overloads as `_raw` suffix

### C. Low priority (intentionally string-based)

- `island_raw()` / `island_with_raw()` — low-level escape hatch
- CORS methods/headers — standard HTTP patterns
- File path utilities — build tool internals
- `IslandConfig` builder — superseded by ComponentRef

### Implementation Order

1. A1 (wc_island rename) — minimal, consistent with island refactor
2. A2 (typed route params) — high user impact
3. A3 (ActionRef) — follows ComponentRef pattern
4. B1-B3 — after A items validated
