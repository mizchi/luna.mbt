---
title: Why Luna?
---

# Why Luna?

Lunaは単なるJavaScriptフレームワークではありません。Web UIを構築するための根本的に異なるアプローチです。

## MoonBitで書かれている

Lunaは[MoonBit](https://www.moonbitlang.com/)で書かれています。クラウドとエッジコンピューティングのために設計された新しい言語です。

### なぜ重要か

```
従来のフレームワーク:
  JavaScript → JavaScriptランタイム → DOM

Luna:
  MoonBit → ネイティブバイナリ (SSR)
         → JavaScript (ブラウザ)
         → Wasm (エッジ)
```

**メリット:**

| 観点 | JavaScriptフレームワーク | Luna (MoonBit) |
|------|------------------------|----------------|
| 型安全性 | 実行時エラー | コンパイル時エラー |
| SSRパフォーマンス | V8オーバーヘッド | ネイティブ速度 |
| バンドルサイズ | フレームワーク + アプリ | 最適化された出力 |
| デッドコード | Tree-shaking | 確実な削除 |

### 同じロジック、複数のターゲット

```moonbit
// このSignalコードはどこでも動作
let count = @luna.signal(0)
let doubled = @luna.memo(fn() { count.get() * 2 })

@luna.effect(fn() {
  println("Count: \{count.get()}")
})
```

| ターゲット | ユースケース |
|-----------|-------------|
| **ネイティブ** | 高性能SSRサーバー |
| **JavaScript** | ブラウザハイドレーション |
| **Wasm** | エッジ関数、Workers |
| **Wasm-GC** | 次世代ランタイム |

## 真のきめ細かいリアクティビティ

Virtual DOMフレームワークとは異なり、Lunaは変更された部分だけを更新します - DOMノードレベルで。

### Virtual DOM (React, Vue)

```
状態変更
    ↓
新しい仮想ツリーを作成
    ↓
新旧ツリーをDiff比較    ← O(n) 比較
    ↓
実DOMにパッチ
```

### きめ細かいリアクティビティ (Luna, Solid)

```
Signalの変更
    ↓
直接DOM更新              ← O(1) 対象更新
```

### 実際の違い

```typescript
// Luna: このテキストノードだけが更新される
<p>Count: {count()}</p>

// Virtual DOM: コンポーネント全体が再レンダリング、
// その後diffでテキスト変更を検出
```

**無駄なレンダリングなし。Diffオーバーヘッドなし。直接更新。**

## Island Architectureを正しく実装

Lunaはきめ細かいリアクティビティとIslandsを組み合わせています - 両方の良いとこ取り。

### Islands (Astro, Fresh)

✅ 部分的ハイドレーション
✅ JavaScript配信量削減
❌ Island内でReact/Vueを使用することが多い（大きなランタイム）

### きめ細かいリアクティビティ (Solid, Svelte)

✅ 最小限のランタイム
✅ 高速な更新
❌ フルページハイドレーション

### Luna: 両方

✅ 部分的ハイドレーション
✅ JavaScript配信量削減
✅ 最小限のランタイム (~1.6KBローダー)
✅ Island内での高速な更新

```html
<!-- このIslandだけがJavaScriptを読み込む -->
<div luna:id="search" luna:client-trigger="visible">
  <!-- 内部できめ細かいリアクティビティ -->
</div>

<!-- 純粋なHTML、JavaScriptゼロ -->
<article>...</article>
```

## Web Componentsネイティブ

LunaはDeclarative Shadow DOMでWeb Componentsを採用。

### なぜWeb Components?

| 機能 | カスタム要素 | フレームワークコンポーネント |
|------|------------|---------------------------|
| スタイルカプセル化 | 組み込み (Shadow DOM) | CSS-in-JS, modules |
| 相互運用 | どこでも動作 | フレームワーク固有 |
| SSR | Declarative Shadow DOM | 様々 |
| 標準 | W3C標準 | 独自仕様 |

### Declarative Shadow DOM SSR

```html
<!-- サーバーレンダリング、スタイルはカプセル化済み -->
<wc-counter>
  <template shadowrootmode="open">
    <style>
      :host { display: block; }
      button { color: blue; }
    </style>
    <button>Count: 0</button>
  </template>
</wc-counter>
```

**FOUCなし。ハイドレーションミスマッチなし。スタイルは即座に動作。**

## スマートハイドレーショントリガー

コンポーネントがいつ、どのようにハイドレートするかを正確に制御。

```html
<!-- 重要: 即座にハイドレート -->
<div luna:client-trigger="load">...</div>

<!-- ファーストビュー外: 表示されたらハイドレート -->
<div luna:client-trigger="visible">...</div>

<!-- 重要でない: アイドル時にハイドレート -->
<div luna:client-trigger="idle">...</div>

<!-- レスポンシブ: デスクトップのみハイドレート -->
<div luna:client-trigger="media:(min-width: 768px)">...</div>
```

### 比較

| フレームワーク | ハイドレーション制御 |
|--------------|-------------------|
| React | 全てか無か |
| Next.js | ページ単位 (RSCで部分対応) |
| Astro | Island単位、visibleトリガー |
| Qwik | Resumability (別モデル) |
| **Luna** | **Island単位、4種のトリガー、メディアクエリ** |

## 極小ランタイム

Lunaのローダーは驚くほど小さい。

| コンポーネント | サイズ (minified) |
|--------------|------------------|
| ハイドレーションローダー | **~1.6 KB** |
| Islandランタイム (IIFE) | **~3.2 KB** |
| WCローダー | **~1.7 KB** |

### フレームワーク比較

| フレームワーク | 最小ランタイム |
|--------------|--------------|
| **Luna** | **~3 KB** |
| Preact | ~4 KB |
| Solid | ~7 KB |
| Svelte | ~2 KB (コンポーネントで増加) |
| Vue 3 | ~33 KB |
| React | ~42 KB |

**小さいランタイム = 速いロード = より良いCore Web Vitals**

## SSRパフォーマンス

### テンプレートオーバーヘッド

Shadow DOMテンプレート構文のオーバーヘッドは**ほぼゼロ**:

| 操作 | ops/sec | vs Plain HTML |
|-----|---------|---------------|
| 文字列連結 | 25,450 | 基準 |
| Shadow DOM構文 | 25,382 | **~0%** 遅い |
| Plain HTML構文 | 25,332 | ~0% 遅い |

### 公平な比較

適切なエスケープ処理を含めた比較:

| アプローチ | ops/sec | 比率 |
|-----------|---------|------|
| Plain HTML (エスケープあり) | 4,456 | 基準 |
| Plain HTML (関数コンポーネント) | 4,359 | 1.02倍遅い |
| **WC SSR (フル処理)** | **4,022** | **1.11倍遅い** |

Web Components SSRはPlain HTMLより**約10%遅いだけ**。

## 最適化のヒント

### 1. 適切なトリガーを使用

```html
<!-- 表示されるまでハイドレートしない -->
<div luna:client-trigger="visible">...</div>

<!-- 重要でないコンポーネントを遅延 -->
<div luna:client-trigger="idle">...</div>
```

### 2. Signal更新をバッチ処理

```typescript
import { batch } from '@mizchi/luna';

// 悪い例: 3回のeffect実行
setA(1);
setB(2);
setC(3);

// 良い例: 1回のeffect実行
batch(() => {
  setA(1);
  setB(2);
  setC(3);
});
```

### 3. 高コストな計算にはMemoを使用

```typescript
// 依存関係が変わった時だけ計算
const filtered = createMemo(() =>
  items().filter(item => item.active)
);
```

## 型安全な状態シリアライズ

サーバーからクライアントへ、完全な型安全性で状態が流れる。

### MoonBit (サーバー)

```moonbit
pub struct CounterProps {
  initial : Int
  max : Int
} derive(ToJson, FromJson)

fn counter_island(props : CounterProps) -> @luna.Node[Unit] {
  @server_dom.island(
    id="counter",
    url="/static/counter.js",
    state=props.to_json().stringify(),  // 型安全なシリアライズ
    children=[...],
  )
}
```

### TypeScript (クライアント)

```typescript
interface CounterProps {
  initial: number;
  max: number;
}

function Counter(props: CounterProps) {
  // props.initialとprops.maxは型付き
  const [count, setCount] = createSignal(props.initial);
  // ...
}
```

**`any`なし。実行時のサプライズなし。エンドツーエンドの型。**

## まとめ

| 特徴 | Lunaのアプローチ |
|-----|-----------------|
| **言語** | MoonBit (native/js/wasmにコンパイル) |
| **リアクティビティ** | きめ細かい (Virtual DOMなし) |
| **ハイドレーション** | スマートトリガー付きIslands |
| **コンポーネント** | Web Componentsネイティブ |
| **ランタイム** | 合計~3 KB |
| **型** | エンドツーエンドの型安全性 |

Lunaは以下を求める開発者向け:
- 最小ランタイムで**最大パフォーマンス**
- フレームワーク肥大化なしの**部分的ハイドレーション**
- サーバーからクライアントまでの**型安全性**
- 独自仕様より**Web標準**
