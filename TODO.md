これは開発者が次にやりたいことをメモとして残していく場所だから、AIは言われるまで修正しない。

完了したタスクは `docs/internal/done/` に移動済み。

全体的にサブカラーを使い分けるようにする。


## TODO

### Luna UI

- webcomponents 生成パターンを埋め込み
- [x] Scaffold CLI を提供する
  - [x] `npx @luna_ui/luna new myapp` (TSX)
  - [x] `npx @luna_ui/luna new myapp --mbt` (MoonBit)
- AI に読ませるための luna skills(js/mbt)を作成する

### Astra (SSG)

**高優先**
- [x] 動的ルート (`_id_.md`, `___all___.md`) - MoonBitモジュールパス互換
- [x] Robots/Noindex (ページ単位制御)
- [ ] astra/components - Luna再利用可能コンポーネント集
  - 現在のドキュメントサイト前提から、ブログ・LP等の複数レイアウト対応へ
  - Header, Footer, Sidebar, Card, Hero, CTA 等の汎用コンポーネント
  - テーマ切り替え可能な設計 (CSS変数ベース)

**中優先**
- [ ] static_render.mbt リファクタ (インラインスクリプト分離)
- [x] MDX サポート (mizchi/markdown の mdx 機能を利用)
- [ ] スケルトン生成ヘルパ (一回レンダリングして width/height を抽出、CLS対策)
- [ ] 画像最適化 (リサイズ、WebP変換)
- [ ] 検索インデックス生成 (クライアント側全文検索)
- [ ] JSON-LD (Schema.org 構造化データ)
- [ ] ページネーション (記事一覧の自動分割)
- [ ] プラグインシステム (mermaid, math等)

**低優先**
- [x] ブログテンプレート → `examples/astra_blog/`
  - Frontmatterにブログ用フィールド追加 (date, author, tags, draft)
- [x] ディスクキャッシュ (永続ビルドキャッシュ) → `src/core/cache/`, `.astra-cache/`
- [x] アセットハッシング (キャッシュバスティング) → rolldown対応済み
- [x] デプロイアダプタ → [設計書](docs/internal/deploy-adapters-design.md)
  - [x] Cloudflare Pages (`_routes.json`)
  - [x] GitHub Pages (`.nojekyll`, `CNAME`)
  - [x] Vercel (`vercel.json`)
  - [x] Netlify (`_headers`, `_redirects`)
  - [x] Deno Deploy (静的サイトは設定不要)

### Sol (フルスタック)

**中優先**
- [x] ISR (Incremental Static Regeneration) → Astra統合
  - [x] ISRManifest / ISRPageEntry を core/isr に共有化
  - [x] SWRキャッシュ実装 (stale-while-revalidate)
  - [x] SQLite例: `examples/sol_sqlite/`
- [ ] データキャッシング (メモ化、SWR)
- [ ] リクエスト検証 (スキーマバリデーション)

**低優先**
- [ ] WebSocket (リアルタイム通信)

### Sol/Astra 共通化

**完了**
- [x] ISR型共有 (`src/core/isr/` - ISRManifest, ISRPageEntry, CacheEntry)
- [x] ルートパターンユーティリティ (`src/core/routes/pattern_utils.mbt`)
  - extract_url_pattern, parse_bracket_param, normalize_url_path
- [x] 動的ルート解析 (`_id_`, `___all___` パターンマッチ) → core/routes
- [x] sitemap/RSS/llms.txt 生成 → `src/core/ssg/generators.mbt`
- [x] DocumentTree を Sol でも利用可能に
  - `src/core/ssg/tree_builder.mbt` - 汎用ビルダー
  - `@ssg.build_tree_from_entries()` で Sol から構築可能

**未完了**
- [ ] 画像最適化パイプライン

**完了（追加）**
- [x] ディスクキャッシュ層 → `src/core/cache/`
  - `DiskCache[F]` - FileSystem trait を使った汎用キャッシュ
  - `hash.mbt` - FNV-1a ハッシュ関数
  - Astra CacheManager が core/cache を使用
- [x] アセットハッシング（部分的）
  - ローダーは `hashedPath` 対応済み
  - rolldown で `[hash]` 指定可能
  - 現状はハッシュなし設定（必要時に有効化）

### Luna UI / DX

- [ ] todomvc サンプルで JSON を使わない
  - JSON/strconv 依存で +200KB 以上のバンドルサイズ増加
- [ ] インラインCSS の扱いを統一する
- [ ] 細粒度 HMR (Island単位の差分更新、状態保持)
- [ ] Vite plugin 版 HMR (Vite の HMR API を利用)
- [ ] sol new のテンプレートをアップデート
- [ ] Critical CSS の抽出
- [ ] sol 中間生成ファイルを見直す (特にHydrate)
- [ ] Fix moonbitlang/parser for coverage
- [ ] SSR Stream が機能しているかテスト (意図的に遅延を入れて体験を確認)
- [ ] sol: キャッシュレイヤーの設計

### ドキュメント

- [ ] v0.1.0 ドキュメントの英語化

### Stella

- [ ] editor
- [ ] inline ssr

---

## Icebox

優先度低め、または検討中のタスク。

- [ ] shiki設定のカスタマイズ (theme, langs 選択)
- [ ] headless ui library
- [ ] shadcn
- [ ] Vite Environment API対応 (やらない可能性高)
- [ ] Inline Editor: dev の時、Monaco を利用
- [ ] react-hook-form 相当のものを試作 (valibot, standard schema)
- [ ] marimo notebook
- [ ] ink ui
- [ ] sol/test_utils (playwright テストをビルトイン)
- [ ] Async Server Function (capnweb参考、cbor encoder)
- [ ] sol build: --prod と --dev に分割
- [ ] src/integration (react, preact)
- [ ] sol validate (Generic パラメータ警告)
- [ ] WASM/Native 向け escape 関数の最適化
- [ ] Prototype: src/platform/native/server
