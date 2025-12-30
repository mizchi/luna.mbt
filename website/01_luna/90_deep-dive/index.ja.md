---
title: Deep Dive
---

# Deep Dive

高度な概念、内部アーキテクチャ、パフォーマンス最適化について。

## 設計上の決定

### なぜコンパイル時最適化がないのか？

多くのモダンフレームワーク（Svelte、Solid、Qwik）はコンパイル時変換に大きく依存しています：

| フレームワーク | アプローチ | トレードオフ |
|--------------|----------|-------------|
| Svelte | 命令型コードにコンパイル | マジック構文、デバッグが困難 |
| Solid | JSX 変換 | ビルドの複雑さ |
| Qwik | コード分割による Resumability | 複雑なメンタルモデル |
| **Luna** | **最小ランタイム、マジックなし** | **書いたコードがそのまま実行される** |

Luna は異なるアプローチを取ります：**ランタイムを非常に小さくして、最適化が不要になるようにする**。

合計約 6.7KB の Luna のオーバーヘッドは既に無視できるレベルです。これは以下を意味します：
- ビルド時のサプライズなし
- デバッグが容易（コードが書いた通りに動作）
- シンプルなメンタルモデル
- あらゆるバンドラーで動作

### WebComponents SSR: 世界初の実装

Luna は Declarative Shadow DOM を使用した完全な WebComponents SSR + Hydration をサポートする最初のフレームワークです：

```html
<!-- サーバーレンダリング出力 -->
<my-counter luna:client-trigger="visible">
  <template shadowrootmode="open">
    <style>button { color: blue; }</style>
    <button>Count: 0</button>
  </template>
</my-counter>
```

キーとなる洞察：Declarative Shadow DOM（`<template shadowrootmode="open">`）により、Shadow DOM を HTML としてシリアライズできます。Luna のハイドレーションシステムと組み合わせることで、以下が可能になります：

- **カプセル化されたスタイルでの SSR** - FOUC なし（スタイル未適用コンテンツのフラッシュ）
- **プログレッシブエンハンスメント** - JS ロード前にコンテンツが表示
- **フレームワーク非依存** - Islands は任意のフロントエンドコードで動作

---

## リアクティビティシステム

Luna のリアクティビティは細粒度シグナルに基づいています：

```
Signal
  └── Subscribers (Effects, Memos)
        └── DOM Updates
```

シグナルが変更されると：
1. すべてのサブスクライバーに通知
2. Effects は同期的に実行（バッチ処理）
3. DOM 更新は直接実行（差分なし）

### Signal の実装

Signal は自動依存関係追跡を持つオブザーバブル値として実装されています：

```moonbit
// Signal を作成
let count = @signal.signal(0)

// 読み取り（依存関係を追跡）
count.get()  // 0 を返し、この読み取りを追跡

// 書き込み（サブスクライバーに通知）
count.set(1)  // すべての Effect に通知

// 更新（読み取り + 書き込み）
count.update(fn(n) { n + 1 })
```

### 細粒度 vs 粗粒度

Luna はセレクター付きの粗粒度ストアではなく、細粒度シグナル（フィールドごとの個別シグナル）を使用します：

| パターン | パフォーマンス | ユースケース |
|---------|--------------|-------------|
| 細粒度 | **21-104倍高速** | すべてのケースで推奨 |
| 粗粒度（select） | 遅い | API から削除 |

**なぜ細粒度が勝つのか：**

```moonbit
// 細粒度：count の更新は count のウォッチャーのみトリガー
let count = @signal.signal(0)
let name = @signal.signal("test")
count.set(1)  // count の Effect のみ実行

// 粗粒度（削除済み）：すべての更新がすべてのセレクターをトリガー
let state = signal({ count: 0, name: "test" })
state.set({ ...state, count: 1 })  // すべてのセレクターが再評価
```

### パフォーマンス特性

| 操作 | 計算量 |
|-----|-------|
| Signal 読み取り | O(1) |
| Signal 書き込み | O(subscribers) |
| DOM 更新 | 影響を受けるノードごとに O(1) |

Virtual DOM との比較：
- React: 毎回のレンダリングで O(n) ツリー差分
- Luna: O(1) 直接更新

これが同じワークロードで React が 12 FPS のところ Luna が 60 FPS を達成する理由です。

---

## VNode アーキテクチャ

Luna は SSR 用に仮想ノード表現を使用します：

```moonbit
pub enum Node[E] {
  Element(VElement[E])      // HTML 要素
  Text(String)              // 静的テキスト
  DynamicText(() -> String) // リアクティブテキスト
  Fragment(Array[Node[E]])  // フラグメント
  Show(...)                 // 条件付きレンダリング
  For(...)                  // リストレンダリング
  Island(VIsland[E])        // Hydration 境界
  WcIsland(VWcIsland[E])    // Web Components Island
  Async(VAsync[E])          // 非同期ノード
}
```

### 属性型

```moonbit
pub enum Attr[E] {
  VStatic(String)           // 静的値
  VDynamic(() -> String)    // Signal 連動
  VHandler(EventHandler[E]) // イベントハンドラ
  VAction(String)           // 宣言的アクション
}
```

### トリガー型

ハイドレーションは様々な方法でトリガーできます：

```moonbit
pub enum TriggerType {
  Load      // ページロード時
  Idle      // requestIdleCallback
  Visible   // IntersectionObserver
  Media(String)  // メディアクエリマッチ
  None      // 手動トリガー
}
```

---

## パフォーマンス最適化

### 10,000 セル問題

大量の要素（例：100x100 グリッド）をレンダリングする場合、ナイーブなアプローチは失敗します：

| アプローチ | フレーム時間 | FPS |
|----------|------------|-----|
| 個別の `attr_dynamic` | 76ms | 13 |
| 単一 Effect | ~10ms | 100 |
| ダーティトラッキング | 0.7ms | **1400** |

### アンチパターン：個別の動的属性

```moonbit
// 悪い例：10,000 の Effect を作成
@dom.for_each(
  fn() { indices },
  fn(i, _) {
    @dom.div(
      class_dyn=fn() { cell_class(get_cell(i)) },  // セルごとに Effect！
      [],
    )
  },
)
```

**問題：** 10,000 の独立した Effect。すべてのシグナル更新がすべてを再実行。

### パターン 1：単一 Effect でバッチ更新

```moonbit
// 良い例：すべてのセルに対して1つの Effect
let cell_elements : Array[@js_dom.Element] = []

let _ = @signal.effect(fn() {
  let state = state_sig.get()
  for i = 0; i < cell_elements.length(); i = i + 1 {
    cell_elements[i].setClassName(cell_class(get_cell(i, state)))
  }
})

@dom.for_each(
  fn() { indices },
  fn(_, _) {
    @dom.div(
      class="cell",
      ref_=fn(el) { cell_elements.push(el) },
      [],
    )
  },
)
```

### パターン 2：ダーティトラッキング（推奨）

```moonbit
// 最良：変更されたセルのみ更新
let cell_elements : Array[@js_dom.Element] = []
let prev_cell_types : Array[Int] = []

let _ = @signal.effect(fn() {
  let state = state_sig.get()
  for i = 0; i < cell_elements.length(); i = i + 1 {
    let cell_type = get_cell(i, state)
    // 変更された場合のみ更新
    if cell_type != prev_cell_types[i] {
      prev_cell_types[i] = cell_type
      cell_elements[i].setClassName(cell_class(cell_type))
    }
  }
})
```

**結果：** 0.7ms/フレーム - ナイーブなアプローチより100倍高速。

### 最適化の原則

1. **Effect 数を最小化** - 多くの要素を更新する1つの Effect は、それぞれ1つの要素を更新する多くの Effect より優れている

2. **DOM 参照を保持** - `ref_` を使用して要素参照を取得し、Effect 内で直接更新

3. **ダーティトラッキング** - 前の状態を追跡し、値が変更された場合のみ DOM を更新

4. **ホットパスには FFI** - パフォーマンスクリティカルな操作には JavaScript FFI を使用

```moonbit
// 遅い：MoonBit の to_int()
let x = pos.to_int()

// 速い：ビット演算を使った JS FFI
extern "js" fn to_int_fast(x : Double) -> Int =
  #| (x) => x | 0
```

---

## ハイドレーション戦略

Luna は複数のハイドレーション戦略をサポートします：

| 戦略 | タイミング | ユースケース |
|-----|----------|-------------|
| `load` | 即座に | 重要なインタラクション |
| `idle` | ブラウザアイドル時 | 二次的機能 |
| `visible` | ビューポート内 | 下部コンテンツ |
| `media` | クエリマッチ時 | デバイス固有 |

### Island 属性

サーバーレンダリングされた HTML にはハイドレーションメタデータが含まれます：

```html
<div luna:id="counter"
     luna:url="/static/counter.js"
     luna:state='{"count":0}'
     luna:client-trigger="visible">
  <!-- SSR コンテンツ -->
</div>
```

| 属性 | 目的 |
|-----|------|
| `luna:id` | コンポーネント識別子 |
| `luna:url` | JavaScript モジュール URL |
| `luna:state` | シリアライズされた初期状態 |
| `luna:client-trigger` | ハイドレーション戦略 |

### ハイドレーションプロセス

1. **ローダー初期化** - 小さな（~1.6KB）ローダースクリプトが実行
2. **Island 検出** - `luna:id` を持つ要素を検索
3. **戦略評価** - トリガー条件をチェック
4. **モジュールロード** - Island コードの動的インポート
5. **状態デシリアライズ** - `luna:state` をパース
6. **ハイドレーション** - 既存 DOM にリアクティビティをアタッチ

### Web Components 統合

Island は Web Components として実装できます：

```typescript
hydrateWC("my-counter", (root, props, trigger) => {
  // root: ShadowRoot（SSR から既存）
  // props: シリアライズされた props
  // trigger: ハイドレーショントリガー情報
});
```

利点：
- Shadow DOM によるスタイルカプセル化
- ネイティブブラウザサポート
- フレームワーク非依存の Island

---

## 状態管理パターン

### 1. 個別 Signal（シンプルな状態）

```moonbit
let count = @signal.signal(0)
let name = @signal.signal("")
```

2-5 個の独立したフィールドに最適。

### 2. SplitStore（構造化された状態）

```moonbit
struct AppState {
  count : @signal.Signal[Int]
  user : @signal.Signal[User?]
}

fn AppState::new() -> AppState {
  {
    count: @signal.signal(0),
    user: @signal.signal(None)
  }
}
```

明示的な構造を持つ型付き状態に最適。

### 3. Context API（依存性注入）

```moonbit
let theme_ctx = create_context("light")

provide(theme_ctx, "dark", fn() {
  let theme = use_context(theme_ctx)  // "dark"
  render_child()
})
```

テーマ、i18n、グローバル設定に最適。

---

## MoonBit アーキテクチャ

Luna はマルチターゲットサポートを持つ MoonBit で実装されています：

| ターゲット | Signal | Render | DOM |
|-----------|:------:|:------:|:---:|
| JavaScript | ✅ | ✅ | ✅ |
| Native | ✅ | ✅ | - |
| Wasm | ✅ | ✅ | - |
| Wasm-GC | ✅ | ✅ | - |

### モジュール構造

```
src/luna/
├── signal/      # リアクティブプリミティブ（全ターゲット）
├── render/      # VNode → HTML 文字列（全ターゲット）
├── routes/      # 型安全ルーティング
├── serialize/   # 状態シリアライズ
└── vnode.mbt    # VNode 型

src/platform/
├── dom/         # ブラウザ DOM 操作（JS のみ）
└── js_dom/      # JavaScript DOM FFI
```

### なぜ MoonBit か？

| 観点 | JavaScript | MoonBit |
|------|------------|---------|
| 型安全性 | ランタイムエラー | コンパイル時 |
| デッドコード | ツリーシェイキング | 確実な除去 |
| SSR 速度 | V8 オーバーヘッド | ネイティブ速度 |
| バンドルサイズ | フレームワーク + アプリ | 最適化された出力 |

---

## デバッグのヒント

### 1. Effect トラッキング

```moonbit
@signal.effect(fn() {
  println("Effect running")
  let val = some_signal.get()
  println("Read value: " + val.to_string())
})
```

### 2. Signal インスペクション

```typescript
// ブラウザコンソールで
window.__LUNA_DEBUG__ = true;
```

### 3. ハイドレーションデバッグ

Network タブで Island モジュールのロードを確認。Elements パネルで `luna:*` 属性を検証。

### 4. パフォーマンスプロファイリング

ブラウザ DevTools の Performance タブを使用。以下を確認：
- Effect 実行時間
- DOM 更新頻度
- モジュールロードタイミング

---

## 関連項目

- [Signals API](/ja/luna/api-js/signals/) - JavaScript シグナルリファレンス
- [Islands API](/ja/luna/api-js/islands/) - Island 設定
- [Stella](/ja/stella/) - Web Components ビルダー
