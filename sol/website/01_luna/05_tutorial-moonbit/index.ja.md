---
title: "チュートリアル: MoonBit"
---

# MoonBit チュートリアル

MoonBit で Luna のリアクティブプリミティブとサーバーサイドレンダリングを学びます。

## 学習内容

| セクション | トピック |
|-----------|---------|
| **導入** | 基本、Signals、Effects、Memos |
| **リアクティビティ** | バッチ更新、Untrack、ネストした Effects |
| **制御フロー** | 条件付きレンダリング、リスト、Switch |
| **ライフサイクル** | Mount、Cleanup |
| **Islands** | 部分的ハイドレーションのためのサーバーサイドレンダリング |

## 前提条件

- MoonBit の基礎（構造体、関数、トレイト）
- リアクティブプログラミングの概念の理解

## チュートリアルセクション

### 導入

1. [基本](./introduction_basics) - 最初の Luna コンポーネント
2. [Signals](./introduction_signals) - リアクティブな状態
3. [Effects](./introduction_effects) - 副作用
4. [Memos](./introduction_memos) - 計算値

### リアクティビティ

5. [バッチ更新](./reactivity_batch) - 複数の更新を結合
6. [Untrack](./reactivity_untrack) - 追跡から逃れる
7. [ネストした Effects](./reactivity_nested) - Effect の合成

### 制御フロー

8. [Show](./flow_show) - 条件付きレンダリング
9. [For](./flow_for) - リストレンダリング
10. [Switch](./flow_switch) - 複数条件

### ライフサイクル

11. [onMount](./lifecycle_onmount) - マウント時のセットアップ
12. [onCleanup](./lifecycle_oncleanup) - リソースのクリーンアップ

### Islands アーキテクチャ

13. [Islands 基本](./islands_basics) - サーバーサイドの Island セットアップ
14. [Islands State](./islands_state) - クライアントへの状態渡し
15. [Islands Triggers](./islands_triggers) - ハイドレーションタイミングの制御
16. [Web Components](./islands_webcomponents) - Shadow DOM Islands

## 関連項目

- [JavaScript チュートリアル](/ja/luna/tutorial-js/) - クライアントサイドハイドレーション
- [MoonBit API リファレンス](/ja/luna/api-moonbit/) - API 詳細
