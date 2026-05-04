# View Transition API まとめ

## 概要

ページ遷移やDOM更新時にスムーズなアニメーションを実現するAPI。MPA・SPA両対応。

## MPA（クロスドキュメント遷移）

### 有効化

```css
@view-transition {
  navigation: auto;
}
```

両方のページにこのCSSを記述するだけで、同一オリジン間の遷移が自動でアニメーション化される。

### イベント

```javascript
// 離脱時（移動元ページ）
window.addEventListener('pageswap', (event) => {
  if (event.viewTransition) {
    // カスタマイズ可能
  }
});

// 到着時（移動先ページ）
window.addEventListener('pagereveal', (event) => {
  if (event.viewTransition) {
    // カスタマイズ可能
  }
});
```

### ブラウザサポート

- Chrome 126+
- Firefox 144+
- Safari 18+
- Edge 126+

## SPA（同一ドキュメント内遷移）

### 基本的な使い方

```javascript
document.startViewTransition(() => {
  // DOM更新処理
  updateDOM();
});
```

### Promise による制御

```javascript
const transition = document.startViewTransition(() => {
  updateDOM();
});

transition.ready.then(() => {
  // アニメーション開始時
});

transition.finished.then(() => {
  // アニメーション完了時
});

// スキップも可能
transition.skipTransition();
```

### ブラウザサポート

- Chrome 111+, Edge 111+, Safari 18+, Firefox 144+

## CSS による制御

### 個別要素のトランジション

```css
.card {
  view-transition-name: main-card;
}
```

同じ `view-transition-name` を持つ要素同士がモーフィングする。

### 擬似要素によるアニメーション制御

```
::view-transition
└── ::view-transition-group(name)
    └── ::view-transition-image-pair(name)
        ├── ::view-transition-old(name)  /* 遷移前の状態 */
        └── ::view-transition-new(name)  /* 遷移後の状態 */
```

### アニメーションのカスタマイズ

```css
/* 古い状態のアニメーション */
::view-transition-old(main-card) {
  animation: fade-out 0.3s ease-out;
}

/* 新しい状態のアニメーション */
::view-transition-new(main-card) {
  animation: fade-in 0.3s ease-out;
}

/* グループ全体の制御 */
::view-transition-group(main-card) {
  animation-duration: 0.4s;
}
```

### シーケンシャルアニメーション（重なり防止）

```css
::view-transition-old(content) {
  animation: fade-out 0.15s ease-out forwards;
}

::view-transition-new(content) {
  animation: fade-in 0.15s ease-out 0.15s forwards; /* delay で遅延 */
  opacity: 0;
}

::view-transition-image-pair(content) {
  isolation: auto; /* 重なり防止 */
}
```

### トランジション無効化

`view-transition-name` を付けなければ、その要素は `root` の一部としてクロスフェードされる。

## MPA vs SPA 比較

| 項目 | MPA | SPA |
|------|-----|-----|
| 有効化 | CSS `@view-transition` | JS `startViewTransition()` |
| DOM | 新規ドキュメント読み込み | 既存DOMを更新 |
| イベント | `pageswap` / `pagereveal` | Promise (`ready` / `finished`) |
| 状態管理 | なし（各ページ独立） | 必要 |
| サポート | Chrome 126+, Firefox 144+, Safari 18+ | Chrome 111+, Firefox 144+, Safari 18+ |

## Luna フレームワークへの示唆

### MPA優先の場合

- `@view-transition { navigation: auto; }` をデフォルトで有効化
- Island ごとに `view-transition-name` を自動付与
- `pagereveal` で Hydration をトリガー可能
- BF Cache との相性を検証する必要あり

### SPA/Hybrid の場合

- クライアントルーターで `startViewTransition()` をラップ
- Island 間の状態を保持しながら遷移
- プリフェッチと組み合わせ可能

### 推奨アプローチ

1. **まず MPA で実装** - シンプルで堅牢
2. **必要に応じて SPA 部分を追加** - 特定のインタラクションのみ
3. **Island 単位での `view-transition-name`** - コンポーネントごとの遷移制御

## 高度な機能

### view-transition-types（方向別アニメーション）

ナビゲーション方向に応じて異なるアニメーションを適用:

```javascript
// pageswap または pagereveal で設定
window.addEventListener('pagereveal', (event) => {
  if (event.viewTransition) {
    const fromIndex = getPageIndex(navigation.activation?.from?.url);
    const toIndex = getPageIndex(navigation.activation?.entry?.url);

    if (toIndex > fromIndex) {
      event.viewTransition.types.add('forwards');
    } else {
      event.viewTransition.types.add('backwards');
    }
  }
});
```

```css
/* CSS で方向に応じたアニメーションを定義 */
html:active-view-transition-type(forwards) {
  &::view-transition-old(root) {
    animation: slide-out-to-left 0.3s ease-out;
  }
  &::view-transition-new(root) {
    animation: slide-in-from-right 0.3s ease-out;
  }
}

html:active-view-transition-type(backwards) {
  &::view-transition-old(root) {
    animation: slide-out-to-right 0.3s ease-out;
  }
  &::view-transition-new(root) {
    animation: slide-in-from-left 0.3s ease-out;
  }
}
```

### NavigationActivation

`navigation.activation` で遷移元・遷移先の情報を取得:

```javascript
window.addEventListener('pagereveal', (event) => {
  const activation = navigation.activation;
  console.log('From:', activation?.from?.url);
  console.log('To:', activation?.entry?.url);
  console.log('Type:', activation?.navigationType); // push, replace, reload, traverse
});
```

### skipTransition()

条件付きでトランジションをスキップ:

```javascript
window.addEventListener('pagereveal', (event) => {
  if (event.viewTransition) {
    if (shouldSkipTransition()) {
      event.viewTransition.skipTransition();
    }
  }
});
```

### sessionStorage での状態渡し

ページ間でコンテキストを共有:

```javascript
// pageswap (離脱時)
window.addEventListener('pageswap', (event) => {
  sessionStorage.setItem('clickedElement', elementId);
});

// pagereveal (到着時)
window.addEventListener('pagereveal', (event) => {
  const context = sessionStorage.getItem('clickedElement');
  // context を使って動的に view-transition-name を設定など
});
```

### render-blocking

特定要素の読み込みを待機してからトランジション:

```html
<link rel="expect" blocking="render" href="#main-content">
```

注意: Core Web Vitals への影響を測定してから使用すること。

## Sol 統合設計

### sol.config.json

```json
{
  "islands": ["app/client"],
  "routes": "app/server",
  "output": "app/__gen__",
  "navigation": {
    "mode": "mpa",
    "viewTransition": true,
    "direction": "history"
  }
}
```

### navigation オプション

| キー | 値 | 説明 |
|------|-----|------|
| `mode` | `"mpa"` / `"csr"` | MPA: ブラウザナビゲーション、CSR: fetch + DOM差し替え |
| `viewTransition` | `true` / `false` | View Transition API を使用するか |
| `direction` | `"history"` / `"depth"` / `"manual"` / `"none"` | 遷移方向の判定方法 (default: history) |

### direction オプション詳細

| 値 | 動作 |
|---|---|
| `"history"` | **(default)** ブラウザ履歴のみ。back_forward なら backwards、それ以外は forwards |
| `"depth"` | URL階層で判定。深くなる=forwards、浅くなる=backwards、同階層=辞書順 |
| `"manual"` | 常に forwards。`data-sol-direction="backwards"` 属性でオーバーライド |
| `"none"` | direction を設定しない（デフォルトのクロスフェード） |

### 生成されるファイル

| mode | ファイル | サイズ目安 |
|------|----------|-----------|
| `mpa` | `sol-nav-mpa.js` | ~500B |
| `csr` | `sol-nav.js` | ~2KB |

### MPA モードの動作

1. `@view-transition { navigation: auto; }` はユーザーが CSS に記述
2. `sol-nav-mpa.js` は pageswap/pagereveal で direction を設定
3. `data-sol-prefetch` 属性のリンクをスキャンしてプリフェッチ

### CSR モードの動作

1. `data-sol-link` のクリックをインターセプト
2. `document.startViewTransition()` で DOM 更新をラップ
3. direction に応じて view-transition-types を設定

### 属性

| 属性 | 説明 |
|------|------|
| `data-sol-link` | CSR ナビゲーション対象 |
| `data-sol-prefetch` | プリフェッチ対象（MPA/CSR 共通） |
| `data-sol-direction` | 遷移方向を明示指定（`"forwards"` / `"backwards"`） |

## 参考リンク

- [MDN - View Transition API](https://developer.mozilla.org/ja/docs/Web/API/View_Transition_API)
- [Chrome Developers - View Transitions](https://developer.chrome.com/docs/web-platform/view-transitions)
- [Chrome Developers - Cross-document View Transitions](https://developer.chrome.com/docs/web-platform/view-transitions/cross-document)
- [Can I use - View Transitions](https://caniuse.com/view-transitions)
