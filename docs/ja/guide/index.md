---
title: ガイド
---

# Luna ガイド

Luna フレームワークのガイドへようこそ。このセクションでは、Lunaのコア概念と機能について説明します。

## コア概念

### [なぜLuna?](/ja/guide/why-luna)

Lunaの設計思想、パフォーマンス特性、他のフレームワークとの比較について学びます。

- 最小限のランタイム（ローダー ~1.6KB）
- Virtual DOMを使わない細粒度リアクティビティ
- 最適なパフォーマンスのためのIsland Architecture

### [Signals](/ja/guide/signals)

SignalsはLunaのリアクティビティシステムの基盤です。リアクティブプリミティブの作成と使用方法を学びます。

- `createSignal` - リアクティブな値を作成
- `createEffect` - Signalの変更に反応
- `createMemo` - 派生値を計算

### [Islands](/ja/guide/islands)

Island Architectureは部分的なハイドレーションを可能にし、必要な場所にのみJavaScriptを配信します。

- 静的コンテンツは静的なまま
- インタラクティブなコンポーネントは独立してハイドレーション
- 複数のトリガー戦略（load, idle, visible, media）

## クイックリンク

- [はじめに](/ja/getting-started/) - インストールと最初のステップ
- [チュートリアル](/ja/tutorial/) - インタラクティブな学習パス
- [パフォーマンス](/ja/performance/) - ベンチマークと最適化のヒント
