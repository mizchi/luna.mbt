# Web Components SSR 実験

Declarative Shadow DOM を使った Web Components の SSR 実験と、フレームワーク設計の検討。

## 実験結果

### 1. Declarative Shadow DOM

`<template shadowrootmode="open">` を使うことで、JavaScript なしで Shadow DOM を宣言できる。

```html
<my-counter data-state='{"count":5}'>
  <template shadowrootmode="open">
    <style>:host { display: block; }</style>
    <div>Count: 5</div>
  </template>
</my-counter>
```

- ブラウザが HTML パース時に自動的に Shadow DOM を構築
- JS ロード前からコンテンツが表示される（FOUC なし）
- Hydration で `this.shadowRoot` が既に存在するため、イベント接続のみで済む

### 2. 入れ子コンポーネント

入れ子の Web Components も SSR 可能。各コンポーネントが独自の `<template shadowrootmode>` を持つ。

```html
<app-root>
  <template shadowrootmode="open">
    <app-child>
      <template shadowrootmode="open">
        ...
      </template>
    </app-child>
  </template>
</app-root>
```

Hydration 順序は内側から外側（子 → 親）。

### 3. CSS 共有パターン

| 戦略 | HTTP | ブロッキング | 重複 | 外部配信 | メモリ |
|------|------|-------------|------|---------|--------|
| inline | 0 | なし | あり | 最適 | 低 |
| link | 1 (cache) | あり | なし | 要設定 | 中 |
| link-preload | 1 (並列) | 軽減 | なし | 不可 | 中 |
| adoptable | 0 | Hydration時 | なし | JS必須 | 高 |

## 意思決定

### CSS 配信戦略

**デフォルト: `link-preload`**（フレームワーク内 SSR）

- `<head>` で CSS を preload し、Shadow DOM 内で参照
- 並列ロードによりブロッキングを軽減
- ブラウザキャッシュが効く
- 同一 CSS の解析は各 Shadow DOM で行われるが、HTTP リクエストは 1 回

**外部配信ビルド: `inline`**

- CSS をコンポーネント内にインライン化
- 単一 HTML で完結（外部依存なし）
- ポータビリティ重視
- 複数コンポーネントで CSS が重複するが、外部配信では許容

### オプション設計

```js
const renderer = createSSRRenderer({
  // 'inline' | 'link' | 'link-preload' | 'adoptable'
  cssStrategy: 'link-preload',
  baseUrl: '/assets/',
});

// フレームワーク内 SSR
const html = renderer.renderToString(Counter, { count: 5 });
const preloads = renderer.getPreloadTags();

// 外部配信ビルド時
const embedRenderer = createSSRRenderer({ cssStrategy: 'inline' });
const embedHtml = embedRenderer.renderToString(Counter, { count: 5 });
```

### 選定理由

```
┌─────────────────────────────────────────────────────────────────┐
│ link-preload を採用する理由                                      │
├─────────────────────────────────────────────────────────────────┤
│ 1. パフォーマンス                                                │
│    - preload により CSS ロードが HTML パースと並列化             │
│    - Critical Rendering Path への影響を最小化                   │
│                                                                 │
│ 2. キャッシュ効率                                                │
│    - 同一 CSS ファイルはブラウザキャッシュで再利用               │
│    - ページ遷移時も恩恵を受けられる                              │
│                                                                 │
│ 3. 開発体験                                                      │
│    - CSS ファイルを個別に編集可能                                │
│    - DevTools での確認が容易                                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ 外部配信で inline を採用する理由                                 │
├─────────────────────────────────────────────────────────────────┤
│ 1. ポータビリティ                                                │
│    - 単一 HTML で完結、外部ファイル不要                          │
│    - CORS 設定不要                                               │
│                                                                 │
│ 2. 信頼性                                                        │
│    - CSS ファイルの 404 リスクなし                               │
│    - CDN 障害の影響を受けない                                    │
│                                                                 │
│ 3. 埋め込み先への配慮                                            │
│    - 埋め込み先のページに preload を要求しない                   │
│    - iframe 不要で直接埋め込み可能                               │
└─────────────────────────────────────────────────────────────────┘
```

### adoptable を採用しない理由

- SSR 時にスタイルを適用できない（FOUC の可能性）
- Hydration が必須（JS 無効環境で見た目が崩れる）
- SPA 内での動的コンポーネント生成には有効だが、SSR 主体の設計には不向き

## ファイル構成

```
experiments/webcomponents_ssr/
├── README.md              # このファイル
├── index.html             # 基本的な SSR デモ
├── demo.html              # フレームワーク v1 デモ
├── nested.html            # 入れ子コンポーネント検証
├── adoptable.html         # Adoptable Stylesheets 検証
├── strategies.html        # 4 戦略の比較デモ
├── framework.js           # フレームワーク v1
├── framework-v2.js        # フレームワーク v2 (CSS 戦略選択可能)
├── shared.css             # 共有 CSS サンプル
└── demo-component.css     # link 戦略用 CSS サンプル
```

## 動作確認

```bash
cd experiments/webcomponents_ssr
python3 -m http.server 8080
```

- http://localhost:8080/index.html - 基本デモ
- http://localhost:8080/strategies.html - 戦略比較
- http://localhost:8080/nested.html - 入れ子 + CSS キャッシュ

## 参考

- [Declarative Shadow DOM](https://developer.chrome.com/docs/css-ui/declarative-shadow-dom)
- [Adoptable Stylesheets](https://developer.mozilla.org/en-US/docs/Web/API/CSSStyleSheet)
- [Web Components SSR (Qiita)](https://qiita.com/tronicboy/items/68f2d9ae1c93a9c3f2cb)
