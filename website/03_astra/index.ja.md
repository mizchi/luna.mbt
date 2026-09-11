---
title: Astra
description: MoonBit 製の静的サイトジェネレーター用 Mars ミドルウェア
---

# Astra

> **Experimental**: Astra は活発に開発中で、API は変わる可能性があります。

Astra は MoonBit 用の [Mars](https://mooncakes.io/docs/mizchi/mars/) にマウント可能な静的サイト生成ミドルウェアです。Markdown / MDX のドキュメントページをリクエスト時にレンダリングし、loader ランタイム、デフォルト CSS、Shiki シンタックスハイライトなどのバンドル済みアセットを配信します。`astra` CLI と組み合わせれば、同じ出力を静的ツリーとしてダンプ (`astra build`) したり、dev サーバーから配信 (`astra dev`) したりできます。

## Astra の特徴

ミドルウェア配信と静的ダンプは、**同じ** `Middleware` で描画されます。`astra dev` はそれを HTTP で配信し、ビルドクローラーはミドルウェアが公開する各 URL に対して `Middleware::render_url(url)` を呼んでレスポンスボディをディスクに書き出すだけです(Mars の `Server` も localhost リスナーも介しません)。`astra dev` で正しく描画されるページは、静的ダンプでも必ず同じ結果になります。レンダラーが二系統に分かれる心配がありません。

この性質によって、Astra には 2 つの使い方があります:

- **ライブラリ**: 既存の Mars サーバーにアプリのルートと並べてマウント。同じ MoonBit バイナリで `/docs/*` のドキュメントと、ライブの API エンドポイントを同時に提供できます。
- **静的サイト**: サーバーを使わず、`astra build --out ./dist` で自己完結したディレクトリを生成。GitHub Pages、Cloudflare、Vercel、Netlify などの静的ホストにそのままデプロイできます。

### コンパイラが検査するページ

ページは `<name>.md` の代わりに `<name>.mbt.md` として書けます。ルーティングは Markdown と完全に同じ — `guide/intro.mbt.md` は `/guide/intro/`、`guide/intro.ja.mbt.md` はその `ja` 版 — ですが、このファイルは同時に MoonBit の literate-markdown 形式でもあります。` ```mbt check ` とタグ付けされたフェンスは `moon check` で型検査され、`moon test` で実行されます:

````md
```mbt check
///|
test "ドキュメントのサンプルが実際に動く" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  assert_true(mw.list_urls().length() >= 0)
}
```
````

こうしたページを `moon.pkg` のあるディレクトリに置き、そのモジュールを `moon.work` に載せれば、サンプルコードは「コンパイラが一度も見ない散文」ではなくなります。[Mars にマウントする](/ja/astra/mount-on-mars/) はこの形式で書かれており、掲載されているスニペットは `moon check` のたびにコンパイルされています。単なる ` ```mbt ` や ` ```moonbit ` は従来どおり散文として扱われるので、説明用の断片もそのまま書けます。

## Sol との使い分け

| 用途 | 選ぶもの |
|------|----------|
| 主に静的なドキュメント / ブログ | **Astra** |
| 既存の Mars アプリに組み込むドキュメント | **Astra**（ミドルウェアとしてマウント） |
| ファイルベースルーティング、API ルート、サーバーアクションを伴うフル SSR | [**Sol**](/ja/sol/) |
| 1 リポジトリで両方 | Sol + `/docs/*` 配下に Astra をマウント |

Astra は Sol に依存しません。`deps: mars + markdown + luna` のみ。Sol はドキュメント生成に Astra を取り込みますが、その逆は成立しません。

## セクション

- [はじめる](/ja/astra/getting-started/) — インストール、最初のプロジェクト、最初のビルド
- [Mars にマウントする](/ja/astra/mount-on-mars/) — 既存の Mars サーバーへの組み込み方(`.mbt.md` で書かれており、サンプルはコンパイルされています)
- [デプロイ](/ja/astra/deploy/) — GitHub Pages / Cloudflare / Vercel / Netlify

## インストール

ライブラリ:

```sh
moon add mizchi/astra
moon add mizchi/mars
moon add mizchi/luna
```

CLI:

```sh
moon install mizchi/astra/cmd/astra   # → $MOON_HOME/bin/astra
# moon は無いが node がある場合
pnpm add -g @luna_ui/astra            # 0.23.0
```

## さわってみる

```bash
mkdir docs && echo "# Hello Astra" > docs/index.md
astra build --out ./dist
# dist/index.html にページが書き出される
```

i18n、MDX、ブログ、コンポーネントを使ったフル機能の例は、ソースリポジトリの [`astra/examples/sol_docs/`](https://github.com/mizchi/luna.mbt/tree/main/astra/examples/sol_docs) にあります。
