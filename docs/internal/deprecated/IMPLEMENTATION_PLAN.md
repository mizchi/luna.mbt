# Luna Framework 実装計画

## 概要

LunaはMoonBitで実装されたIsland Architectureベースの軽量UIフレームワーク。
Preactの軽量ランタイム + Qwikのresumability + Solidのシグナルを組み合わせ、最小限のクライアントバンドルサイズを目指す。

## 設計原則

### 1. クライアントバンドルサイズ最優先
- 軽量ランタイム（Signals + 最小限のDOM操作）
- SSRによる事前レンダリングで初期負荷を削減
- Island単位での遅延ロード

### 2. MoonBitクロスコンパイル活用
- 同一コードからJS/Native/WASM出力
- SSR/Hydrationで同一実装による振る舞い保証
- プロトタイプはJS、将来的にNative対応

### 3. 明示的なアーキテクチャ
- ディレクトリ規約による client/server 分離
- `components/client/` - クライアントコンポーネント
- `components/server/` - サーバーコンポーネント（データローダー含む）
- 静的解析なし、シンプルなランタイム

### 4. デプロイ形態
- SSG: 静的サイト生成
- SSR: Cloudflare Workers等でのエッジSSR
- Embedding: サードパーティ埋め込み用ウィジェット

## 命名規約

### 属性プレフィックス（ln:統一）
- `ln:id` - コンポーネントID
- `ln:url` - Hydration用モジュールURL
- `ln:trigger` - Hydrationトリガー（load, idle, visible, media）
- `ln:state` - シリアライズされた状態

### MoonBit名前空間
- `mizchi/luna` - コアモジュール
- `mizchi/luna/element` - HTML要素
- `mizchi/luna/ssr` - SSR
- `mizchi/luna/embedding` - 埋め込みモード
- `mizchi/luna/js/dom` - DOM操作

### NPMパッケージ
- `@luna_ui/luna` - コアランタイム
- `@luna_ui/luna-loader` - Islandローダー

---

## Phase 1: 名前空間移行 ✅

- [x] moon.mod.json 変更 (`mizchi/ui` → `mizchi/luna`)
- [x] 全moon.pkg.json 変更 (20ファイル)
- [x] ソースコード変更 (`@ui.` → `@luna.`)
- [x] NPMパッケージ名変更
  - [x] `@mizchi/ui` → `@luna_ui/luna`
  - [x] `@mizchi/ui-loader` → `@luna_ui/luna-loader`
- [x] tsconfig.json 更新 (jsxImportSource, paths)
- [x] `moon check` 通過確認

---

## Phase 2: ローダー属性の統一 ✅

### ln:* 属性への移行

`ln:*` 形式で統一済み。

**HTML出力例**
```html
<div ln:id="counter-1"
     ln:url="/components/counter.js"
     ln:trigger="visible"
     ln:state='{"count":0}'>
  <span>0</span>
  <button>+</button>
</div>
```

- [x] `src/embedding/html_builder.mbt` - ln:* 属性出力
- [x] `js/loader/kg-loader-v1.js` - ln:* 属性読み取り
- [x] E2Eテストで ln:* 使用

---

## Phase 3: Island Architecture強化

### 3.1 Preloadタグ注入
- [ ] SSR時のコンポーネントURL収集
- [ ] `<link rel="modulepreload">` 生成
- [ ] E2Eテスト追加

SSR時にIslandコンポーネントの `<link rel="modulepreload">` を自動挿入。

```html
<head>
  <link rel="modulepreload" href="/components/counter.js">
  <link rel="modulepreload" href="/components/todo.js">
</head>
```

**実装箇所**
- `src/ssr/render.mbt` - Preloadタグ収集
- `src/js/ssr/stream_render.mbt` - ストリーミング対応

### 3.2 トリガータイプ拡張

| トリガー | 説明 | 実装状況 |
|---------|------|---------|
| `load` | ページロード時に即座にhydrate | ✅ 実装済み |
| `idle` | requestIdleCallback時にhydrate | ✅ 実装済み |
| `visible` | IntersectionObserver検知時 | ✅ 実装済み |
| `media` | メディアクエリマッチ時 | ✅ 実装済み |
| `interaction` | ユーザー操作時（新規） | ⬜ 未実装 |

- [ ] `interaction` トリガー実装
- [ ] `hover` トリガー実装（検討）

### 3.3 ディレクトリ規約

```
src/
├── components/
│   ├── client/           # クライアントコンポーネント
│   │   ├── Counter.mbt
│   │   └── TodoList.mbt
│   └── server/           # サーバーコンポーネント
│       ├── DataLoader.mbt
│       └── Layout.mbt
```

- [ ] ディレクトリ規約のドキュメント整備
- [ ] サンプルプロジェクト構造作成

---

## Phase 4: Embedding Mode

### 4.1 基本機能
- [x] SSR結果をスタンドアロンHTMLとして出力
- [x] 状態のJSON安全シリアライズ（XSS対策済み）
- [ ] CORSヘッダー設定ドキュメント

### 4.2 WebComponents対応
```javascript
// 自動生成されるWebComponent
class KgCounter extends HTMLElement {
  connectedCallback() {
    luna.hydrate(this, this.getAttribute('ln:state'));
  }
}
customElements.define('kg-counter', KgCounter);
```

- [ ] WebComponentsラッパー実装
- [ ] `js/loader/` にWebComponentsローダー追加
- [ ] E2Eテスト追加

---

## Phase 5: フルスタック統合 (将来TODO)

> **Note**: このフェーズは将来の拡張として保留。現時点ではPhase 3-4に集中する。

### 5.1 Vite Environmental API
- [ ] Environmental API調査
- [ ] 基本プラグイン実装
- [ ] 開発サーバーでのHMR対応
- [ ] ビルド時のIsland抽出

### 5.2 Server Functions
ディレクトリ規約による暗黙的なサーバー関数。

```
components/
└── server/
    └── api.mbt  # 自動的にサーバー専用としてバンドル
```

- [ ] サーバー関数の基本設計
- [ ] ビルド時の分離処理

### 5.3 Native/WASM対応（将来）
- [ ] MoonBitのNative出力でスタンドアロンSSRサーバー
- [ ] 依存なしの単一バイナリデプロイ
- [ ] クロスターゲット対応Any型ライブラリ (see: [next-xany.md](./next-xany.md))

---

## テスト戦略

### ユニットテスト (MoonBit)
```bash
moon test --target js
```
- [x] Signals, Effects
- [x] VDOM差分計算
- [x] SSRレンダリング
- [x] 状態シリアライズ

### ブラウザテスト (Vitest Browser Mode)
```bash
pnpm test:browser
```
- [x] DOM操作
- [x] Hydration
- [x] イベントハンドリング

### E2Eテスト (Playwright)
```bash
pnpm test:e2e
```
- [x] SSR → Hydration フロー
- [x] Island遅延ロード (loader)
- [ ] WebComponents

---

## 参考リンク

- Qwik: https://qwik.dev/
- Preact Signals: https://preactjs.com/guide/v10/signals/
- SolidJS: https://www.solidjs.com/
- Vite Environmental API: https://vite.dev/guide/api-environment
- MoonBit: https://www.moonbitlang.com/
