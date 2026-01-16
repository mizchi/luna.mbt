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
