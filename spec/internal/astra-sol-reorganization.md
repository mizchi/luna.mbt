# Astra/Sol 責務再編成

## 完了した作業

### 1. browser_router の移動

```
移動前: src/luna/dom/router/
移動後: src/sol/browser_router/
```

理由: ブラウザルーターは sol のフレームワーク機能であり、luna のコアUI機能ではない。

依存関係:
- `luna/routes` (ルートマッチングのコア型)
- `luna/signal` (リアクティブ状態管理)

### 2. core/isr を sol/isr にマージ

```
削除: src/core/isr/
統合先: src/sol/isr/
```

変更内容:
- `ISRPageEntry` → `ISRPageMeta` に統一（sol/isr/handler.mbt の型を採用）
- `ISRManifest` を `pub(all)` に変更（astra から構築可能に）
- parser.mbt は handler.mbt の `parse_manifest()` と重複のため削除
- utils.mbt は cache.mbt と重複のため削除
- serializer.mbt は sol/isr に移動（astra がビルド時に使用）

astra/isr の変更:
- `@core_isr` → `@sol_isr` に変更
- `ISRPageEntry` → `ISRPageMeta` に変更

### 3. ファイルスキャン機能を sol/routes に抽出

```
新規作成: src/sol/routes/scanner.mbt
新規作成: src/sol/routes/moon.pkg.json
変更: src/astra/routes/file_router.mbt
変更: src/astra/routes/moon.pkg.json
```

変更内容:
- 汎用的なファイルスキャンインフラを `sol/routes` に抽出
- `ScanOptions`, `FileEntry` 構造体を `sol/routes` で定義
- ユーティリティ関数を `sol/routes` に移動:
  - `is_excluded()` - 除外パターンマッチング
  - `join_path()` - パス結合
  - `get_basename()` - ファイル名取得
  - `get_parent_dir()` - 親ディレクトリ取得
  - `get_extension()` - 拡張子取得
  - `is_content_file()` - コンテンツファイル判定
  - `scan_directory()` - ディレクトリスキャン（FileSystem trait使用）
- `astra/routes` は `@sol_routes` をインポートして利用

依存関係:
- `sol/routes` → `core/env` (FileSystem trait)
- `astra/routes` → `sol/routes`, `core/routes` (ParamInfo, extract_param_name)

## 決定事項

### 1. Routes モジュール

**決定: パターン A を採用**
- `luna/routes` をそのまま保持（ターゲット非依存: js, wasm-gc, native）
- ルートマッチングのコア型として維持

### 2. Astra/Sol 間のルーティング統合

**方針:**
- `astra/routes` のファイルスキャン部分を sol の基本機能として移動
- markdown 処理は astra が sol のルート定義に「注入」する形
- `sol/router` は routes 定義にハンドラをアタッチ可能にする

### 3. ISR

**決定: sol/isr を正とし、astra は利用者となる**
- ISR は sol の責務
- astra/isr は sol/isr の型を使用してマニフェストを生成

## 今後の作業

### 優先度: 高
- ~~`astra/routes` のファイルスキャン機能を sol に移動~~ ✅ 完了
- ~~ルート定義への注入メカニズムを設計~~ ✅ 完了
  - `manifest_to_sol_routes()` で RouteManifest → SolRoutes 変換
  - `PageHandlerFactory`, `ApiHandlerFactory` でハンドラ注入
  - `combine_page_factories()`, `combine_api_factories()` でファクトリ合成
  - 詳細は `spec/internal/route-handler-injection.md` 参照

### 優先度: 中
- ~~`core/routes` の整理~~ ✅ 完了
  - `core/routes` を `sol/routes` にマージ
  - `file_scanner.mbt` (汎用スキャン) + `scanner.mbt` (ページスキャン) の構成
  - 全ての `@core_routes` 参照を `@sol_routes` に更新

### 4. core/routes を sol/routes にマージ

```
削除: src/core/routes/
統合先: src/sol/routes/
```

変更内容:
- `RouteManifest`, `RouteEntry`, `StaticRouteEntry`, `DynamicRouteEntry` を sol/routes に移動
- `RenderMode`, `HttpMethod`, `FileType`, `FallbackConfig` を sol/routes に移動
- `PageConfig`, パターンユーティリティを sol/routes に移動
- `file_scanner.mbt` と `scanner.mbt` の重複関数を整理
- 全ての `@core_routes` 参照を `@sol_routes` に更新

影響モジュール:
- sol/router, sol/cli
- astra/routes, astra/isr, astra/cli, astra/generator, astra/builder_pool

### 5. core/cache を astra/cache にマージ

```
削除: src/core/cache/
統合先: src/astra/cache/
```

変更内容:
- `CacheEntry`, `CacheStatus` 型を astra/cache に移動
- `DiskCache` 実装を astra/cache に移動
- FNV-1a ハッシュ関数 (`fnv1a`, `fnv1a_64`, `hash_strings`, `hash_content`) を astra/cache に移動
- `BuildStateProvider` trait と `BuildStateCheck` を astra/cache に移動
- 全ての `@core_cache` 参照を `@astra_cache` に更新

理由: キャッシュ機能は astra (SSG) 固有の機能であり、sol では使用していない。

### 6. core/ssg は共有インフラとして維持

**決定: core/ssg はそのまま保持**

理由:
- `I18nConfig`, `LocaleConfig`, `NavigationConfig` など共有型定義
- sol と astra の両方から参照（11モジュール）
- どちらにも偏らない純粋な型定義
- 移動のコストに対してメリットが少ない

### 7. HMR インフラを sol/hmr に抽出

```
新規作成: src/sol/hmr/
削除: src/sol/cli/hmr_server.mbt (内容を sol/hmr に移動)
削除: src/astra/cli/dev.mbt 内の HmrServer 実装
```

変更内容:
- `sol/hmr/hmr_server.mbt` - 共有 HMR WebSocket サーバー
  - `HmrServer::start(port)` - async でサーバー起動
  - `HmrServer::notify_reload()` - フルリロード通知
  - `HmrServer::notify_update(islands)` - 島別更新通知 (sol用)
  - `HmrServer::notify_error(error)` - エラー通知
  - `HmrServer::broadcast(message)` - 汎用ブロードキャスト
- sol/cli と astra/cli の両方が `@hmr.HmrServer` を使用
- 重複コードを削減

### 8. CLI 共通ユーティリティを sol/cli_common に抽出

```
新規作成: src/sol/cli_common/
削除: src/sol/cli/cli_utils.mbt
削除: src/astra/cli/cli_utils.mbt
```

変更内容:
- `sol/cli_common/utils.mbt` - 共通 CLI ユーティリティ
  - `console_error(msg)` - エラー出力
  - `keep_alive()` - Node.js イベントループ維持
  - `date_now()` - タイムスタンプ取得
- sol/cli と astra/cli の両方が `@cli_common` を使用
- 重複コードを削減

### 9. 設定ファイル探索を sol/cli_common に追加

変更内容:
- `sol/cli_common/utils.mbt` に追加:
  - `find_config(fs, cwd, candidates, default)` - 汎用設定ファイル探索
  - `astra_config_candidates` - Astra 用候補リスト
  - `sol_config_candidates` - Sol 用候補リスト
- astra/cli/build.mbt の `find_config_file_with_fs` を簡略化

探索順序 (Astra):
1. `astra.json` (ルート)
2. `website/astra.json`
3. `docs/astra.json`
4. `sol.config.json` (フォールバック)

### 10. ファイルシステムユーティリティを sol/cli_common に追加

変更内容:
- `sol/cli_common/utils.mbt` に追加:
  - `rm_rf_sync(fs, path)` - ディレクトリ再帰削除
- sol/cli/clean.mbt, dev.mbt, build.mbt で使用

### 11. MIME タイプ検出を sol/cli_common に追加

変更内容:
- `sol/cli_common/utils.mbt` に追加:
  - `get_content_type(file_path)` - ファイル拡張子からMIMEタイプを取得
- astra/cli/dev.mbt から移動
- 静的ファイル配信の開発サーバーで使用

対応フォーマット:
- HTML, CSS, JS, JSON, SVG
- 画像 (PNG, JPG, GIF, ICO)
- フォント (WOFF, WOFF2, TTF)
- その他 (XML, TXT, WASM, Pagefind index)

### 12. 汎用ワーカープールを sol/builder に抽出

```
新規作成: src/sol/builder/
変更: src/astra/builder_pool/
```

変更内容:
- `sol/builder` に汎用ワーカープールインフラを作成:
  - `types.mbt` - PoolConfig, WorkerState, JobResult, IPC messages
  - `pool.mbt` - WorkerPool (ジョブ管理、ワーカー制御)
  - `worker_ipc.mbt` - FFI (on_message, send_message, exit) とヘルパー
- `astra/builder_pool` を sol/builder を使用するように更新:
  - `types.mbt` - WorkerInitData (astra固有)、PageJobResult (ラッパー)
  - `pool.mbt` - run_parallel_build (@builder.WorkerPool を使用)
  - `worker.mbt` - @builder IPC helpers を使用

sol/builder API:
```moonbit
// Pool management
WorkerPool::new(config, init_data_json) -> WorkerPool
WorkerPool::submit_jobs(job_ids)
WorkerPool::wait_all() -> Array[JobResult]
WorkerPool::shutdown()

// Worker IPC (for custom workers)
on_message(callback)
send_message(message)
send_ready()
send_done(result)
send_error(message)
exit(code)
```

## 分析結果（抽出不適切と判断）

### astra_worker

**結論: 現状維持**

`astra_worker` は `is-main: true` のエントリポイント（child_process.fork で別プロセスとして起動）。
`builder_pool` はライブラリ。役割が異なるため分離が必要。

```
astra_worker/main.mbt (10行)
fn main {
  @builder_pool.start_worker()
}
```

### astra/generator

**結論: astra 固有のため抽出不適切**

依存関係: luna, render, astra, markdown, mdx, routes, shiki, assets, tree, adapters, cache, isr, components, ssg (14モジュール)

すべてが `@astra.BuildContext`, `@astra.PageMeta`, `@astra.SsgConfig` に依存。
Markdown処理、レイアウト適用、テンプレート展開は SSG/ドキュメント固有。

```
sol (SSR ランタイム)          astra (SSG ドキュメント)
├── リクエスト処理              ├── Markdown → HTML
├── 動的レンダリング            ├── レイアウト適用
└── サーバー実行                └── 静的ファイル生成
```

### JSON エスケープの重複

`escape_json_string` が複数モジュールで重複:
- `luna/serialize/json.mbt` - public (正規版)
- sol/hmr, sol/isr, astra/cache, astra/builder_pool, astra/generator, astra/adapters - private 重複

統一可能だが、依存関係変更のコストに対してメリットが小さい。

### 優先度: 低（将来検討）
- `sol/cli` と `astra/cli` のさらなる統合 (共通コマンドパーサー等)
- SSR 用 sol/adapters (Node.js, Deno, Cloudflare Workers ランタイム)
- JSON エスケープユーティリティの統一 (`luna/serialize` を使用)
