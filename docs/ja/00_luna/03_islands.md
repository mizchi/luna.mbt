---
title: Island Architecture
---

# Island Architecture

Islandは部分的ハイドレーションを実現します。インタラクティブなコンポーネントだけがJavaScriptを読み込みます。

## 問題

従来のSPAはページ全体にJavaScriptを配信:

```
┌─────────────────────────────────────┐
│  ヘッダー (静的)      ← JS読み込み   │
├─────────────────────────────────────┤
│  記事 (静的)         ← JS読み込み   │
│                                     │
│  コメント (動的)     ← JS必要       │
│                                     │
│  フッター (静的)     ← JS読み込み   │
└─────────────────────────────────────┘
```

## 解決策

Islandはインタラクティブなコンポーネントのみをハイドレート:

```
┌─────────────────────────────────────┐
│  ヘッダー (静的)      ← JSなし      │
├─────────────────────────────────────┤
│  記事 (静的)         ← JSなし      │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ コメント Island   ← JS     │    │
│  └─────────────────────────────┘    │
│                                     │
│  フッター (静的)     ← JSなし      │
└─────────────────────────────────────┘
```

## ハイドレーショントリガー

Islandがいつハイドレートするかを制御:

### `load` - 即座に

```html
<div luna:id="critical" luna:client-trigger="load">
  <!-- ページロード時に即座にハイドレート -->
</div>
```

### `idle` - ブラウザがアイドル時

```html
<div luna:id="analytics" luna:client-trigger="idle">
  <!-- requestIdleCallback中にハイドレート -->
</div>
```

### `visible` - ビューポートに入った時

```html
<div luna:id="comments" luna:client-trigger="visible">
  <!-- IntersectionObserverが発火したらハイドレート -->
</div>
```

### `media` - メディアクエリにマッチした時

```html
<div luna:id="sidebar" luna:client-trigger="media:(min-width: 768px)">
  <!-- デスクトップでのみハイドレート -->
</div>
```

## Islandの作成

### サーバーサイド (MoonBit)

```moonbit
fn comments_section(props : CommentsProps) -> @luna.Node[Unit] {
  @server_dom.island(
    id="comments",
    url="/static/comments.js",
    state=props.to_json().stringify(),
    trigger=@luna.Visible,
    children=[
      // ハイドレーション前に表示されるSSRコンテンツ
      @server_dom.div([@server_dom.text("コメントを読み込み中...")])
    ],
  )
}
```

### クライアントサイド (TypeScript)

```typescript
// comments.ts
import { createSignal, hydrate, onMount } from '@mizchi/luna';

interface CommentsProps {
  postId: string;
}

function Comments(props: CommentsProps) {
  const [comments, setComments] = createSignal([]);

  // マウント時にコメントを取得
  onMount(async () => {
    const data = await fetch(`/api/comments/${props.postId}`);
    setComments(await data.json());
  });

  return (
    <ul>
      <For each={comments}>
        {(comment) => <li>{comment.text}</li>}
      </For>
    </ul>
  );
}

// ハイドレーション用に登録
hydrate("comments", Comments);
```

## Island State

サーバーからクライアントにシリアライズされた状態を渡す:

```html
<div
  luna:id="counter"
  luna:url="/static/counter.js"
  luna:state='{"count":5}'
  luna:client-trigger="load"
>
  <button>Count: 5</button>
</div>
```

クライアントは状態を受け取る:

```typescript
function Counter(props: { count: number }) {
  const [count, setCount] = createSignal(props.count);
  // 0ではなく5から開始
}
```

## Web Components Island

Declarative Shadow DOMでスタイルをカプセル化:

```moonbit
@server_dom.wc_island(
  name="wc-counter",
  url="/static/wc-counter.js",
  styles=":host { display: block; }",
  state=props.to_json().stringify(),
  trigger=@luna.Load,
  children=[...],
)
```

レンダリング結果:

```html
<wc-counter luna:wc-url="/static/wc-counter.js" luna:wc-state='{}'>
  <template shadowrootmode="open">
    <style>:host { display: block; }</style>
    <!-- SSRコンテンツ -->
  </template>
</wc-counter>
```

## ベストプラクティス

### 1. インタラクティブな境界を特定する

本当にインタラクティブなセクションのみをラップ:

```
✅ 検索ボックス → Island
✅ コメントフォーム → Island
✅ ショッピングカート → Island
❌ ナビゲーションメニュー (静的) → Islandにしない
❌ 記事コンテンツ → Islandにしない
```

### 2. 適切なトリガーを選択

| コンテンツ | トリガー |
|-----------|---------|
| ファーストビュー、重要 | `load` |
| ファーストビュー外 | `visible` |
| アナリティクス、重要でない | `idle` |
| デスクトップ専用機能 | `media` |

### 3. Island数を最小化

多数の小さなIslandより、少数の大きなIslandが良い:

```
❌ 10個の小さなIsland → 10回のスクリプト読み込み
✅ 2個の大きなIsland → 2回のスクリプト読み込み
```

### 4. 共通の依存関係を共有

共有コードを共通チャンクにバンドル:

```javascript
// rolldown設定
{
  output: {
    chunkFileNames: '_shared/[name]-[hash].js'
  }
}
```
