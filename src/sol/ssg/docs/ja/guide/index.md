---
title: はじめに
description: Luna SSGの使い方ガイド
---

# はじめに

Luna SSG は Sol CLI に統合された静的サイトジェネレーターです。

## インストール

MoonBit と Node.js がインストールされている必要があります。

## ディレクトリ構成

```
project/
├── docs/           # デフォルト言語 (英語)
│   └── index.md
├── docs/ja/        # 日本語
│   └── index.md
├── sol.config.json
└── dist/           # 出力先
```

## 多言語対応

`sol.config.json` で言語を設定します：

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
