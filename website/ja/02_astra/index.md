---
title: Astra SSG
---

# Astra SSG

> **実験的**: Astraは開発中です。APIは変更される可能性があります。

AstraはLunaの静的サイトジェネレーターです。Markdownからドキュメントサイトやブログを構築します。

## 特徴

- **Markdownベース** - フロントマター付きMarkdownでコンテンツを記述
- **シンタックスハイライト** - Shikiによるコードブロックのハイライト
- **i18nサポート** - 多言語ドキュメント対応
- **自動サイドバー** - ディレクトリ構造からナビゲーション自動生成
- **Islands対応** - インタラクティブなWeb Componentsを埋め込み可能
- **ISR** - Stale-While-RevalidateによるIncremental Static Regeneration
- **HMR** - Hot Module Replacementによる高速開発
- **SPAナビゲーション** - View Transitionsによるスムーズな遷移

## ガイド

- [動的ルート](/ja/astra/dynamic-routes/) - パラメータから静的ページを生成
- [Islands](/ja/astra/islands/) - 静的ページにインタラクティブコンポーネントを埋め込む
- [ISR](/ja/astra/isr/) - 動的コンテンツのためのIncremental Static Regeneration

## クイックスタート

```bash
# 新規プロジェクト作成
npx @luna_ui/astra new my-docs
cd my-docs
npm install

# 開発サーバー起動
npm run dev
```

http://localhost:3355 でHMR付きプレビューが開きます。

## CLIリファレンス

```bash
# 新規プロジェクト作成
astra new <name> [options]
  -t, --title <text>  サイトタイトル (デフォルト: プロジェクト名)

# HMR付き開発サーバー起動
astra dev [options]
  -p, --port <port>    ポート番号 (デフォルト: 3355)
  -c, --config <path>  設定ファイルパス

# 静的サイトをビルド
astra build [options]
  -c, --config <path>  設定ファイルパス (デフォルト: astra.json)
  -o, --output <dir>   出力ディレクトリ
```

## 設定 (astra.json)

```json
{
  "docs": "docs",
  "output": "dist",
  "title": "My Docs",
  "base": "/",
  "trailingSlash": true,
  "sidebar": "auto",
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
  ]
}
```

## ディレクトリ構造

```
docs/
├── index.md              # ホームページ (/)
├── 00_introduction/      # /introduction/
│   └── index.md
├── 01_guide/             # /guide/
│   ├── index.md
│   ├── 01_basics.md      # /guide/basics/
│   └── 02_advanced.md    # /guide/advanced/
└── ja/                   # 日本語版
    ├── index.md
    └── ...
```

数字プレフィックス（`00_`、`01_`）は順序制御用で、URLからは除去されます。

## フロントマター

```markdown
---
title: ページタイトル
description: SEO用の説明文
layout: doc
sidebar: true
---

# ここにコンテンツ
```

## Web Components

静的ページにインタラクティブなコンポーネントを埋め込み：

```html
<my-counter initial="5" luna:trigger="visible"></my-counter>
```

| トリガー | 説明 |
|---------|------|
| `load` | ページ読み込み時に即座にハイドレート |
| `idle` | ブラウザがアイドル時にハイドレート |
| `visible` | ビューポートに入った時にハイドレート |
| `media` | メディアクエリにマッチした時 |

## 関連項目

- [Luna UI](/ja/luna/) - リアクティビティシステム
- [Sol Framework](/ja/sol/) - フルスタックSSR
- [Stella](/ja/stella/) - Web Components
