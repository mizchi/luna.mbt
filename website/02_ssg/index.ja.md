---
title: Sol SSG
---

# Sol SSG

> **実験的**: Sol SSGは開発中です。APIは変更される可能性があります。

Sol SSGはLunaの静的サイトジェネレーターです。Markdownからドキュメントサイトやブログを構築します。

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

- [動的ルート](/ja/ssg/dynamic-routes/) - パラメータから静的ページを生成
- [Islands](/ja/ssg/islands/) - 静的ページにインタラクティブコンポーネントを埋め込む
- [ISR](/ja/ssg/isr/) - 動的コンテンツのためのIncremental Static Regeneration

## クイックスタート

```bash
# 新規プロジェクト作成
npx @luna_ui/sol new my-docs --ssg
cd my-docs
npm install

# 開発サーバー起動
npm run dev
```

http://localhost:3355 でHMR付きプレビューが開きます。

## CLIリファレンス

Sol SSGは統合された`sol`CLIの一部になりました。プロジェクトに`sol.config.json`または`ssg`セクションを持つ`sol.config.json`がある場合、SolはSSGモードで自動的に実行されます。

```bash
# 新規SSGプロジェクト作成
sol new <name> --ssg [options]
  -t, --title <text>  サイトタイトル (デフォルト: プロジェクト名)

# HMR付き開発サーバー起動
sol dev [options]
  -p, --port <port>    ポート番号 (デフォルト: 3355)
  -c, --config <path>  設定ファイルパス

# 静的サイトをビルド
sol build [options]
  -c, --config <path>  設定ファイルパス (デフォルト: sol.config.json または sol.config.json)
  -o, --output <dir>   出力ディレクトリ

# SSGコンテンツをリント
sol lint [options]
  -c, --config <path>  設定ファイルパス
```

## 設定 (sol.config.json)

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
