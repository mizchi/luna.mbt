# Luna Island vs WC Island 使い分けガイドライン

Luna フレームワークでは、2種類の Island アーキテクチャを提供しています。
それぞれの特性を理解し、適切に使い分けることで最適なパフォーマンスを実現できます。

## TL;DR - 判断フローチャート

```
あなたのコンポーネントは...

  外部サイトへの埋め込みが必要?
    → Yes: WC Island
    → No: ↓

  厳密な CSS カプセル化が必要?
    → Yes: WC Island
    → No: ↓

  大量のイベント伝搬がある? (フォーム、ドラッグ&ドロップ等)
    → Yes: Luna Island
    → No: ↓

  親コンポーネントと状態共有が多い?
    → Yes: Luna Island
    → No: ↓

  100個以上のインスタンスを同時表示?
    → Yes: Luna Island
    → No: どちらでも可 (デフォルト: Luna Island)
```

## 2種類の Island

### Luna Island (`@luna.island`)

**特徴:**
- 通常の DOM 内でレンダリング
- `luna:*` 属性によるハイドレーション
- イベントバブリングが自然に動作
- 親子間の状態共有が効率的

**適用シーン:**
- アプリケーション内部のコンポーネント
- フォーム、リスト、データテーブル
- 頻繁な状態更新が必要なUI
- ネストされたコンポーネント構造

### WC Island (`@luna.wc_island`)

**特徴:**
- Shadow DOM 内でレンダリング
- CSS がカプセル化される
- 外部スタイルの影響を受けない
- 独立したコンポーネント境界

**適用シーン:**
- 外部サイトへの埋め込みウィジェット
- サードパーティ統合（Zendesk型ツール）
- スタイル衝突を避けたいコンポーネント
- マイクロフロントエンドの境界

## ベンチマーク根拠

以下の数値は、実際のベンチマーク結果に基づいています。

### イベント伝搬

| パターン | 相対速度 |
|---------|----------|
| Luna Island (Light DOM) | **1x (基準)** |
| WC Island (Shadow 1層) | 5.7x 遅い |
| WC Island (Shadow 3層) | 11.6x 遅い |

**影響:** フォームや大量のクリックイベントがあるUIでは Luna Island が有利。

### 状態共有 (Context / Signal)

| パターン | 相対速度 |
|---------|----------|
| Luna Island (closure) | **1x (基準)** |
| WC Island (custom event) | 11x 遅い |
| WC Island (attribute drilling) | 16x 遅い |

**影響:** 親子間で頻繁に状態を共有するコンポーネントでは Luna Island が有利。

### コンポーネント生成

| パターン | 相対速度 |
|---------|----------|
| Luna Island (innerHTML) | **1x (基準)** |
| WC Island (Adoptable Stylesheets) | 1.8x 遅い |
| WC Island (Declarative Shadow DOM) | 3.6x 遅い |

**影響:** 100個以上のコンポーネントを同時生成する場合に差が顕著。

### querySelector (ハイドレーション時)

| パターン | 相対速度 |
|---------|----------|
| Luna Island (Light DOM) | **1x (基準)** |
| WC Island (Shadow DOM) | 4x 遅い |

**影響:** 初期ハイドレーション時間に影響。

## 実装例

### Luna Island の使用

```moonbit
// server/routes.mbt
fn home_page() -> @luna.Node {
  @element.div([
    // Luna Island: 通常の Island
    @luna.island(
      "counter-component",
      "/static/counter.js",
      "{\"count\":0}",
      [@element.text("Loading...")],
      trigger=@luna.Load,
    )
  ])
}
```

### WC Island の使用

```moonbit
// server/routes.mbt
fn widget_embed() -> @luna.Node {
  @element.div([
    // WC Island: 外部埋め込み用
    @luna.wc_island(
      name="embed-widget",
      url="/static/widget.js",
      state="{\"config\":\"...\"}",
      styles=widget_styles,  // カプセル化されたスタイル
      trigger=@luna.Visible,
      children=[@element.text("Loading...")],
    )
  ])
}
```

### 統一ハイドレーション

どちらの Island も同じコンポーネントコードを使用できます:

```typescript
// client/counter.ts
import { createSignal, hydrate } from '@luna_ui/luna';

interface CounterProps {
  initial_count: number;
}

function Counter(props: CounterProps) {
  const [count, setCount] = createSignal(props.initial_count);

  return (
    <div>
      <span>Count: </span>
      <span>{count()}</span>
      <button onClick={() => setCount(c => c + 1)}>+</button>
    </div>
  );
}

hydrate("counter-component", Counter);
```

ハイドレーションローダー (`@luna_ui/luna-loader`) は、
Shadow Root の有無を自動検出して適切に動作します。

## WC Island を選ぶべき具体例

### 1. 外部埋め込みウィジェット

```moonbit
// チャットウィジェット、フィードバックボタン等
@luna.wc_island(
  name="chat-widget",
  url="/widget/chat.js",
  state=state,
  styles=chat_styles,  // 外部サイトのCSSに影響されない
  trigger=@luna.Idle,
)
```

### 2. デザインシステムのカプセル化

```moonbit
// 他プロジェクトで再利用可能なUIライブラリ
@luna.wc_island(
  name="ds-button",
  url="/design-system/button.js",
  state=state,
  styles=design_system_styles,
  trigger=@luna.Load,
)
```

### 3. レガシーシステムとの統合

```moonbit
// 既存のjQueryサイトに部分的に導入
@luna.wc_island(
  name="modern-component",
  url="/modern/component.js",
  state=state,
  styles=modern_styles,  // レガシーCSSと分離
  trigger=@luna.Visible,
)
```

## Luna Island を選ぶべき具体例

### 1. 複雑なフォーム

```moonbit
// バリデーション、エラー表示、親への状態伝搬
@luna.island(
  "contact-form",
  "/static/form.js",
  state,
  [@element.text("Loading...")],
  trigger=@luna.Load,
)
```

### 2. データテーブル

```moonbit
// ソート、フィルタ、ページネーション、行選択
@luna.island(
  "data-table",
  "/static/table.js",
  state,
  [@element.text("Loading...")],
  trigger=@luna.Load,
)
```

### 3. ネストされたコンポーネント

```moonbit
// 親子で状態を共有するUI
@luna.island(
  "dashboard",
  "/static/dashboard.js",
  state,
  [@element.text("Loading...")],
  trigger=@luna.Idle,
)
```

## 最適化のヒント

### WC Island 使用時

1. **Adoptable Stylesheets を活用**
   - 同じコンポーネントが複数ある場合、スタイルを共有
   - インラインスタイルより 6x 高速

2. **Event Delegation を検討**
   - Shadow DOM 内でのイベントリスナー数を減らす
   - querySelectorAll より 2.9x 高速

3. **DOM Parts でバッチ更新**
   - 複数の値を一度に更新する場合に有効

### Luna Island 使用時

1. **Signal の粒度を適切に**
   - 更新が必要な部分だけを Signal 化
   - 過剰な Signal 化は避ける

2. **コンポーネント分割の判断**
   - 独立して更新される部分は別 Island に
   - ただし Island の数は最小限に

## 参考資料

- [Ryan Carniato: Web Components Are Not the Future](https://dev.to/ryansolid/web-components-are-not-the-future-48bh)
- [docs/wc-bench-results.md](./wc-bench-results.md) - 詳細なベンチマーク結果
- [docs/architecture.md](./architecture.md) - Luna アーキテクチャ概要
