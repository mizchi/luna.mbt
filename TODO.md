これは開発者が次にやりたいことをメモとして残していく場所だから、AIは言われるまで修正しない。

完了したタスクは `docs/internal/done/` に移動済み。

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

**中優先**
- [ ] static_render.mbt リファクタ (インラインスクリプト分離)
- [ ] MDX サポート (mizchi/markdown の mdx 機能を利用)
- [ ] 画像最適化 (リサイズ、WebP変換)
- [ ] 検索インデックス生成 (クライアント側全文検索)
- [ ] JSON-LD (Schema.org 構造化データ)
- [ ] ページネーション (記事一覧の自動分割)
- [ ] プラグインシステム (mermaid, math等)

**低優先**
- [ ] ディスクキャッシュ (永続ビルドキャッシュ)
- [ ] アセットハッシング (キャッシュバスティング)
- [ ] デプロイアダプタ (Vercel/Netlify/GitHub Pages)

### Sol (フルスタック)

**中優先**
- [ ] ISR (Incremental Static Regeneration) → Astra統合
- [ ] データキャッシング (メモ化、SWR)
- [ ] リクエスト検証 (スキーマバリデーション)

**低優先**
- [ ] WebSocket (リアルタイム通信)

### Sol/Astra 共通化

**共有可能なパーツ**

- [ ] 動的ルート解析 (`_id_`, `_...slug_` パターンマッチ)
- [ ] 画像最適化パイプライン
- [ ] sitemap/RSS/llms.txt 生成
- [ ] ディスクキャッシュ層 (ビルド成果物)
- [ ] アセットハッシング

**ISR 実装案**
- Astra の静的生成 + Sol のランタイム再生成を統合
- `revalidate: number` でページ単位の TTL 設定
- ビルド時: Astra で静的生成
- ランタイム: Sol で期限切れ時に再生成

**統合のステップ**
1. [ ] src/core/ssg を sol/astra 両方から使う共通層に
2. [ ] FileSystem trait で静的生成出力を抽象化
3. [ ] Astra の DocumentTree を Sol でも利用可能に

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
