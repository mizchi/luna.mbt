---
title: Astra SSG
---

# Astra SSG

> **実験的**: Astraは開発中です。APIは変更される可能性があります。

AstraはLunaの静的サイトジェネレーターです。ドキュメントサイトやコンテンツサイトの構築に使用します。

## 特徴

- **Markdownベース** - フロントマター付きMarkdownでコンテンツを記述
- **シンタックスハイライト** - Shikiによるコードブロックのハイライト
- **i18nサポート** - 多言語ドキュメント対応
- **自動サイドバー** - ディレクトリ構造からナビゲーション自動生成
- **Islands対応** - インタラクティブなLunaコンポーネントを埋め込み可能

## クイックスタート

### 1. 設定ファイルを作成

プロジェクトルートに `astra.json` を作成:

```json
{
  "docs": "docs",
  "output": "dist",
  "title": "My Docs",
  "base": "/",
  "sidebar": "auto"
}
```

### 2. コンテンツを作成

```
docs/
├── index.md           # ホームページ
├── getting-started/
│   └── index.md       # /getting-started/
└── guide/
    ├── basics.md      # /guide/basics
    └── advanced.md    # /guide/advanced
```

### 3. ビルド

```bash
astra build
```

`dist/` に出力されます。

## 設定オプション

### 基本オプション

| オプション | 型 | デフォルト | 説明 |
|-----------|-----|----------|------|
| `docs` | string | `"docs"` | ソースディレクトリ |
| `output` | string | `"dist"` | 出力ディレクトリ |
| `title` | string | `"Documentation"` | サイトタイトル |
| `base` | string | `"/"` | ベースURLパス |

### ナビゲーション

```json
{
  "nav": [
    { "text": "ガイド", "link": "/guide/" },
    { "text": "API", "link": "/api/" },
    { "text": "GitHub", "link": "https://github.com/..." }
  ]
}
```

### サイドバー

#### 自動モード

```json
{
  "sidebar": "auto"
}
```

ディレクトリ構造からサイドバーを自動生成します。

#### 手動モード

```json
{
  "sidebar": [
    {
      "text": "はじめに",
      "items": [
        { "text": "スタートガイド", "link": "/getting-started/" },
        { "text": "インストール", "link": "/installation/" }
      ]
    },
    {
      "text": "ガイド",
      "collapsed": true,
      "items": [
        { "text": "基本", "link": "/guide/basics" },
        { "text": "応用", "link": "/guide/advanced" }
      ]
    }
  ]
}
```

### 国際化 (i18n)

```json
{
  "i18n": {
    "defaultLocale": "en",
    "locales": [
      { "code": "en", "label": "English", "path": "" },
      { "code": "ja", "label": "日本語", "path": "ja" }
    ]
  }
}
```

i18n用のディレクトリ構造:

```
docs/
├── index.md           # 英語（デフォルト）
├── guide/
│   └── basics.md
└── ja/                # 日本語
    ├── index.md
    └── guide/
        └── basics.md
```

### 除外ディレクトリ

```json
{
  "exclude": ["internal", "drafts"]
}
```

### テーマ

```json
{
  "theme": {
    "primaryColor": "#6366f1",
    "logo": "/logo.svg",
    "footer": {
      "message": "MITライセンスでリリース",
      "copyright": "Copyright 2024 Your Name"
    }
  }
}
```

## Markdown機能

### フロントマター

```markdown
---
title: ページタイトル
description: SEO用の説明文
---

# ここにコンテンツ
```

### コードブロック

````markdown
```typescript
const greeting = "Hello, World!";
```

```moonbit
fn main {
  println("Hello, World!")
}
```
````

### テーブル

```markdown
| 機能 | 状態 |
|-----|------|
| Markdown | ✅ |
| シンタックスハイライト | ✅ |
```

## CLIリファレンス

```bash
# 静的サイトをビルド
astra build

# カスタム出力先でビルド
astra build -o public

# カスタム設定でビルド
astra build -c custom.json

# ヘルプを表示
astra --help
```

## 完全な設定例

```json
{
  "docs": "docs",
  "output": "dist",
  "title": "Luna Documentation",
  "base": "/",
  "exclude": ["internal"],
  "i18n": {
    "defaultLocale": "en",
    "locales": [
      { "code": "en", "label": "English", "path": "" },
      { "code": "ja", "label": "日本語", "path": "ja" }
    ]
  },
  "nav": [
    { "text": "ガイド", "link": "/guide/" },
    { "text": "チュートリアル", "link": "/tutorial/" },
    { "text": "API", "link": "/api/" }
  ],
  "sidebar": "auto",
  "theme": {
    "primaryColor": "#6366f1",
    "footer": {
      "message": "MITライセンスでリリース",
      "copyright": "Copyright 2024"
    }
  }
}
```
