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
| Virtual DOM差分計算なし | |

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

```html
<!-- このIslandだけがJavaScriptを配信 -->
<div luna:id="counter" luna:client-trigger="visible">
  <button>Count: 0</button>
</div>
<!-- それ以外は純粋なHTML -->
```

### SSR パフォーマンス

Shadow DOM SSRのオーバーヘッドはほぼゼロ：

| 操作 | オーバーヘッド |
|-----|--------------|
| Shadow DOM テンプレート構文 | Plain HTMLと**ほぼ同等** |
| Hydration更新 | **~12%** 遅い程度 |
| Adoptable Stylesheets | **8.4倍速** |

ボトルネックは属性のエスケープ処理であり、テンプレート形式ではない。

---

## マルチターゲットアーキテクチャ

一度書けば、どこでも動く：

| ターゲット | Signal | Render | DOM |
|-----------|:------:|:------:|:---:|
| JavaScript | ✅ | ✅ | ✅ |
| Native | ✅ | ✅ | - |
| Wasm | ✅ | ✅ | - |
| Wasm-GC | ✅ | ✅ | - |

コアのリアクティビティは全MoonBitターゲットで動作。SSRにはNative、ブラウザにはJavaScript。

---

## クイックスタート

### インストール

```bash
npm install @luna_ui/luna
```

### コンポーネントを作成

```tsx
import { createSignal } from '@luna_ui/luna';

function Counter() {
  const [count, setCount] = createSignal(0);

  return (
    <button onClick={() => setCount(c => c + 1)}>
      Count: {count()}
    </button>
  );
}
```

### MoonBitで使用

```moonbit
let count = @luna.signal(0)
let doubled = @luna.memo(fn() { count.get() * 2 })

@luna.effect(fn() {
  println("Count: \{count.get()}, Doubled: \{doubled()}")
})

count.set(5)  // 出力: Count: 5, Doubled: 10
```

---

## 設計哲学

1. **より少ないJavaScript** - 静的コンテンツにランタイムコストは不要
2. **Fine-Grained更新** - 変更された部分だけをDOM単位で更新
3. **プログレッシブエンハンスメント** - JavaScriptなしでも動作、あればより良く
4. **型安全性** - MoonBitの型システムでコンパイル時にエラーを検出

---

## さらに詳しく

- [はじめに](/introduction/getting-started/) - インストールと最初のステップ
- [Signalsガイド](/ja/luna/signals/) - リアクティブプリミティブの詳細
- [Island Architecture](/ja/luna/islands/) - 部分的ハイドレーションのパターン
- [Luna ドキュメント](/ja/luna/) - 完全なドキュメント

---

## ステータス

> **実験的** - Lunaは活発に開発中です。APIは変更される可能性があります。

[MoonBit](https://www.moonbitlang.com/)で構築 - クラウドとエッジコンピューティング向けに設計された高速で安全な言語。

[GitHub](https://github.com/mizchi/luna) | [npm](https://www.npmjs.com/package/@luna_ui/luna)
