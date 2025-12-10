# Fixable Hydration (Experimental)

This document describes the experimental hydration system that can repair DOM mismatches during hydration, similar to morphdom.

## Overview

The fixable hydration module provides resilient hydration that can repair mismatches between server-rendered HTML and the expected VDOM structure. This is useful when:

- Server HTML may differ slightly from expected VDOM due to caching
- Different render paths produce slightly different output
- User modifications have altered the DOM before hydration

## API

### `experimental_hydrate`

Low-level hydration with repair capability. Always attempts to repair mismatches.

```moonbit
pub fn experimental_hydrate(
  container : @js_dom.Element,
  node : @ui.Node,
  logger? : StringBuilder,
) -> ExperimentalHydrationResult
```

### `smart_hydrate` (Recommended)

Smart hydration that uses heuristics to decide between repair and full re-render.

```moonbit
pub fn smart_hydrate(
  container : @js_dom.Element,
  node : @ui.Node,
  logger? : StringBuilder,
) -> SmartHydrateResult
```

**Heuristics applied:**
- Falls back to full render if VNode tree has more than 50 nodes
- Falls back to full render if DOM has less than 30% of expected nodes

### `hydrate_with_fallback`

Tries regular hydration first, falls back to experimental if it fails.

```moonbit
pub fn hydrate_with_fallback(
  container : @js_dom.Element,
  node : @ui.Node,
  logger? : StringBuilder,
) -> @dom.HydrationResult
```

## Repair Types

The system can detect and repair the following mismatches:

| Repair Type | Description |
|-------------|-------------|
| `TextMismatch` | Text content differs |
| `TextMissing` | Text node is missing |
| `ElementMissing` | Element node is missing |
| `TagMismatch` | Element tag is wrong |
| `AttributeMismatch` | Attribute value differs |
| `DynamicTextMarkerMissing` | Dynamic text marker (comment) is missing |
| `ShowMarkerMissing` | Show/hide markers are missing |
| `ForMarkerMissing` | For loop markers are missing |
| `ForItemCountMismatch` | For loop item count differs |
| `ShowContentMissing` | Show content is missing when visible |

## Performance Benchmarks

### Full Render vs Experimental Hydrate (Clean Match)

| Nodes | Full Render | experimental_hydrate | Ratio |
|-------|-------------|---------------------|-------|
| 10 | 53 µs | 223 µs | 4.2x slower |
| 50 | 254 µs | 1.91 ms | 7.5x slower |
| 100 | 528 µs | 6.39 ms | 12x slower |

**Key finding:** `experimental_hydrate` is 4-12x slower than full render even with a clean match (no repairs needed).

### Impact of Mismatch Severity

| Test Case | 50 Nodes |
|-----------|----------|
| Clean (0% mismatch) | 1.91 ms |
| 1 text mismatch | 1.90 ms |
| 10% text mismatch | 1.91 ms |
| 50% text mismatch | 1.89 ms |
| 100% text mismatch | 1.85 ms |

**Key finding:** The number of text mismatches has minimal impact on repair time.

### Missing Elements

| Missing Elements | 50 Nodes |
|-----------------|----------|
| 1 missing | 1.82 ms |
| 10 missing | 1.53 ms |
| 25 missing | 1.02 ms |

**Key finding:** Fewer DOM nodes to traverse actually makes hydration faster.

### Smart Hydrate with Heuristics

| Test Case | Time | Strategy |
|-----------|------|----------|
| 10 nodes clean | 252 µs | experimental_hydrate |
| 50 nodes clean | 1.03 ms | experimental_hydrate |
| 60 nodes | ~300 µs | fallback (full render) |
| 100 nodes | ~530 µs | fallback (full render) |
| Low DOM/VNode ratio | ~500 µs | fallback (full render) |

## When to Use

### Use `smart_hydrate` when:
- You need resilient hydration that handles minor mismatches
- The VNode tree is small (<50 nodes)
- You're unsure if server HTML will match exactly

### Use `experimental_hydrate` when:
- You need detailed repair reports
- You're debugging hydration issues
- You want to force repair mode regardless of performance

### Use regular `hydrate` when:
- Server HTML is guaranteed to match exactly
- Performance is critical
- VNode tree is large

## Heuristics Configuration

The following constants control the heuristics:

```moonbit
// Fallback if DOM/VNode ratio is below this threshold
let min_node_ratio : Double = 0.3

// Fallback if VNode tree exceeds this node count
let max_hydration_nodes : Int = 50
```

## Conclusion

The experimental hydration system trades performance for resilience. For small trees with potential mismatches, it provides automatic repair capability. For larger trees or when performance is critical, `smart_hydrate` automatically falls back to full render.

---

# Fixable Hydration (実験的機能)

このドキュメントでは、morphdomのようにDOM不一致を修復できる実験的ハイドレーションシステムについて説明します。

## 概要

fixable hydrationモジュールは、サーバーレンダリングされたHTMLと期待されるVDOM構造の間の不一致を修復できる、回復力のあるハイドレーションを提供します。以下のような場合に有用です：

- キャッシュによりサーバーHTMLが期待と若干異なる場合
- 異なるレンダリングパスが微妙に異なる出力を生成する場合
- ハイドレーション前にユーザーがDOMを変更した場合

## API

### `experimental_hydrate`

修復機能を持つ低レベルハイドレーション。常に不一致の修復を試みます。

```moonbit
pub fn experimental_hydrate(
  container : @js_dom.Element,
  node : @ui.Node,
  logger? : StringBuilder,
) -> ExperimentalHydrationResult
```

### `smart_hydrate` (推奨)

ヒューリスティックを使用して修復かフルレンダリングかを判断するスマートハイドレーション。

```moonbit
pub fn smart_hydrate(
  container : @js_dom.Element,
  node : @ui.Node,
  logger? : StringBuilder,
) -> SmartHydrateResult
```

**適用されるヒューリスティック:**
- VNodeツリーが50ノードを超える場合はフルレンダリングにフォールバック
- DOMノード数が期待の30%未満の場合はフルレンダリングにフォールバック

### `hydrate_with_fallback`

通常のハイドレーションを最初に試み、失敗した場合は実験的ハイドレーションにフォールバック。

```moonbit
pub fn hydrate_with_fallback(
  container : @js_dom.Element,
  node : @ui.Node,
  logger? : StringBuilder,
) -> @dom.HydrationResult
```

## 修復タイプ

システムは以下の不一致を検出・修復できます：

| 修復タイプ | 説明 |
|------------|------|
| `TextMismatch` | テキスト内容が異なる |
| `TextMissing` | テキストノードが欠落 |
| `ElementMissing` | 要素ノードが欠落 |
| `TagMismatch` | 要素タグが間違っている |
| `AttributeMismatch` | 属性値が異なる |
| `DynamicTextMarkerMissing` | 動的テキストマーカー（コメント）が欠落 |
| `ShowMarkerMissing` | Show/hideマーカーが欠落 |
| `ForMarkerMissing` | Forループマーカーが欠落 |
| `ForItemCountMismatch` | Forループのアイテム数が異なる |
| `ShowContentMissing` | 表示状態のShowコンテンツが欠落 |

## パフォーマンスベンチマーク

### フルレンダリング vs experimental_hydrate（完全一致時）

| ノード数 | フルレンダリング | experimental_hydrate | 比率 |
|----------|-----------------|---------------------|------|
| 10 | 53 µs | 223 µs | 4.2倍遅い |
| 50 | 254 µs | 1.91 ms | 7.5倍遅い |
| 100 | 528 µs | 6.39 ms | 12倍遅い |

**重要な発見:** `experimental_hydrate`は完全一致（修復不要）でもフルレンダリングより4〜12倍遅い。

### 不一致の程度による影響

| テストケース | 50ノード |
|--------------|----------|
| 完全一致（0%不一致） | 1.91 ms |
| 1件のテキスト不一致 | 1.90 ms |
| 10%テキスト不一致 | 1.91 ms |
| 50%テキスト不一致 | 1.89 ms |
| 100%テキスト不一致 | 1.85 ms |

**重要な発見:** テキスト不一致の数は修復時間にほとんど影響しない。

### 要素欠落の影響

| 欠落要素数 | 50ノード |
|-----------|----------|
| 1件欠落 | 1.82 ms |
| 10件欠落 | 1.53 ms |
| 25件欠落 | 1.02 ms |

**重要な発見:** 走査するDOMノードが少ないと実際にはハイドレーションが速くなる。

### ヒューリスティック付きsmart_hydrate

| テストケース | 時間 | 戦略 |
|--------------|------|------|
| 10ノード完全一致 | 252 µs | experimental_hydrate |
| 50ノード完全一致 | 1.03 ms | experimental_hydrate |
| 60ノード | 約300 µs | フォールバック（フルレンダリング） |
| 100ノード | 約530 µs | フォールバック（フルレンダリング） |
| DOM/VNode比率が低い | 約500 µs | フォールバック（フルレンダリング） |

## 使用場面

### `smart_hydrate`を使用する場面：
- 軽微な不一致を処理できる回復力のあるハイドレーションが必要
- VNodeツリーが小さい（50ノード未満）
- サーバーHTMLが正確に一致するか不明

### `experimental_hydrate`を使用する場面：
- 詳細な修復レポートが必要
- ハイドレーションの問題をデバッグ中
- パフォーマンスに関係なく修復モードを強制したい

### 通常の`hydrate`を使用する場面：
- サーバーHTMLが正確に一致することが保証されている
- パフォーマンスが重要
- VNodeツリーが大きい

## ヒューリスティック設定

以下の定数がヒューリスティックを制御します：

```moonbit
// DOM/VNode比率がこの閾値を下回るとフォールバック
let min_node_ratio : Double = 0.3

// VNodeツリーがこのノード数を超えるとフォールバック
let max_hydration_nodes : Int = 50
```

## 結論

実験的ハイドレーションシステムは、パフォーマンスを犠牲にして回復力を得るトレードオフです。不一致の可能性がある小さなツリーに対しては自動修復機能を提供します。大きなツリーやパフォーマンスが重要な場合、`smart_hydrate`は自動的にフルレンダリングにフォールバックします。
