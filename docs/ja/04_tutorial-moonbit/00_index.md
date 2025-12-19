---
title: チュートリアル
---

# Luna チュートリアル

基本概念から応用パターンまで、Lunaを段階的に学びましょう。

## 構成

このチュートリアルは段階的に進む構成になっています：

### 1. イントロダクション

まずここから始めましょう。Lunaのリアクティブシステムの基礎を学びます。

| レッスン | トピック |
|---------|---------|
| [Basics](/tutorial/introduction_basics) | 最初のLunaコンポーネント |
| [Signals](/tutorial/introduction_signals) | リアクティブな状態管理 |
| [Effects](/tutorial/introduction_effects) | 副作用とサブスクリプション |
| [Memos](/tutorial/introduction_memos) | 算出値/派生値 |

### 2. リアクティビティ

Lunaのリアクティビティシステムを深掘りします。

| レッスン | トピック |
|---------|---------|
| [Batch](/tutorial/reactivity_batch) | 複数更新のバッチ処理 |
| [Untrack](/tutorial/reactivity_untrack) | 追跡からのオプトアウト |
| [Nested Effects](/tutorial/reactivity_nested) | Effectの合成 |

### 3. 制御フロー

条件付きレンダリングとリスト。

| レッスン | トピック |
|---------|---------|
| [Show](/tutorial/flow_show) | 条件付きレンダリング |
| [For](/tutorial/flow_for) | リストレンダリング |
| [Switch](/tutorial/flow_switch) | 複数条件 |

### 4. ライフサイクル

コンポーネントのライフサイクル管理。

| レッスン | トピック |
|---------|---------|
| [onMount](/tutorial/lifecycle_onmount) | マウント後にコードを実行 |
| [onCleanup](/tutorial/lifecycle_oncleanup) | リソースのクリーンアップ |

### 5. Islands

Lunaの部分的ハイドレーションアーキテクチャ。

| レッスン | トピック |
|---------|---------|
| [Basics](/tutorial/islands_basics) | 最初のIslandを作成 |
| [Triggers](/tutorial/islands_triggers) | ハイドレーションタイミングの制御 |
| [State](/tutorial/islands_state) | サーバーからクライアントへの状態転送 |
| [Web Components](/tutorial/islands_webcomponents) | Shadow DOMを持つIslands |

## 前提知識

- HTML、CSS、JavaScript/TypeScriptの基本知識
- コンポーネントベースのUI開発に慣れていること

## コード例

各レッスンには以下が含まれます：

- **説明** - 概念の概要
- **コード** - TypeScriptとMoonBitの動作例
- **試してみよう** - インタラクティブな練習問題

## APIリファレンス

完全なAPIドキュメントは以下を参照：

- [Signals API](/ja/guide/signals)
- [Islands API](/ja/guide/islands)
- [パフォーマンス](/ja/performance/)
