これは開発者が次にやりたいことをメモとして残していく場所だから、AIは言われるまで修正しない。

完了したタスクは `docs/internal/done/` に移動済み。


### APG Components (`src/x/components`)

WAI-ARIA APG準拠のアクセシブルUIコンポーネント集。

**次フェーズ (フォーム系)**
- [ ] Checkbox - チェックボックス (tri-state対応)
- [ ] Switch - オン/オフスイッチ
- [ ] Slider - 範囲スライダー
- [ ] Spinbutton - 数値入力

**次フェーズ (選択系)**
- [ ] Listbox - 単一/複数選択リスト
- [ ] Combobox - オートコンプリート付き入力
- [ ] Menu / Menubar - ドロップダウンメニュー
- [ ] Select (native) - ネイティブセレクト

**次フェーズ (ナビゲーション系)**
- [ ] Tree View - ツリー構造
- [ ] Breadcrumb - パンくずリスト (簡易版は landmarks に含む)
- [ ] Disclosure - 開閉パネル (Accordion の単体版)
- [ ] Carousel - スライドショー

**将来 (高複雑度)**
- [ ] Grid - インタラクティブテーブル
- [ ] Treegrid - ツリー+グリッド
- [ ] Feed - 無限スクロール
- [ ] Window Splitter - リサイズ可能パネル

**テスト基盤**
- [ ] E2E Tests (Playwright) - キーボードナビゲーション検証
- [ ] VoiceOver/NVDA 実機テスト
- SSR 対応のコンポーネントライブラリ、という概念を作りたい。qwik を参照する。
  - [ ] cloudflare worker の microfrontend service binding
- [ ] CSS DCE in WC
- [ ] CSS Mangling の実行テスト
- [ ] CSS Static Analyzer (`src/luna/css/analyzer`) を別リポジトリに切り出す検討
  - 現状: moonbitlang/parser に依存した MoonBit AST 解析
  - 依存が深くなりすぎないよう、API境界を明確に保つ
- ブラウザで動く playground を作る
- 最小限の CSS Reset 導入
- [x] PageFind https://pagefind.app/
- loader のレビュー・軽量化
- ドキュメントサイト
  - Favicon
  - OGP画像
  - AI用にluna doc コマンドを提供する
- playground の作成
- mermaid
- [ ] Sol SSGの動作対応
- [x] Moonbit 用にDocTestのサンプルを用意する。
- [ ] JSX 用のドキュメントを整理する。
- [x] Shiki の bundle を除外する
- [ ] Sol を TSX でも動くようにする。
- [ ] Playwright Chaos を外に切り出す
- [ ] Luna のバンドルサイズを見直す
- [ ] Luna/Sol. のリポジトリを分割するか検討

## TODO

### Luna UI / DX

- [ ] todomvc サンプルで JSON を使わない
  - JSON/strconv 依存で +200KB 以上のバンドルサイズ増加
- [ ] インラインCSS の扱いを統一する
- [ ] 細粒度 HMR (Island単位の差分更新、状態保持)
- [ ] Vite plugin 版 HMR (Vite の HMR API を利用)
- [ ] Critical CSS の抽出
- [ ] Fix moonbitlang/parser for coverage
- [ ] SSR Stream が機能しているかテスト (意図的に遅延を入れて体験を確認)

### Bugfix (Hydration/Reconcile)

- [ ] Repro: for_each item が Fragment を返すと DOM が残留するケースのテスト追加
- [ ] Fix: for_each/reconcile が Fragment を適切に扱えるように修正
- [ ] Repro: VNode For が Fragment を返すと DOM が残留するケースのテスト追加
- [ ] Fix: VNode For の更新で Fragment を正しく差し替える
- [ ] Repro: Show/For の初期 hydration で子孫の dynamic attr/handler が未バインドになるケース
- [ ] Fix: Show/For の hydrate で子孫の VDynamic/VHandler を正しくバインド
- [ ] Repro: 同名タグ兄弟がある場合に hydration が誤った要素へ進むケース
- [ ] Fix: hydration の要素探索を順序/カーソル方式に変更
- [ ] Repro: ErrorBoundary の reset 後に DOM が復元されないケース
- [ ] Fix: ErrorBoundary reset が DOM に再挿入するよう修正
- [ ] Perf: sol:hk 探索を 캐ッシュ化 (O(1) 参照) し、テストで回帰防止
- [ ] Perf: reconcile_items の O(n^2) を改善 (Map/Hash で参照)
- [ ] Bug: SSR minify_css が文字列リテラルの空白を壊すケース
- [ ] Fix: minify_css の安全性を上げる or 無効化オプション
- [ ] Perf: preload_urls の dedup を O(n^2) から改善

### Refactor candidates (2026-05-15 audit)

直近の 0.22.x 系作業で見えたリファクタ余地。 数字は「impact × cost の優先度」。

- [ ] **#1 sol/astra: version 文字列の 1 const 化** — `sol/src/cmd/sol/main.mbt` の native version, `sol/src/cli/main.mbt::show_version` の JS CLI version, `sol/src/cli/doctor.mbt::SOL_JS_CLI_VERSION` の 3 か所に独立に hardcoded されている。 0.22.3 release で 1 つの bump 漏れ (cli/main.mbt) が CI fail を引き起こした。 解: 1 const に集約、 もしくは build 時に sol/moon.mod.json から生成。
- [ ] **#2 vup script に templates の hardcoded deps 自動同期** — `sol/src/cli/templates.mbt` と `sol/src/scaffold_templates/templates.mbt` の `mizchi/sol`/`mizchi/sol_adapter_*`/`mizchi/luna` の version pin を毎 release 手動で書き換えている。 vup --release の bump 対象に taking。 verify subagent 報告でも指摘済。
- [ ] **#3 astra middleware: dispatch を render_url 経由に統合** — `dispatch(ctx)` と `render_url(url)` で render logic が並立。 dispatch を「render_url を呼んで ctx に書き戻すだけ」 に薄くすれば dedup。
- [ ] **#4 astra/docs/guide/* の「Luna SSG」 文言整理** — README は astra-canonical に直したが、 `astra/docs/guide/index.md` 冒頭「Luna SSG is a static site generator integrated into the Sol CLI.」、 `markdown.md` 冒頭「Luna SSG supports standard Markdown syntax.」 など旧文言が残る。
- [ ] **#5 sol_app / sol_auth example を新 scaffold layout へ** — sol_todo は D8 で揃えた (`app/server/main.mbt` + routes.mbt 同居 + `app/layout/` 別 package)。 sol_app と sol_auth は旧構造 (`app/server/{pages,layout,routes}.mbt`) のまま。 別 PR 候補。
- [ ] **#6 astra middleware の `render_page` 中間層削除** — `middleware.mbt::render_page` は `@render.render_page_html` への 1 段 wrapper。 BuildContext 組み立てを Middleware 側に move して中間層を畳む。 cosmetic だが軽い。
- [ ] **#7 sol/src/cli/dev.mbt の watch dirs hardcoded** — `["src", "app"]` を hardcoded で listen。 sol_docs / astra 系 (`docs/` 配下) を拾えない。 config 化候補。
- [ ] **#8 sol launcher の monorepo dev UX** — `~/.moon/bin/sol doctor` を `sol/examples/*` で打つと delegate fail。 launcher の `delegate_to_project_js_cli` に「workspace root を ascend」 or 「path dep follow」 を追加。 verify subagent 報告。
- [ ] **#9 moon test `-f <file>` filter 不具合** — moon CLI 側の bug or 仕様。 upstream issue 候補。
- [ ] **#10 mnemo token 設定** — `mnemo --server doctor` で bearer_source=none。 chezmoi 経由で `MNEMO_API_TOKEN` を環境に乗せれば agent が retrospective を hosted に保存できる。

優先度: #1 と #2 は即効 (release 周りの再発防止)、 #3-#6 は cleanup、 #7-#9 は調査要、 #10 は環境設定。
