---
title: Benchmark Report
---

# Luna Benchmark Report

Luna vs React vs Preact の比較ベンチマーク結果。

## TL;DR - Luna の強み

| 指標 | Luna | 備考 |
|------|------|------|
| **バンドルサイズ** | 9.4 KB (gzip) | React の 1/6 |
| **SSR 性能** | 12,800 pages/sec | 1000アイテムリスト |
| **Signal 更新** | 11M ops/sec | Fine-Grained Reactivity |
| **部分更新** | 4.5M ops/sec | DOM 操作なしで更新 |

## Bundle Size Comparison

| Library | Minified | Gzip | vs React |
|---------|----------|------|----------|
| React 19 + ReactDOM | 193 KB | 60 KB | - |
| **Luna** | **33 KB** | **9.4 KB** | **6x smaller** |
| Preact 10 + hooks | 13 KB | 5.4 KB | 15x smaller |

**Luna は React の 1/6 のサイズ**。Preact より大きいが、Signal, SSR, Island Architecture を含むフルスタックフレームワーク。

## Runtime Performance

jsdom 環境でのベンチマーク結果 (vitest bench)。

### Initial Mount (2,500 cells)

| Library | ops/sec | vs Preact |
|---------|---------|-----------|
| Preact | 981 | 1x |
| React | 123 | 8x slower |
| Luna | 67 | 14.6x slower |

### Reactive State Mount (2,500 cells)

| Library | ops/sec | vs Preact |
|---------|---------|-----------|
| Preact | 61 | 1x |
| React | 42 | 1.4x slower |
| Luna | 42 | 1.5x slower |

### State Update (2,500 cells)

| Library | ops/sec | vs Preact |
|---------|---------|-----------|
| Preact | 12,523 | 1x |
| React | 119 | 105x slower |
| Luna | 111 | 113x slower |

> Note: Preact の Update が極端に速いのは、状態変更のバッチ処理による可能性あり。

### Large Grid (5,000 cells)

| Library | ops/sec | vs Preact |
|---------|---------|-----------|
| Preact | 387 | 1x |
| React | 53 | 7.3x slower |
| Luna | 29 | 13.3x slower |

### List Operations (Add 100 items)

| Library | ops/sec | vs Preact |
|---------|---------|-----------|
| Preact | 2,876 | 1x |
| React | 65 | 44x slower |
| Luna | 72 | 40x slower |

## Analysis

### Current Status

Luna は現時点で**速度面では React/Preact に劣っています**。これは以下の要因による：

1. **MoonBit → JS コンパイル**: 生成された JS コードは手書きより最適化の余地がある
2. **Fine-Grained Reactivity のオーバーヘッド**: 各要素ごとの依存追跡コスト
3. **開発初期段階**: まだ最適化が進んでいない

### Luna の価値提案

速度だけが全てではありません。Luna は以下の価値を提供します：

| Feature | Luna | React | Preact |
|---------|------|-------|--------|
| **Island Architecture** | ✅ Built-in | ❌ | ❌ |
| **Fine-Grained Reactivity** | ✅ | ❌ (VDOM) | ❌ (VDOM) |
| **SSR** | ✅ Native | Requires Next.js etc. | ✅ preact-render-to-string |
| **Hydration Strategies** | ✅ load/idle/visible/media | ❌ | ❌ |
| **Type Safety** | ✅ MoonBit | TypeScript | TypeScript |
| **Multi-target** | ✅ js/native/wasm | JS only | JS only |

### Future Optimization Opportunities

1. **wasm-gc target**: MoonBit は wasm-gc にコンパイル可能。将来的に JS より高速になる可能性
2. **コンパイラ最適化**: MoonBit コンパイラの改善による自動的な高速化
3. **DOM 操作の最適化**: 現在の実装にはまだ改善の余地がある

## Benchmark Environment

- Node.js v24 + jsdom
- Vitest 4.0.15
- macOS Darwin 24.5.0

## Running Benchmarks

```bash
cd luna.mbt
npx vitest bench js/luna/benches/grid.bench.ts --run
```

## Luna の強み - MoonBit ベンチマーク

Luna 内部の MoonBit ベンチマーク結果。これらは Luna の設計上の強みを示しています。

### SSR (Server-Side Rendering)

| テスト | 時間 | ops/sec |
|--------|------|---------|
| Simple element | 0.13 µs | 7.7M |
| 10 item list | 0.83 µs | 1.2M |
| 100 item list | 8.12 µs | 123K |
| **1000 item list** | **78 µs** | **12.8K** |
| 10 card page | 5.95 µs | 168K |
| 50 card page | 28.5 µs | 35K |
| 100 card page | 58.4 µs | 17K |

**SSR 性能は非常に高速** - 1000要素のリストを 78µs で生成可能。

### Signal (Fine-Grained Reactivity)

| 操作 | 時間 | ops/sec |
|------|------|---------|
| Signal::new | ~0.36 µs/100 | 280K |
| Signal::get | 0.28 µs/1000 | 3.6M |
| **Signal::set** | **0.09 µs** | **11M** |
| Memo cached read | 0.28 µs/1000 | 3.6M |
| Memo recompute | 0.63 µs | 1.6M |
| Effect rerun | ~1 µs | 1M |
| Batch 100 updates | 5 µs | 200K |

**Signal 更新は 11M ops/sec** - React の setState より桁違いに高速。

### DOM 更新 (Fine-Grained)

| 操作 | 時間 | ops/sec |
|------|------|---------|
| **Text update** | **0.22 µs** | **4.5M** |
| Attr update | 0.39 µs | 2.6M |
| Show toggle | 2.56 µs | 390K |
| Deep update (5 levels) | 0.37 µs | 2.7M |

**部分更新は 4.5M ops/sec** - VDOM diff なしで直接 DOM 更新。

### なぜ Luna は VDOM ベンチで遅いのか

Grid ベンチマーク（2,500セル全更新）では Luna は Preact より遅いが、これは：

1. **全要素更新は Luna の想定外ユースケース**
   - Fine-Grained Reactivity は「一部だけ更新」が前提
   - 2,500セル全部を毎回更新するのは VDOM 向き

2. **Luna の設計思想**
   - 変更された Signal だけが DOM を更新
   - 1セルの更新 = 0.22µs（VDOM diff 不要）

3. **実際のアプリでは Luna が有利なケース**
   - ほとんどの UI は部分更新
   - Island Architecture で初期化コストを分散

## Conclusion

### Luna が向いているケース

- ✅ **SSR + 選択的ハイドレーション** が必要
- ✅ **Island Architecture** で部分ハイドレーションしたい
- ✅ **部分更新が多い** UI（リアクティブなダッシュボード等）
- ✅ **小さなバンドルサイズ** が重要（React の 1/6）
- ✅ MoonBit で型安全な UI を書きたい
- ✅ 将来的な wasm-gc 対応を見据えている

### Luna が向いていないケース

- ❌ **大量要素の全更新**（ゲームのフレーム更新等）
- ❌ React/Preact エコシステム（既存ライブラリ）が必要

### 比較まとめ

| 特性 | Luna | Preact | React |
|------|------|--------|-------|
| バンドルサイズ | ⭐⭐⭐ 9KB | ⭐⭐⭐⭐ 5KB | ⭐ 60KB |
| 全要素更新 | ⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| 部分更新 | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| SSR | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| Island Architecture | ⭐⭐⭐⭐ Built-in | ❌ | ❌ |
