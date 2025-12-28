---
title: ダイナミックルート
description: 動的パラメータから静的ページを生成
---

# ダイナミックルート

Astra は `_param_` ディレクトリ命名パターンを使用した動的ルート生成をサポートしています。これにより、単一のテンプレートから複数の静的ページを生成できます。

## 基本的な使い方

### ディレクトリ構造

```
docs/
└── posts/
    ├── index.md              # 投稿一覧ページ
    └── _slug_/               # 動的パラメータディレクトリ
        ├── page.json         # 静的パラメータ設定
        └── index.md          # 各ページのテンプレート
```

### 設定（page.json）

`staticParams` を使用して生成するページを定義します：

```json
{
  "staticParams": [
    { "slug": "hello-world" },
    { "slug": "getting-started" },
    { "slug": "advanced-topics" }
  ]
}
```

### テンプレート（index.md）

テンプレートファイルはすべての生成ページに使用されます：

```markdown
---
description: ブログ投稿
---

# 投稿ページ

このコンテンツはすべての生成ページで共有されます。
```

### 生成される出力

上記の設定で、Astra は以下を生成します：

- `/posts/hello-world/index.html`
- `/posts/getting-started/index.html`
- `/posts/advanced-topics/index.html`

## パラメータ命名

パラメータ名はディレクトリ名から抽出されます：

| ディレクトリ | パラメータ |
|------------|-----------|
| `_slug_` | `slug` |
| `_id_` | `id` |
| `_category_` | `category` |

## 自動生成タイトル

frontmatter で `title` が指定されていない場合、Astra はパラメータ値からタイトルを生成します：

- `hello-world` → "Hello World"
- `getting-started` → "Getting Started"

## 複数パラメータ

ネストしたディレクトリで複数のパラメータを使用できます：

```
docs/
└── blog/
    └── _category_/
        └── _slug_/
            ├── page.json
            └── index.md
```

```json
{
  "staticParams": [
    { "category": "tech", "slug": "intro-to-moonbit" },
    { "category": "tech", "slug": "advanced-patterns" },
    { "category": "news", "slug": "release-notes" }
  ]
}
```

## クライアントサイドルーティングとの比較

| 機能 | ダイナミックルート（`_slug_`） | クライアントサイド（BrowserRouter） |
|-----|------------------------------|-----------------------------------|
| SEO | 完全な静的 HTML | 初期ページのみ |
| ビルド時間 | すべてのページを生成 | 単一のエントリーポイント |
| ナビゲーション | フルページリロード | SPA のような即時遷移 |
| ユースケース | ブログ投稿、ドキュメント | インタラクティブアプリ |

クライアントサイドの動的ルーティング（SPA）については、[Islands](/ja/astra/islands/) を参照してください。
