---
title: デプロイ
description: astra build の出力を GitHub Pages / Cloudflare / Vercel / Netlify に配信する
---

# デプロイ

`astra build` は自己完結したディレクトリを生成するので、任意の静的ホストにそのままデプロイできます。`astra.config.json` で `deploy` を指定すると、HTML と一緒にプラットフォーム固有の設定ファイルが書き出されます。

## 設定

```json
{
  "deploy": "github-pages"
}
```

実行:

```sh
astra build --out ./dist
```

## 対応プラットフォーム

| プラットフォーム | `deploy` の値 | 生成されるファイル |
|------------------|---------------|--------------------|
| 静的（デフォルト） | `static` | なし |
| Cloudflare Pages / Workers | `cloudflare` | `_routes.json` |
| GitHub Pages | `github-pages` または `github` | `.nojekyll`、`CNAME`（指定時） |
| Vercel | `vercel` | `vercel.json` |
| Netlify | `netlify` | `_headers`、`_redirects` |
| Deno Deploy | `deno` | なし（そのまま配信される） |
| Node.js | `node` | なし |

## GitHub Pages

```json
{
  "deploy": "github-pages",
  "base": "/my-repo/",
  "github": {
    "repo": "mizchi/my-repo",
    "branch": "gh-pages"
  }
}
```

GitHub Pages はユーザー / 組織サイトを `/<repo>/` 配下で配信するため、`base` をリポジトリパスに合わせる必要があります。`.nojekyll` が出力されるので、`_` で始まるファイル（`_astro` チャンクなど）が除外されません。

## Cloudflare Pages

```json
{
  "deploy": "cloudflare",
  "base": "/"
}
```

Cloudflare のエッジランタイムが静的 / 動的パスを区別できるよう `_routes.json` が出力されます。同じ出力に Functions を共存させても衝突しません。

## 検索インデックス (pagefind)

Astra 自体は検索インデックスを生成しません。全文検索が必要なら、ビルド出力に対して pagefind を走らせます:

```sh
astra build --out ./dist
pnpm exec pagefind --site ./dist
```

pagefind が生成する `dist/pagefind/` は、バンドル済み `<pagefind-ui>` コンポーネントが実行時に読み込むディレクトリです。Luna のドキュメントサイトはデプロイ前の CI でこれを実行しています — パターンは [`.github/workflows/deploy-website.yml`](https://github.com/mizchi/luna.mbt/blob/main/.github/workflows/deploy-website.yml) を参照。

## デプロイ前の検証

Luna リポジトリの `tests/integration/website-asset-integrity.test.js` は、ビルド出力のすべての HTML をクロールし、ローカル参照 (`src` / `href`) を解析して、各リソースの存在を検証します。同じパターンを自分のサイトに対して走らせれば、リンク切れアセットがデプロイ前に検出できます。
