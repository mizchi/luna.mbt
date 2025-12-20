---
title: Why Luna UI?
---

# Why Luna LUI?

- 軽量 7.5k
- 

⏺ Update(~/mizchi/luna.mbt/docs/benchmark.md)
  ⎿  Added 9 lines                                                        
       2  
       3  Luna vs React vs Preact の比較ベンチマーク結果。
       4  
       5 +## TL;DR - Luna の強み                                          
       6 +                                                                
       7 +| 指標 | Luna | 備考 |                                          
       8 +|------|------|------|                                          
       9 +| **バンドルサイズ** | 9.4 KB (gzip) | React の 1/6 |           
      10 +| **SSR 性能** | 12,800 pages/sec | 1000アイテムリスト |        
      11 +| **Signal 更新** | 11M ops/sec | Fine-Grained Reactivity |     
      12 +| **部分更新** | 4.5M ops/sec | DOM 操作なしで更新 |            
      13 +                                                                
      14  ## Bundle Size Comparison
      15  
      16  | Library | Minified | Gzip | vs React |

⏺ Update(~/mizchi/luna.mbt/docs/benchmark.md)
  ⎿  Added 78 lines, removed 8 lines                                      
      109  npx vitest bench js/luna/benches/grid.bench.ts --run
      110  ```
      111  
      112 -## Conclusion                                                  
      112 +## Luna の強み - MoonBit ベンチマーク                          
      113  
      114 -**Luna はパフォーマンス重視のアプリには現時点では推奨しません。
          -**                                                             
      114 +Luna 内部の MoonBit ベンチマーク結果。これらは Luna の設計上の 
          +強みを示しています。                                           
      115  
      116 -以下のケースで Luna を検討してください：                       
      116 +### SSR (Server-Side Rendering)                                
      117  
      118 -- ✅ Island Architecture で部分ハイドレーションしたい          
      118 +| テスト | 時間 | ops/sec |                                    
      119 +|--------|------|---------|                                    
      120 +| Simple element | 0.13 µs | 7.7M |                            
      121 +| 10 item list | 0.83 µs | 1.2M |                              
      122 +| 100 item list | 8.12 µs | 123K |                             
      123 +| **1000 item list** | **78 µs** | **12.8K** |                 
      124 +| 10 card page | 5.95 µs | 168K |                              
      125 +| 50 card page | 28.5 µs | 35K |                               
      126 +| 100 card page | 58.4 µs | 17K |                              
      127 +                                                               
      128 +**SSR 性能は非常に高速** - 1000要素のリストを 78µs で生成可能。
      129 +                                                               
      130 +### Signal (Fine-Grained Reactivity)                           
      131 +                                                               
      132 +| 操作 | 時間 | ops/sec |                                      
      133 +|------|------|---------|                                      
      134 +| Signal::new | ~0.36 µs/100 | 280K |                          
      135 +| Signal::get | 0.28 µs/1000 | 3.6M |                          
      136 +| **Signal::set** | **0.09 µs** | **11M** |                    
      137 +| Memo cached read | 0.28 µs/1000 | 3.6M |                     
      138 +| Memo recompute | 0.63 µs | 1.6M |                            
      139 +| Effect rerun | ~1 µs | 1M |                                  
      140 +| Batch 100 updates | 5 µs | 200K |                            
      141 +                                                               
      142 +**Signal 更新は 11M ops/sec** - React の setState より桁違いに 
          +高速。                                                         
      143 +                                                               
      144 +### DOM 更新 (Fine-Grained)                                    
      145 +                                                               
      146 +| 操作 | 時間 | ops/sec |                                      
      147 +|------|------|---------|                                      
      148 +| **Text update** | **0.22 µs** | **4.5M** |                   
      149 +| Attr update | 0.39 µs | 2.6M |                               
      150 +| Show toggle | 2.56 µs | 390K |                               
      151 +| Deep update (5 levels) | 0.37 µs | 2.7M |                    
      152 +                                                               
      153 +**部分更新は 4.5M ops/sec** - VDOM diff なしで直接 DOM 更新。  
      154 +                                                               
      155 +### なぜ Luna は VDOM ベンチで遅いのか                         
      156 +                                                               
      157 +Grid ベンチマーク（2,500セル全更新）では Luna は Preact より遅 
          +いが、これは：                                                 
      158 +                                                               
      159 +1. **全要素更新は Luna の想定外ユースケース**                  
      160 +   - Fine-Grained Reactivity は「一部だけ更新」が前提          
      161 +   - 2,500セル全部を毎回更新するのは VDOM 向き                 
      162 +                                                               
      163 +2. **Luna の設計思想**                                         
      164 +   - 変更された Signal だけが DOM を更新                       
      165 +   - 1セルの更新 = 0.22µs（VDOM diff 不要）                    
      166 +                                                               
      167 +3. **実際のアプリでは Luna が有利なケース**                    
      168 +   - ほとんどの UI は部分更新                                  
      169 +   - Island Architecture で初期化コストを分散                  
      170 +                                                               
      171 +## Conclusion                                                  
      172 +                                                               
      173 +### Luna が向いているケース                                    
      174 +                                                               
      175 +- ✅ **SSR + 選択的ハイドレーション** が必要                   
      176 +- ✅ **Island Architecture** で部分ハイドレーションしたい      
      177 +- ✅ **部分更新が多い** UI（リアクティブなダッシュボード等）   
      178 +- ✅ **小さなバンドルサイズ** が重要（React の 1/6）           
      179  - ✅ MoonBit で型安全な UI を書きたい
      120 -- ✅ SSR + 選択的ハイドレーションが必要                        
      180  - ✅ 将来的な wasm-gc 対応を見据えている
      181  
      123 -パフォーマンスが最優先の場合：                                 
      124 -- Preact (最小・最速)                                          
      125 -- React (エコシステム)                                         
      182 +### Luna が向いていないケース                                  
      183 +                                                               
      184 +- ❌ **大量要素の全更新**（ゲームのフレーム更新等）            
      185 +- ❌ React/Preact エコシステム（既存ライブラリ）が必要         
      186 +                                                               
      187 +### 比較まとめ                                                 
      188 +                                                               
      189 +| 特性 | Luna | Preact | React |                               
      190 +|------|------|--------|-------|                               
      191 +| バンドルサイズ | ⭐⭐⭐ 9KB | ⭐⭐⭐⭐ 5KB | ⭐ 60KB |       
      192 +| 全要素更新 | ⭐ | ⭐⭐⭐⭐ | ⭐⭐ |                          
      193 +| 部分更新 | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ |                          
      194 +| SSR | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ |                               
      195 +| Island Architecture | ⭐⭐⭐⭐ Built-in | ❌ | ❌ |          

  Luna の強み

  | 指標           | Luna             | 備考           |
  |----------------|------------------|----------------|
  | バンドルサイズ | 9.4 KB           | React の 1/6   |
  | SSR            | 12,800 pages/sec | 1000アイテム   |
  | Signal 更新    | 11M ops/sec      | Fine-Grained   |
  | 部分更新       | 4.5M ops/sec     | VDOM diff 不要 |

  Luna の弱み（正直に）

  | 指標              | Luna vs Preact |
  |-------------------|----------------|
  | 全要素更新        | 14x 遅い       |
  | Grid 初期マウント | 13x 遅い       |

  結論

  Luna は 「全部更新」には向かない が、「部分更新」「SSR」「Island Architecture」 では強い。

  - 2,500 セル全更新 → Preact/React が速い（VDOM 向き）
  - 1 セルだけ更新 → Luna が速い（0.22µs、Signal 直結）

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
let count = Signal::new(0)
let doubled = memo(fn() { count.get() * 2 })

effect(fn() {
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

fn counter_island(props : CounterProps) -> @luna.Node {
  @luna.island(
    "counter",
    "/static/counter.js",
    props.to_json().stringify(),  // 型安全なシリアライズ
    [@element.div([@element.text("Loading...")])],
    trigger=@luna.Load,
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
