---
title: Sol SSG (Astra へ移行)
---

# Sol SSG → Astra

> **このページは旧リンク互換のために残しています。**
> Sol 内蔵の SSG モード (`sol new --ssg`、静的サイト向けの `sol build`)
> は sol 0.16 で **[Astra](/ja/astra/)** として独立しました。
> `sol new` の `--ssg` フラグも同時に削除されています。

ドキュメント / ブログ / 静的サイト用途は Astra を直接使用してください:

- [Astra 概要](/ja/astra/)
- [Astra — はじめる](/ja/astra/getting-started/)
- [Astra — Mars にマウントする](/ja/astra/mount-on-mars/)
- [Astra — デプロイ](/ja/astra/deploy/)

## 分離理由

Astra は Sol に依存しません (`deps: mars + markdown + luna`)。
ビルド経路は sol サーバーを必要としなくなり、`astra build` は
プロセス内ミドルウェアが配信できる全 URL を巡回してレスポンス本文を
ディスクに書き出します。そのため「一度ビルドして任意の静的ホストに
配信する」 形式が標準的なデプロイです (Cloudflare Workers Static Assets、
GitHub Pages、S3 など)。詳細は [astra README](https://github.com/mizchi/luna.mbt/tree/main/astra)
を参照してください。

## 移行チートシート

| 旧 (sol ≤ 0.15) | 新 (astra 0.22.3+) |
|----------------|--------------------|
| `sol new my-docs --ssg` | `mkdir my-docs && cd my-docs && mkdir docs && echo "# Hello" > docs/index.md` |
| `sol dev` (SSG モード) | `astra dev` |
| `sol build` (SSG モード) | `astra build --out ./dist` |
| `sol.config.json` の `ssg`/`docs` セクション | `astra.config.json` (同じフィールド名。レガシープロジェクトのため `sol.config.json` はフォールバックとして読まれる) |

元のクイックスタート相当は Astra をインストールして [はじめる](/ja/astra/getting-started/) を参照してください:

```sh
moon install mizchi/astra/cmd/astra   # または: pnpm add -g @luna_ui/astra
```

## ハイブリッド (Sol アプリ + Astra ドキュメント)

SSR アプリとドキュメントを 1 バイナリで配信したい場合は、Sol のルートに
並べて Mars ミドルウェアとして Astra をマウントできます。詳細は
[Astra — Mars にマウントする](/ja/astra/mount-on-mars/) を参照してください。
