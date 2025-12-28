---
title: "Islands: Triggers"
---

# ハイドレーショントリガー

Island がいつインタラクティブになるかを正確に制御します。

## 利用可能なトリガー

Luna は4つのハイドレーショントリガーを提供：

| トリガー | タイミング | ユースケース |
|---------|----------|-------------|
| `load` | ページロード時に即座 | 重要な UI、ファーストビューコンテンツ |
| `idle` | ブラウザがアイドル時 | 重要でない機能 |
| `visible` | 要素がビューポートに入った時 | 下部コンテンツ |
| `media` | メディアクエリがマッチした時 | レスポンシブ機能 |

## Load トリガー

ページロード時に即座にハイドレート：

```html
<div luna:id="search" luna:url="/static/search.js" luna:client-trigger="load">
  <!-- サーバーレンダリングコンテンツ -->
</div>
```

**用途：**
- ヘッダー検索ボックス
- ナビゲーションメニュー
- 重要なインタラクティブ要素
- ファーストビューコンテンツ

## Idle トリガー

ブラウザがアイドル時にハイドレート（`requestIdleCallback` を使用）：

```html
<div luna:id="analytics" luna:url="/static/analytics.js" luna:client-trigger="idle">
  <!-- サーバーレンダリングコンテンツ -->
</div>
```

**用途：**
- アナリティクス追跡
- 重要でないウィジェット
- バックグラウンド機能
- 低優先度インタラクション

## Visible トリガー

要素がスクロールして表示されたときにハイドレート（`IntersectionObserver` を使用）：

```html
<div luna:id="comments" luna:url="/static/comments.js" luna:client-trigger="visible">
  <!-- サーバーレンダリングコンテンツ -->
</div>
```

**用途：**
- コメントセクション
- 画像ギャラリー
- 無限スクロール
- フッターウィジェット
- 任意の下部コンテンツ

## Media トリガー

メディアクエリがマッチしたときにハイドレート：

```html
<div luna:id="sidebar" luna:url="/static/sidebar.js" luna:client-trigger="media:(min-width: 768px)">
  <!-- サーバーレンダリングコンテンツ -->
</div>
```

**用途：**
- デスクトップ専用機能
- モバイル固有コンポーネント
- レスポンシブインタラクション
- 向き依存 UI

### メディアクエリの例

```html
<!-- デスクトップのみ（768px+） -->
<div luna:client-trigger="media:(min-width: 768px)">...</div>

<!-- モバイルのみ（768px 未満） -->
<div luna:client-trigger="media:(max-width: 767px)">...</div>

<!-- ダークモード設定 -->
<div luna:client-trigger="media:(prefers-color-scheme: dark)">...</div>
```

## 適切なトリガーの選択

### 決定フロー

```
ファーストビューか？
├── はい → 初期インタラクションに重要か？
│         ├── はい → load
│         └── いいえ → idle
└── いいえ → ユーザーは必ずスクロールするか？
          ├── はい → visible
          └── いいえ → デバイス固有か？
                    ├── はい → media
                    └── いいえ → visible または idle
```

## 戦略の組み合わせ

典型的なページですべてのトリガーを使用：

```html
<div>
  <!-- 即座 - UX に重要 -->
  <div luna:id="search" luna:client-trigger="load">...</div>

  <!-- Idle - あると良いが緊急ではない -->
  <div luna:id="theme-toggle" luna:client-trigger="idle">...</div>

  <!-- 静的な記事コンテンツ - JS なし -->
  <article>...</article>

  <!-- Visible - ユーザーがスクロールしたときのみロード -->
  <div luna:id="comments" luna:client-trigger="visible">...</div>

  <!-- Media - デスクトップのみ -->
  <div luna:id="sidebar" luna:client-trigger="media:(min-width: 1024px)">...</div>
</div>
```

## 試してみよう

これらのコンポーネントにトリガーを割り当て：

1. サイト全体の検索ボックス
2. Cookie 同意バナー
3. 画像ライトボックス
4. ライブチャットウィジェット
5. モバイルハンバーガーメニュー

<details>
<summary>推奨解答</summary>

1. **検索ボックス** → `load`（重要、ファーストビュー）
2. **Cookie 同意** → `idle`（重要でない、待てる）
3. **画像ライトボックス** → `visible` または `none`（画像表示時のみ）
4. **ライブチャット** → `idle`（バックグラウンド機能）
5. **モバイルメニュー** → `media:(max-width: 767px)`（モバイルのみ）

</details>

## 次へ

[サーバーからクライアントへの State →](./islands_state) について学ぶ
