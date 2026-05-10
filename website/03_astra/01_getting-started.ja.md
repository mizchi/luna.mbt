---
title: はじめる
description: Astra のインストール、初回プロジェクト作成、ビルド
---

# はじめる

## 前提

- MoonBit ツールチェーン (`moon`)
- CLI として `moon install mizchi/astra/cmd/astra` または `pnpm add -g @luna_ui/astra`

npm ラッパーは、Node.js は入っているが MoonBit ツールチェーンが無い場合のために用意されています。どちらの経路でも `$PATH` には同じバイナリが入ります。

## プロジェクト構成

Astra はコンテンツツリーを `docs/` から読みます（`astra.config.json` の `docs_dir` で変更可）:

```
my-docs/
├── astra.config.json     # 省略可。小規模なら無くても動く
├── docs/
│   ├── index.md          # → /
│   └── guide/
│       ├── index.md      # → /guide/
│       └── routing.md    # → /guide/routing/
└── dist/                 # → astra build の出力先（gitignore）
```

最小限の `astra.config.json`:

```json
{
  "title": "My Docs",
  "docs_dir": "docs",
  "output_dir": "dist"
}
```

省略したフィールドは `@astra.SsgConfig::default()` のデフォルト値が使われます。

## 最初のページ

`docs/index.md`:

```md
---
title: ようこそ
---

# ようこそ

このページは Astra が描画しています。
```

frontmatter の `title` はページの `<title>` と、自動生成サイドバーの両方に反映されます。

## ビルド

```sh
astra build --out ./dist
```

ミドルウェアが公開するすべての URL（Markdown ページ + バンドルアセット）をクロールし、各ページについて `<out>/<url>/index.html` を生成。アセットツリー (`/assets/main.css`、`/scripts/loader.js` など) も同じ `<out>/` 直下に書き出されます。

## dev サーバー

```sh
astra dev --port 7777
```

dev サーバーは build と同じ `Middleware::handler()` を経由するので、`http://localhost:7777` でブラウザに表示される内容と、`astra build` がディスクに書く内容は同一です。レンダラーが分裂しません。

## 次

- [Mars にマウントする](/ja/astra/mount-on-mars/) — 既存の Mars サーバーに組み込む
- [デプロイ](/ja/astra/deploy/) — ビルド出力を配信する
