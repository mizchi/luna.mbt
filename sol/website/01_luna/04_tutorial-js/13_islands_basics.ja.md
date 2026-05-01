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

サーバーがハイドレーション属性を持つ Island をレンダリング：

```html
<div
  luna:id="counter"
  luna:url="/static/counter.js"
  luna:state="0"
  luna:client-trigger="load"
>
  <button>Count: 0</button>
</div>
```

> MoonBit でのサーバーサイドレンダリングについては、[MoonBit チュートリアル](/ja/luna/tutorial-moonbit/)を参照してください。

### 2. クライアントサイド（TypeScript）

インタラクティブコンポーネントを作成：

```typescript
// counter.ts
import { createSignal, hydrate } from '@luna_ui/luna';

interface CounterProps {
  initial: number;
}

function Counter(props: CounterProps) {
  const [count, setCount] = createSignal(props.initial);

  return (
    <button onClick={() => setCount(c => c + 1)}>
      Count: {count()}
    </button>
  );
}

// ハイドレーションに登録
hydrate("counter", Counter);
```

### 3. ハイドレーション

1. ページがサーバーレンダリングされた HTML でロード（即座に表示）
2. Luna ローダーが `luna:id` 要素を検出
3. トリガーに基づいて `/static/counter.js` をロード
4. JavaScript が引き継ぎ、要素がインタラクティブに

## Island 属性

| 属性 | 目的 |
|-----|------|
| `luna:id` | ハイドレーション用のコンポーネント識別子 |
| `luna:url` | コンポーネント JavaScript をロードする URL |
| `luna:state` | シリアライズされた props（JSON） |
| `luna:client-trigger` | いつハイドレートするか |

## 複数の Islands

各 Island は独立しています。典型的なページ構造：

```html
<div>
  <h1>マイページ</h1>

  <!-- 検索 Island - 即座にハイドレート -->
  <div luna:id="search" luna:client-trigger="load">...</div>

  <!-- 記事 - 純粋な HTML、JS なし -->
  <article>
    <p>静的コンテンツ...</p>
  </article>

  <!-- コメント Island - 表示時にハイドレート -->
  <div luna:id="comments" luna:client-trigger="visible">...</div>

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
