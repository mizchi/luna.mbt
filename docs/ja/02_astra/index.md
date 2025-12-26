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
- **Islands対応** - インタラクティブなWeb Componentsを埋め込み可能
- **HMR** - Hot Module Replacementによる高速開発

## クイックスタート

### 1. 新規プロジェクト作成

```bash
npx @luna_ui/astra new my-docs
cd my-docs
npm install
```

### 2. 開発サーバー起動

```bash
npm run dev
```

http://localhost:3355 でHMR付きプレビューが開きます。

### 3. 本番ビルド

```bash
npm run build
```

`dist-docs/` に静的ファイルが生成されます。

## CLIリファレンス

```bash
# 新規プロジェクト作成
astra new <name> [options]
  -t, --title <text>  サイトタイトル (デフォルト: プロジェクト名)
  -h, --help          ヘルプ表示

# HMR付き開発サーバー起動
astra dev [options]
  -p, --port <port>    ポート番号 (デフォルト: 3355)
  -c, --config <path>  設定ファイルパス
  -h, --help           ヘルプ表示

# 静的サイトをビルド
astra build [options]
  -c, --config <path>  設定ファイルパス (デフォルト: astra.json)
  -o, --output <dir>   出力ディレクトリ (設定を上書き)
  -h, --help           ヘルプ表示

# ヘルプ表示
astra --help

# バージョン表示
astra --version
```

## 設定

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

### 基本オプション

| オプション | 型 | デフォルト | 説明 |
|-----------|-----|----------|------|
| `docs` | string | `"docs"` | ソースディレクトリ |
| `output` | string | `"dist"` | 出力ディレクトリ |
| `title` | string | `"Documentation"` | サイトタイトル |
| `base` | string | `"/"` | ベースURLパス |
| `trailingSlash` | boolean | `true` | URLに末尾スラッシュを使用 |
| `exclude` | string[] | `[]` | 除外ディレクトリ |

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

### テーマ

```json
{
  "theme": {
    "primaryColor": "#6366f1",
    "logo": "/logo.svg",
    "footer": {
      "message": "MITライセンスでリリース",
      "copyright": "Copyright 2024 Your Name"
    },
    "socialLinks": [
      { "icon": "github", "link": "https://github.com/..." }
    ]
  }
}
```

### OGP (Open Graph Protocol)

```json
{
  "ogp": {
    "siteUrl": "https://example.com",
    "image": "/og-image.png",
    "twitterHandle": "@yourhandle",
    "twitterCard": "summary_large_image"
  }
}
```

## コンテンツ構造

```
docs/
├── index.md              # ホームページ (/)
├── 00_introduction/      # /introduction/
│   └── index.md
├── 01_guide/             # /guide/
│   ├── index.md
│   ├── 01_basics.md      # /guide/basics/
│   └── 02_advanced.md    # /guide/advanced/
└── components/           # Web Components
    └── my-counter.js
```

数字プレフィックス（`00_`、`01_`）は順序制御用で、URLからは除去されます。

## Markdown機能

### フロントマター

```markdown
---
title: ページタイトル
description: SEO用の説明文
layout: doc
sidebar: true
---

# ここにコンテンツ
```

#### フロントマターオプション

| オプション | 型 | デフォルト | 説明 |
|-----------|-----|----------|------|
| `title` | string | - | ページタイトル |
| `description` | string | - | SEO用説明文 |
| `layout` | string | `"doc"` | レイアウト: `doc`, `home` |
| `sidebar` | boolean | `true` | サイドバー表示 |
| `image` | string | - | OGP画像（サイト設定を上書き） |

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

## Web Components

静的ページにインタラクティブなWeb Componentsを埋め込めます。

### コンポーネント作成

`docs/components/` にコンポーネントを配置:

```javascript
// docs/components/my-counter.js
export function hydrate(element, state, name) {
  let count = parseInt(element.getAttribute('initial') || '0', 10);

  const render = () => {
    element.innerHTML = `<button>${count}</button>`;
    element.querySelector("button").onclick = () => {
      count++;
      render();
    };
  };

  render();
}
```

### Markdownでの使用

```html
<my-counter initial="5" luna:trigger="load"></my-counter>
```

### トリガータイプ

| トリガー | 説明 |
|---------|------|
| `load` | ページ読み込み時に即座にハイドレート（デフォルト） |
| `idle` | ブラウザがアイドル時にハイドレート |
| `visible` | 要素がビューポートに入った時にハイドレート |
| `media` | メディアクエリにマッチした時にハイドレート |
| `none` | 手動ハイドレーションのみ |

## 完全な設定例

```json
{
  "docs": "docs",
  "output": "dist",
  "title": "My Documentation",
  "base": "/",
  "trailingSlash": true,
  "exclude": ["internal", "drafts"],
  "i18n": {
    "defaultLocale": "en",
    "locales": [
      { "code": "en", "label": "English", "path": "" },
      { "code": "ja", "label": "日本語", "path": "ja" }
    ]
  },
  "nav": [
    { "text": "ガイド", "link": "/guide/" },
    { "text": "API", "link": "/api/" }
  ],
  "sidebar": "auto",
  "theme": {
    "primaryColor": "#6366f1",
    "logo": "/logo.svg",
    "footer": {
      "message": "MITライセンスでリリース",
      "copyright": "Copyright 2024"
    },
    "socialLinks": [
      { "icon": "github", "link": "https://github.com/..." }
    ]
  },
  "ogp": {
    "siteUrl": "https://example.com",
    "image": "/og-image.png"
  }
}
```
