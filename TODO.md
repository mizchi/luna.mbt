これは開発者が次にやりたいことをメモとして残していく場所だから、AIは言われるまで修正しない。

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
