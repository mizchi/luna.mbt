---
title: Luna SSG
description: MoonBitで作られた静的サイトジェネレーター
layout: home
---

# Luna SSG

MoonBit で実装された静的サイトジェネレーター。VitePress/Docusaurus 風のドキュメントサイトを生成できます。

## 特徴

- **ファイルベースルーティング** - `docs/` 配下のMarkdownから自動ルート生成
- **Frontmatter対応** - YAMLでページメタデータを定義
- **VitePress風テーマ** - ナビ、サイドバー、目次を自動生成
- **多言語対応** - 複数言語のドキュメントをサポート
- **Island Architecture** - 部分的Hydration対応（将来）

## クイックスタート

```bash
# docsディレクトリを作成
mkdir docs

# Markdownファイルを追加
echo "# Hello World" > docs/index.md

# ビルド実行
sol ssg build
```
