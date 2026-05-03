---
title: なぜ Luna なのか？
---

# なぜ Luna なのか？

## 既存フレームワークへの不満

- **React** - パフォーマンスが重要なアプリケーションには大きすぎる
- **Qwik / Solid** - コンパイル時の変換がデバッグの邪魔になる
- **WebComponents ファーストのフレームワークがなかった**

## Luna の特徴

### コンパイル時最適化が不要なほど小さい

| フレームワーク | バンドルサイズ |
|--------------|--------------|
| **Luna** | **~6.7 KB** |
| Preact | ~20 KB |
| Solid | ~7 KB |
| Vue 3 | ~33 KB |
| React | ~42 KB |

### WebComponents SSR（世界初）

Luna は **WebComponents SSR + Hydration を完全サポートした初めてのフレームワーク** です。

```html
<my-counter luna:client-trigger="visible">
  <template shadowrootmode="open">
    <button>Count: 0</button>
  </template>
</my-counter>
```

### ランタイムパフォーマンス

| シナリオ | Luna | React |
|---------|------|-------|
| 100×100 DOM シューティングゲーム | **60 FPS** | 12 FPS |

Fine-grained reactivity により、実際のシナリオで **5倍のパフォーマンス** を実現。

### MoonBit で書かれている

| 観点 | JavaScript フレームワーク | Luna (MoonBit) |
|------|------------------------|----------------|
| 型安全性 | ランタイムエラー | コンパイル時エラー |
| SSR パフォーマンス | V8 オーバーヘッド | ネイティブ速度 |
| デッドコード | Tree-shaking | 確実な除去 |

## Fine-Grained Reactivity

Virtual DOM なし。差分計算なし。Signal 単位で DOM を直接更新。

```
Virtual DOM: State → Create Tree → Diff → Patch (O(n))
Luna:        Signal → Direct DOM Update (O(1))
```

## Island Architecture

スマートなローディング戦略による部分的ハイドレーション：

| トリガー | タイミング |
|---------|-----------|
| `load` | ページロード時に即座 |
| `idle` | ブラウザのアイドル時 |
| `visible` | ビューポートに入った時 |
| `media` | メディアクエリにマッチした時 |
