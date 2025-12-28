---
title: "Islands: Triggers"
---

# ハイドレーショントリガー

Island がいつインタラクティブになるかを制御します。

## 利用可能なトリガー

Luna は4つのハイドレーショントリガーを提供：

| トリガー | タイミング | ユースケース |
|---------|----------|-------------|
| `Load` | ページロード時に即座 | 重要な UI |
| `Idle` | ブラウザがアイドル時 | 重要でない機能 |
| `Visible` | 要素がビューポートに入った時 | 下部コンテンツ |
| `Media(query)` | メディアクエリがマッチした時 | レスポンシブ機能 |

## トリガーの使用

```moonbit
using @luna { Load, Idle, Visible, Media }

// 即座にハイドレート
island(id="search", trigger=Load, ...)

// ブラウザがアイドル時にハイドレート
island(id="analytics", trigger=Idle, ...)

// 表示時にハイドレート
island(id="comments", trigger=Visible, ...)

// メディアクエリマッチ時にハイドレート
island(id="sidebar", trigger=Media("(min-width: 768px)"), ...)
```

## 適切なトリガーの選択

### 決定フロー

```
ファーストビューか？
├── はい → 初期インタラクションに重要か？
│         ├── はい → Load
│         └── いいえ → Idle
└── いいえ → ユーザーは必ずスクロールするか？
          ├── はい → Visible
          └── いいえ → デバイス固有か？
                    ├── はい → Media
                    └── いいえ → Visible または Idle
```

## 戦略の組み合わせ

典型的なページ：

```moonbit
fn page() -> @luna.Node {
  div([
    // 即座 - UX に重要
    island(id="search", trigger=Load, ...),

    // Idle - あると良いが緊急ではない
    island(id="theme-toggle", trigger=Idle, ...),

    // 静的な記事コンテンツ
    article([text("...")]),

    // Visible - スクロール時のみロード
    island(id="comments", trigger=Visible, ...),

    // Media - デスクトップのみ
    island(id="sidebar", trigger=Media("(min-width: 1024px)"), ...),
  ])
}
```

## HTML 出力

各トリガーは `luna:client-trigger` 属性を生成：

```html
<div luna:client-trigger="load">...</div>
<div luna:client-trigger="idle">...</div>
<div luna:client-trigger="visible">...</div>
<div luna:client-trigger="media:(min-width: 768px)">...</div>
```

## 試してみよう

これらのコンポーネントにトリガーを割り当て：
1. サイト全体の検索ボックス
2. Cookie 同意バナー
3. 画像ライトボックス
4. モバイルハンバーガーメニュー

## 次へ

[Web Components Islands →](./islands_webcomponents) について学ぶ
