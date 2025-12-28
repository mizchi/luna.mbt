---
title: "Luna UI"
layout: home
---

# Luna UI

**MoonBitで書かれた超高速リアクティブUIフレームワーク**

Fine-Grained ReactivityとIsland Architectureの融合。より少ないJavaScriptで、より速く。

---

## なぜ Luna なのか？

### 最小ランタイム、最大パフォーマンス

| コンポーネント | サイズ |
|--------------|--------|
| Hydration Loader | **~1.6 KB** |
| Island Runtime | **~3.2 KB** |
| 合計 | **~6.7 KB** |

LunaのIsland Architectureは、インタラクティブなコンポーネントだけにJavaScriptを配信。静的コンテンツは静的なまま。

### Fine-Grained Reactivity

Virtual DOMなし。差分計算なし。Signal単位でDOMを直接更新。

```typescript
import { createSignal, createEffect } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);

// このテキストノードだけが更新される
createEffect(() => console.log(count()));

setCount(1);  // Logs: 1
setCount(c => c + 1);  // Logs: 2
```

### Island Architecture

スマートなローディング戦略による部分的ハイドレーション：

| トリガー | タイミング |
|---------|-----------|
| `load` | ページロード時に即座 |
| `idle` | ブラウザのアイドル時 |
| `visible` | ビューポートに入った時 |
| `media` | メディアクエリにマッチした時 |

---

## クイックスタート

### JavaScript/TypeScript

```bash
npx @luna_ui/luna new myapp
cd myapp && npm install && npm run dev
```

### MoonBit

```bash
npx @luna_ui/luna new myapp --mbt
cd myapp && moon update && npm install && npm run dev
```

---

## コード例

### JavaScript

```typescript
import { createSignal, createEffect } from '@luna_ui/luna';

const [count, setCount] = createSignal(0);
createEffect(() => console.log(count()));
setCount(1);  // Logs: 1
```

### MoonBit

```moonbit
let count = @signal.signal(0)
let doubled = @signal.memo(fn() { count.get() * 2 })

@signal.effect(fn() {
  println("Count: \{count.get()}, Doubled: \{doubled()}")
})

count.set(5)  // 出力: Count: 5, Doubled: 10
```

---

## エコシステム

| プロジェクト | 説明 |
|------------|------|
| [Luna UI](/ja/luna/) | コアUIライブラリ - Signals、Islands、Hydration |
| [Astra](/ja/astra/) | 静的サイトジェネレーター (SSG) |
| [Stella](/ja/stella/) | Web Componentsビルドシステム |
| [Sol](/ja/sol/) | フルスタックSSRフレームワーク |

---

## ステータス

> **実験的** - Lunaは活発に開発中です。APIは変更される可能性があります。

[MoonBit](https://www.moonbitlang.com/)で構築 - クラウドとエッジコンピューティング向けに設計された高速で安全な言語。

[GitHub](https://github.com/mizchi/luna.mbt) | [npm](https://www.npmjs.com/package/@luna_ui/luna)
