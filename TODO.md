これは開発者が次にやりたいことをメモとして残していく場所だから、AIは言われるまで修正しない。

## 🚧 実装中: Unified Progressive Architecture

設計ドキュメント: `docs/internal/unified-progressive-arch.md`

### Phase 1: 型定義 ✅ 完了

| タスク | ファイル | 状態 |
|--------|----------|------|
| RouteManifest 拡張 | `src/core/routes/manifest.mbt` | ✅ |
| ComponentRouteEntry 追加 | `src/core/routes/manifest.mbt` | ✅ |
| ComponentType enum 追加 | `src/core/routes/manifest.mbt` | ✅ |
| StaticPathEntry 追加 | `src/core/routes/manifest.mbt` | ✅ |
| PageConfig.staticParams | `src/core/routes/page_config.mbt` | ✅ |
| PageConfig.component | `src/core/routes/page_config.mbt` | ✅ |
| ComponentConfig 型 | `src/core/routes/page_config.mbt` | ✅ |
| LunaConfig 型 | `src/core/config/config.mbt` | ✅ |
| E2E ハイドレーションテスト | `e2e/sol-app/navigation-hydration.test.ts` | ✅ (10件) |

### Phase 2: ディレクトリスキャナー ✅ 完了

`moon.pkg.json` ディレクトリを検出し、ComponentRoute を生成する。

| タスク | ファイル | 状態 |
|--------|----------|------|
| moon.pkg.json 検出 | `src/core/routes/scanner.mbt` | ✅ |
| client/server 構造判定 | `src/core/routes/scanner.mbt` | ✅ |
| ComponentType 決定ロジック | `src/core/routes/scanner.mbt` | ✅ |
| staticParams → StaticPathEntry 変換 | `src/core/routes/scanner.mbt` | ✅ |
| page.json 継承マージ | `src/core/routes/merge.mbt` | ✅ |
| スキャナーテスト | `src/core/routes/scanner_test.mbt` | ✅ (9件) |

**スキャナーのルール:**
```
counter/                      # moon.pkg.json ディレクトリ
├── moon.pkg.json            # ← これがあればコンポーネント
├── page.json                # ページ設定 (mode, staticParams)
├── client/                  # ← あれば Hydration
└── server/                  # ← あれば SSR
```

| 構造 | ComponentType | 動作 |
|------|--------------|------|
| `client/` + `server/` | SsrComponent | SSR + Hydration |
| `client/` のみ | ClientOnlyComponent | Hydration のみ |
| `server/` のみ | ServerOnlyComponent | SSR のみ |

### Phase 3: クライアントランタイム ✅ 完了

| タスク | ファイル | 状態 |
|--------|----------|------|
| boot/loader.ts (チャンクローダー) | `js/loader/src/boot/loader.ts` | ✅ |
| boot/router.ts (最小ルーター) | `js/loader/src/boot/router.ts` | ✅ |
| boot/index.ts (エントリ) | `js/loader/src/boot/index.ts` | ✅ |
| ChunkManifest 型 | `src/core/routes/client_manifest.mbt` | ✅ |
| manifest.json 生成 | `src/astra/generator/static_render.mbt` | ✅ |

**実装済み機能:**
- `ChunkLoader`: manifest.json ベースのチャンクロード
- `MinimalRouter`: リンクインターセプト、prefetch、History API
- `ChunkManifest`: RouteManifest → クライアント向けマニフェスト変換
- ビルド時に `_luna/manifest.json` を自動生成

### Phase 4: ビルドパイプライン ✅ 完了

| タスク | ファイル | 状態 |
|--------|----------|------|
| Rolldown boot エントリ | `rolldown.config.mjs` | ✅ |
| boot ランタイムコピー | `src/astra/generator/static_render.mbt` | ✅ |
| manifest.json 生成 | `src/astra/generator/static_render.mbt` | ✅ |

### Phase 5: SSR コンポーネント (Astra側) ✅ 完了

| タスク | ファイル | 状態 |
|--------|----------|------|
| Component ContentType 追加 | `src/astra/types.mbt` | ✅ |
| moon.pkg.json ディレクトリ検出 | `src/astra/routes/file_router.mbt` | ✅ |
| page.json パース | `src/astra/routes/file_router.mbt` | ✅ |
| Component ページ生成 | `src/astra/generator/static_render.mbt` | ✅ |

### Phase 6: CFW デプロイ ✅ 完了

| タスク | ファイル | 状態 |
|--------|----------|------|
| DeployTarget enum | `src/astra/types.mbt` | ✅ |
| deploy 設定パース | `src/astra/config.mbt` | ✅ |
| _routes.json 生成 | `src/astra/generator/cloudflare.mbt` | ✅ |
| E2E テスト (Playwright) | `e2e/astra/deploy-target.test.ts` | ✅ (8件) |
| Vitest ルーティングテスト | `tests/cloudflare/routes.test.ts` | ✅ (21件) |

**Note:** `@cloudflare/vitest-pool-workers` は vitest 2.x-3.x 必須。
vitest 4.x 環境では Worker ランタイムなしでルーティングロジックをテスト。
`_worker.js` 生成時に wrangler dev --test または vitest 3.x 別環境を検討。

### Phase 7: 拡張ルーター ✅ 完了

| タスク | ファイル | 状態 |
|--------|----------|------|
| HybridRouter (fetch+swap) | `js/loader/src/router/hybrid.ts` | ✅ |
| SpaRouter (CSR) | `js/loader/src/router/spa.ts` | ✅ |
| ScrollManager | `js/loader/src/router/scroll.ts` | ✅ |
| Rolldown エントリ追加 | `rolldown.config.mjs` | ✅ |
| package.json exports | `js/loader/package.json` | ✅ |

**実装済み機能:**
- `HybridRouter`: Turbo/HTMX スタイルの fetch + swap ナビゲーション
- `SpaRouter`: クライアントサイドレンダリングルーター、動的ルート対応
- `ScrollManager`: スクロール位置の保存・復元、sessionStorage 永続化

**サイズ:**
- `router/hybrid.js`: 4.1KB
- `router/spa.js`: 3.8KB
- `router/scroll.js`: 3.8KB

### Phase 8: Lint & DX ✅ 完了

| タスク | ファイル | 状態 |
|--------|----------|------|
| orphan-client 警告 | `src/astra/cli/lint.mbt` | ✅ |
| orphan-server 通知 | `src/astra/cli/lint.mbt` | ✅ |
| missing-props 警告 | `src/astra/cli/lint.mbt` | ✅ |
| empty-static-params 警告 | `src/astra/cli/lint.mbt` | ✅ |
| page.json JSON Schema | `schemas/page.schema.json` | ✅ |
| astra.json Schema | `schemas/astra.schema.json` | ✅ |

**Lintルール:**
- `orphan-client`: client/ のみで server/ がない (Warning)
- `orphan-server`: server/ のみで client/ がない (Info)
- `missing-props`: client/ があるが props_type 未定義 (Warning)
- `empty-static-params`: 動的ルートで staticParams 未定義 (Warning)

---

## ✅ Unified Progressive Architecture 完了

全8フェーズが完了しました。

---

## TODO

- sol (フルスタック)
  - 高優先
    - [x] キャッチオールルート (`[...slug]`, `[[...slug]]`)
    - [x] ミドルウェア (ROP、Logger、CORS、`.then()` 合成)
    - [x] レイアウト完成 (ネストレイアウト対応)
    - [x] Error Boundary (コンポーネント単位エラー処理)
  - 中優先
    - [x] Server Actions (フォーム送信のサーバー直接処理)
    - [ ] ISR (Incremental Static Regeneration) → Astra統合
    - [ ] データキャッシング (メモ化、SWR)
    - [ ] リクエスト検証 (スキーマバリデーション)
  - 低優先
    - [ ] WebSocket (リアルタイム通信)
    - [ ] ルートグループ `(group)`

- astra (SSG)
  - [ ] preload
  - [x] AI 用 llm.txt の生成
  - [x] sitemap.xml
  - [x] RSS
  - 高優先
    - [ ] 動的ルート (`[id].md`, `[...slug].md`)
    - [ ] 画像最適化 (リサイズ、WebP変換)
    - [ ] MDX サポート (Markdown内コンポーネント)
    - [ ] プラグインシステム (mermaid, math等)
  - 中優先
    - [ ] 検索インデックス生成 (クライアント側全文検索)
    - [ ] JSON-LD (Schema.org 構造化データ)
    - [ ] ページネーション (記事一覧の自動分割)
    - [ ] Robots/Noindex (ページ単位制御)
  - 低優先
    - [ ] ディスクキャッシュ (永続ビルドキャッシュ)
    - [ ] アセットハッシング (キャッシュバスティング)
    - [ ] デプロイアダプタ (Vercel/Netlify/GitHub Pages)

- sol/astra 共通化
  - 共有可能なパーツ
    - [ ] 動的ルート解析 (`[id]`, `[...slug]` パターンマッチ)
    - [ ] 画像最適化パイプライン
    - [ ] sitemap/RSS/llms.txt 生成
    - [ ] ディスクキャッシュ層 (ビルド成果物)
    - [ ] アセットハッシング
  - ISR 実装案
    - Astra の静的生成 + Sol のランタイム再生成を統合
    - `revalidate: number` でページ単位の TTL 設定
    - ビルド時: Astra で静的生成
    - ランタイム: Sol で期限切れ時に再生成
  - 統合のステップ
    1. [ ] src/core/ssg を sol/astra 両方から使う共通層に
    2. [ ] FileSystem trait で静的生成出力を抽象化
    3. [ ] Astra の DocumentTree を Sol でも利用可能に

- luna cli
- [x] vite hot reload plugin
- [ ] todomvc サンプルで JSON を使わない
  - JSON/strconv 依存で +200KB 以上のバンドルサイズ増加
- [ ] インラインCSS の扱いを統一する
- DX
  - sol: 細粒度 HMR (Island単位の差分更新、状態保持)
  - sol: Vite plugin 版 HMR (Vite の HMR API を利用)
  - 今の仕様に合わせて sol new のテンプレ
  ートをアップデート
- Features
  - Critical CSS の抽出
- Internal
  - sol 中間生成ファイルを見直す。特にHydrate
  - Fix moonbitlang/parser for coverage
- v0.1.0
  - v0.1.0 ドキュメントの英語化
- [ ] SSR Stream が機能しているかテスト. 意図的に遅延を入れて体験を確認
- [ ] sol: キャッシュレイヤーの設計
- atlas
  - GitHub
  - 埋め込む
  - Footer
- stella
  - editor
  - inline ssr

## Icebox

- [ ] shiki設定のカスタマイズ
  - sol.config.json の ssg セクションで theme と langs を選択可能にする
  - theme: github-light, github-dark, nord, etc.
  - langs: json, typescript, rust, mbt, etc.
- [ ] headless ui library
- [ ] shadcn
- [ ] Vite Enviroment Apiに対応? -> やらない。やるにしても最後
- [ ] Inline Editor: dev の時、Monaco を利用して、
- [ ] react-hook-form 相当のものを試作する
  - valibot を使うか、自前のバリデータを作るか
  - standard schema 相当のものを作るといいのでは
- [ ] marimo notebook
- [ ] ink ui
- [ ] sol/test_utils
  - playwright テストをビルトインできないか
- [ ] Async Server Function
  - [ ] src/sol/rpc: capnweb を参考に、リクエストをバッチ化する
  - [ ] Prototype: 内部的に cbor encoder を使う
- [ ] sol build: --prod と --dev に分割して、デバッグ用のビルドを注入する
- [ ] src/integration
  - [ ] src/platform/dom/integrations/react
  - [ ] src/platform/dom/integrations/preact
- [ ] sol validate
  - client/*.mbt の link.js.exports で、Generic パラメータを持1つものを警告する
- [ ] WASM/Native 向け escape 関数の最適化
  - JS は FFI で高速化済み (18-22倍)
  - WASM: SIMD 的なバッチ処理、または extern "wasm" で最適化
  - Native: extern "C" で C 実装を検討
- [ ] Prototype: src/platform/native/server

## Done

- localStorage 保存を独自シリアライズに変更する
- [x] sol multi-runtime support (Node.js, Cloudflare Workers, Deno, Bun)
  - ServerRuntime enum, sol.config.json の runtime フィールド, wrangler で動作確認済み
- [x] client trigger を astro と互換にする (`luna:trigger` → `luna:client-trigger`)
  - https://r4ai.dev/posts/astro_hydration/
- [x] src/core/markdown を mizchi/markdown に移行
  - 外部パッケージ化、5077行削除、FootnoteDefinition/Reference 対応
- [x] 再 export するのに、moonbitlang/parser を使用する
- [x] js/cli を src/eclipse/cli で、CLIをMoonbitで書き直す
- [x] data 属性を修正する
  `luna:*` と `sol:*` にする
- [x] webcomponents SSR を試す
- [x] Sol ServerComponent PageProps
  - Server Route から Client を Route に登録するとき、 Props を取らないといけない
  - Server Component 同士は呼び出せる。
  - `__gen__/types` には Client/Server 共に使える Opaque Type を定義して、それを呼び出す
- [x] src/astra: 静的サイト生成 (src/sol/ssg から再設計)
  - astra build/dev, Shiki syntax highlighting, dark/light toggle, file ordering
- virtual package を導入してクロスプラットフォーム化の基盤を作る
  - https://www.moonbitlang.com/blog/virtual-package
  - => 厳しい
  - [x] mizchi/luna から mizchi/luna のコアAPIを再 export
- [ ] Prototype: ViewTransition
  - [x] BF Cache 最適化
  - [x] MPA Mode
  - [x] sol generate で `.sol/client/exports.mbt` を削除して直接 moon.pkg.json の link を更新する
- [x] preload 挿入

-----

## UserReview

ユーザー視点で優先度が高いもの：

### 最優先（開発体験に直結）

- [x] sol: hot reload (基本実装) - ページ全体リロード、client_auto_exports: false で高速化
- [ ] sol: 細粒度 HMR - Island単位の差分更新、状態保持
- [ ] v0.1.0 ドキュメントの英語化 - 海外ユーザーの参入障壁

### 高優先（実用性向上）
- [x] src/astra で静的サイト生成に対応 - ブログ/静的サイトの需要 ✓実装済み
- [x] client trigger を astro と互換にする - 学習コスト低減 ✓実装済み (`luna:client-trigger`)
- [ ] ViewTransition - モダンなページ遷移UX

### 中優先（機能拡充）
- [x] src/platform/dom/portal - モーダル等の実装に必須 ✓実装済み

## ImplementerReview

内部実装者視点での優先度：

### アーキテクチャ決定（早期に確定すべき）
- [ ] ViewTransition - MPA vs CSR の設計判断に直結
  - MPA優先なら: SSR Stream、BF Cache最適化が重要
  - CSR優先なら: クライアントルーター強化、プリフェッチ
  - **先にプロトタイプして、どこまでMPAでカバーできるか確認すべき**
- [ ] virtual package - クロスプラットフォーム対応の基盤。後から入れると既存コードに影響大
- [ ] sol 中間生成ファイルを見直す - `.sol/` の構造が固まらないとhot reload実装にも影響

### 技術的な依存関係
- [x] sol generate で moon.pkg.json の link を直接更新 → 中間ファイル見直しの一部
- [x] hot reload (基本実装) → WebSocket通知、ページリロード
- [x] _dyn のDSLをどうするか:
- [ ] 細粒度 HMR → Island差分更新、rolldown watch mode

### 後回しでよい
- ~~SSG (src/astra)~~ ✓実装済み (astra build/dev, Shiki, dark/light toggle, file ordering)
- ~~portal~~ ✓実装済み
- ~~Astro互換trigger~~ ✓実装済み (`luna:client-trigger`)

### 推奨順序
1. ViewTransition プロトタイプ → MPA/CSR比重を決定
2. virtual package 導入 → プラットフォーム抽象化
3. sol 中間ファイル見直し → 生成構造の確定
4. ~~hot reload~~ ✓基本実装済み (WebSocket、ページリロード)
5. 細粒度 HMR → Island差分更新、状態保持
