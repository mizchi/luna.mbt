---
title: "Islands: 基本"
---

# Islands の基本

Islands アーキテクチャは部分的なハイドレーションを可能にします - ページのインタラクティブな部分のみが JavaScript をロードします。

## 問題

従来の SPA はページ全体に JavaScript を送信します：

```
┌─────────────────────────────────────┐
│  ヘッダー（静的）     ← JS ロード   │
├─────────────────────────────────────┤
│  記事（静的）         ← JS ロード   │
│                                     │
│  コメント（インタラクティブ）← JS 必要 │
│                                     │
│  フッター（静的）     ← JS ロード   │
└─────────────────────────────────────┘
```

結果：大きなバンドル、遅いロード、無駄なリソース。

## 解決策

Islands はインタラクティブなコンポーネントのみをハイドレート：

```
┌─────────────────────────────────────┐
│  ヘッダー（静的）     ← JS なし     │
├─────────────────────────────────────┤
│  記事（静的）         ← JS なし     │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ コメント Island    ← JS     │    │
│  └─────────────────────────────┘    │
│                                     │
│  フッター（静的）     ← JS なし     │
└─────────────────────────────────────┘
```

結果：最小限の JavaScript、高速ロード、優れた Core Web Vitals。

## Island の作成

### 1. サーバーレンダリングされた HTML

サーバーがハイドレーション属性を持つ Island を Custom Element として出力：

```html
<wc-counter
  luna:wc-url="/static/wc-counter.js"
  luna:wc-state="0"
  luna:wc-trigger="load"
>
  <template shadowrootmode="open">
    <button>Count: 0</button>
  </template>
</wc-counter>
```

> MoonBit でのサーバーサイドレンダリングについては、[MoonBit チュートリアル](/ja/luna/tutorial-moonbit/)を参照してください。

### 2. クライアントサイド（TypeScript）

インタラクティブコンポーネントを作成：

```typescript
// wc-counter.ts
import { createSignal, render } from '@luna_ui/luna';

interface CounterProps {
  initial: number;
}

// wc-loader は luna:wc-url が指すモジュールを動的 import し、
// 既定 export (もしくは名前付き export `hydrate`) を要素と
// パース済み luna:wc-state とともに呼び出します。
export default function hydrate(element: Element, state: CounterProps) {
  const [count, setCount] = createSignal(state.initial);

  render(element, () => (
    <>
      <style>{`:host { display: block; }`}</style>
      <button onClick={() => setCount(c => c + 1)}>
        Count: {count()}
      </button>
    </>
  ));
}
```

### 3. ハイドレーション

1. ページがサーバーレンダリングされた HTML でロード（即座に表示）
2. Luna ローダーが `[luna:wc-url]` 要素を検出
3. トリガーに基づいて `/static/wc-counter.js` をロード
4. JavaScript が引き継ぎ、要素がインタラクティブに

## Island 属性

| 属性 | 目的 |
|-----|------|
| `luna:wc-url` | コンポーネント JavaScript をロードする URL |
| `luna:wc-state` | シリアライズされた props（JSON） |
| `luna:wc-trigger` | いつハイドレートするか |

`customElements.define()` は **不要** です。 loader は `[luna:wc-url]` を持つ要素を直接スキャンするので、 Custom Element として登録していないタグでも動作します。

## 複数の Islands

各 Island は独立しています。典型的なページ構造：

```html
<div>
  <h1>マイページ</h1>

  <!-- 検索 Island - 即座にハイドレート -->
  <wc-search luna:wc-url="/wc-search.js" luna:wc-trigger="load">...</wc-search>

  <!-- 記事 - 純粋な HTML、JS なし -->
  <article>
    <p>静的コンテンツ...</p>
  </article>

  <!-- コメント Island - 表示時にハイドレート -->
  <wc-comments luna:wc-url="/wc-comments.js" luna:wc-trigger="visible">...</wc-comments>

  <!-- フッター - 純粋な HTML -->
  <footer>...</footer>
</div>
```

## 試してみよう

典型的なブログページを考えてください。どの部分を Island にしますか？

<details>
<summary>解答</summary>

```
ブログページ構造：
├── ヘッダー         → 静的（Island なし）
├── ナビゲーション   → 静的（Island なし）
├── 記事             → 静的（Island なし）
├── シェアボタン     → Island（クリック追跡）
├── コメントフォーム → Island（フォーム送信）
├── コメントリスト   → Island（ライブ更新）
├── 関連投稿         → 静的（Island なし）
└── フッター         → 静的（Island なし）

完全なインタラクティビティに必要なのは3つの Island だけ！
```

</details>

## 次へ

[ハイドレーショントリガー →](./islands_triggers) について学ぶ
