---
title: JavaScript API
---

# JavaScript API リファレンス

`@luna_ui/luna` npm パッケージを 2 ページで扱います。掲載している例はすべて、ビルド済みの `dist/` に対して実行して確認しています。

## リアクティブプリミティブ

| 関数 | 説明 |
|------|------|
| [`createSignal`](./signals#createsignal) | リアクティブな Signal を作成 |
| [`createEffect`](./signals#createeffect) | 副作用。マイクロタスクへ遅延 |
| [`createRenderEffect`](./signals#createeffect) | 副作用。同期実行 |
| [`createMemo`](./signals#creatememo) | キャッシュ付き派生値 |
| [`batch`](./signals#batch) | 更新をまとめる |
| [`untrack`](./signals#untrack) | 追跡せずに実行 |
| [`onCleanup`](./signals#oncleanup) | effect のクリーンアップを登録 |
| [`onMount`](./signals#onmount) | 追跡せずに 1 回実行 |
| [`on`](./signals#on) | 依存を明示指定。`{ defer }` あり |
| [`createRoot`](./signals#createroot) | 破棄できるリアクティブスコープ |
| [Context API](./signals#context-api) | `createContext` / `provide` / `useContext` |
| [Resource API](./signals#resource-api) | `createResource` / `createDeferred` |
| [Store API](./signals#store-api) | `createStore` / `produce` / `reconcile` |
| [ユーティリティ](./signals) | `mergeProps` / `splitProps` |

## Island ハイドレーション

| Export | 説明 |
|--------|------|
| [`export default function hydrate`](./islands#hydration-api) | wc-loader が呼ぶ Island モジュールのエントリポイント |
| [`render(el, jsx)`](./islands) | ハイドレーション時に JSX を要素へ描画 |
| [トリガー](./islands) | `load` / `idle` / `visible` / `media` / `none` |

## 制御フローコンポーネント

| コンポーネント | 説明 |
|---------------|------|
| [`Show`](./islands) | 条件付き描画 |
| [`For` / `Index`](./islands) | 参照ベース / インデックスベースのリスト描画 |
| [`Switch` / `Match`](./islands) | 多分岐の条件描画 |
| [`Portal`](./islands) | 別の DOM 位置へ描画 |
| [`Provider`](./islands) | context の値を提供 |

`Portal` と `Provider` は children を呼び出すため、children は**関数**でなければなりません。

## セクション

- [Signals](./signals) — リアクティブな状態管理
- [Islands](./islands) — 部分ハイドレーション、制御フロー、DOM ユーティリティ
