---
title: パフォーマンス
---

# パフォーマンス

Lunaは最小のランタイムオーバーヘッドと最大のパフォーマンスを目指して設計されています。

## バンドルサイズ

| コンポーネント | サイズ (minified) |
|--------------|------------------|
| Hydration Loader | **~1.6 KB** |
| Island Runtime (IIFE) | **~3.2 KB** |
| WC Loader | **~1.7 KB** |

人気フレームワークとの比較:

| フレームワーク | ランタイムサイズ |
|--------------|----------------|
| **Luna** | **~3 KB** |
| Preact | ~4 KB |
| Solid.js | ~7 KB |
| Vue 3 | ~33 KB |
| React | ~42 KB |

## SSRベンチマーク

### テンプレートオーバーヘッド

Shadow DOMテンプレート構文のオーバーヘッドは**ほぼゼロ**:

| 操作 | ops/sec | vs Plain HTML |
|-----|---------|---------------|
| 文字列連結 | 25,450 | 基準 |
| Shadow DOM構文 | 25,382 | **~0%** 遅い |
| Plain HTML構文 | 25,332 | ~0% 遅い |

テンプレート形式はボトルネックではありません。

### 実際のボトルネック

| 操作 | ops/sec | オーバーヘッド |
|-----|---------|--------------|
| Plain連結 | 25,450 | 基準 |
| JSON.stringify | 2,181 | 12倍遅い |
| escapeAttr | 396 | **64倍遅い** |

属性のエスケープがSSR時間を支配しており、テンプレート生成ではありません。

### 公平な比較

適切なエスケープ処理を含めた比較:

| アプローチ | ops/sec | 比率 |
|-----------|---------|------|
| Plain HTML (エスケープあり) | 4,456 | 基準 |
| Plain HTML (関数コンポーネント) | 4,359 | 1.02倍遅い |
| **WC SSR (フル処理)** | **4,022** | **1.11倍遅い** |

Web Components SSRはPlain HTMLより**約10%遅いだけ**。

## DOMパフォーマンス

### 初期レンダリング

| 方法 | ops/sec | 備考 |
|-----|---------|------|
| createElement | 608,134 | 直接DOM API |
| attachShadow + innerHTML | 171,214 | Shadow Root |
| Plain innerHTML | 170,044 | パース必要 |
| Declarative Shadow DOM | 66,810 | テンプレートパース |

### 更新

| 操作 | オーバーヘッド |
|-----|--------------|
| textContent更新 | ~12%遅い |
| DOM Partsバッチ | 1.38倍速い |
| Adoptable Stylesheets | **8.4倍速い** |

## 最適化のヒント

### 1. 適切なトリガーを使用

```html
<!-- 表示されるまでハイドレートしない -->
<div luna:trigger="visible">...</div>

<!-- 重要でないコンポーネントを遅延 -->
<div luna:trigger="idle">...</div>
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

### 4. リアクティブスコープを最小化

```typescript
// 悪い例: リスト全体が再レンダー
createEffect(() => {
  renderList(items());
});

// 良い例: 変更されたアイテムだけ更新
<For each={items}>
  {(item) => <Item data={item} />}
</For>
```

## ベンチマーク環境

- Vitest 2.1.9 (Browser Mode)
- Playwright (Chromium, Firefox, WebKit)
- Node.js v20+
- MoonBit 0.1.x
