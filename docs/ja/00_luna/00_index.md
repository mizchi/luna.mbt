---
title: Luna
---

# Luna

Luna は MoonBit と JavaScript のためのリアクティブ UI ライブラリです。細粒度リアクティビティと Island Architecture を特徴としています。

## コア概念

### [なぜ Luna?](/ja/luna/why-luna/)

Luna の設計思想、パフォーマンス特性、他のフレームワークとの比較について学びます。

- 最小限のランタイム（ローダー ~1.6KB）
- Virtual DOM を使わない細粒度リアクティビティ
- 最適なパフォーマンスのための Island Architecture

### [Signals](/ja/luna/signals/)

Signals は Luna のリアクティビティシステムの基盤です。リアクティブプリミティブの作成と使用方法を学びます。

- `createSignal` - リアクティブな値を作成
- `createEffect` - Signal の変更に反応
- `createMemo` - 派生値を計算

### [Islands](/ja/luna/islands/)

Island Architecture は部分的なハイドレーションを可能にし、必要な場所にのみ JavaScript を配信します。

- 静的コンテンツは静的なまま
- インタラクティブなコンポーネントは独立してハイドレーション
- 複数のトリガー戦略（load, idle, visible, media）

## クイックリンク

- [チュートリアル (MoonBit)](/ja/tutorial-moonbit/) - MoonBit で Luna を学ぶ
- [チュートリアル (JavaScript)](/ja/tutorial-js/) - JavaScript で Luna を学ぶ
- [Astra SSG](/ja/astra/) - 静的サイトジェネレーター
- [Sol Framework](/ja/sol/) - フルスタック SSR フレームワーク
