---
title: はじめに
description: Astra の使い方ガイド
---

# はじめに

Astra は MoonBit で書かれた markdown ドリブンな静的サイトジェネレーターです。
`astra build` で static tree を吐き、 任意の static host (Cloudflare Workers
Static Assets, GitHub Pages, S3, ...) に配るのが基本フロー。 同じレンダラを
Mars サーバーに mount する形態もあるが、 sol に組み込むなど特別な理由がない
限りは static path が推奨です。

## インストール

MoonBit と Node.js がインストールされている必要があります。

## ディレクトリ構成

```
project/
├── docs/           # デフォルト言語 (英語)
│   └── index.md
├── docs/ja/        # 日本語
│   └── index.md
├── astra.config.json # 設定ファイル
└── dist/             # 出力先
```

`sol.config.json` は `astra.config.json` が無い場合にのみ fallback として読まれる (sol の SSG モード時代の互換用)。 新規プロジェクトでは `astra.config.json` を使う。

## 多言語対応

`astra.config.json` で言語を設定します：

```json
{
  "ssg": {
    "i18n": {
      "defaultLocale": "en",
      "locales": [
        { "code": "en", "label": "English", "path": "" },
        { "code": "ja", "label": "日本語", "path": "ja" }
      ]
    }
  }
}
```

翻訳がない場合、自動的にデフォルト言語（英語）にフォールバックします。
