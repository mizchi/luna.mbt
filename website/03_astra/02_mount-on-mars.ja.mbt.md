---
title: Mars にマウントする
description: 既存の Mars サーバーに Astra をミドルウェアとして組み込む
---

# Mars にマウントする

`astra build` がクロールするのと同じ `Middleware` インスタンスを、任意の Mars サーバーにマウントできます。これにより、1 つの MoonBit バイナリで稼働中のアプリケーションとドキュメントを同時に配信できます。

> このページは `.mbt.md` ファイルです。以下の ` ```mbt check ` ブロックは `moon check` で型検査され、`moon test` で実行されます。サンプルコードが実際の API から乖離することはありません。

## 最小構成

```mbt check
///|
test "Mars サーバーに astra をマウントする" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  let app = @mars.Server::new()
  app.all("/*", mw.handler())
  // `to_handler()` でサーバーをリクエストハンドラに変換します。
  // 実際に listen する方法はランタイム依存です（下の注記を参照）。
  let _handler = app.to_handler()
}
```

Mars に `listen` は存在しません。`Server::to_handler()` が返すのは
`async (Request, Reader, ServerConnection) -> Unit` で、これをランタイムのアダプタが駆動します。`astra dev` はこのハンドラを Node の FFI リスナに渡しています（`astra/src/cli/dev.mbt`）。Cloudflare Workers なら代わりに `@adapters.cloudflare_handler(app, env)` を使います。

`Middleware::handler()` は Mars の `Handler` を返します。ドキュメントツリーが公開するすべてのページ URL と、`Middleware::asset_urls()` のすべてのエントリに対する GET に応答します。`Middleware::list_urls()` はその和集合を返し、ビルドクローラーが歩くのと同じ集合です。

## パス prefix でのマウント

ドキュメントを `/docs/*` に配置するには、`/*` の代わりに prefix に対してミドルウェアを登録します:

```mbt check
///|
test "astra をパス prefix の下にマウントする" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  let app = @mars.Server::new()
  app.all("/docs/*", mw.handler()) // astra のドキュメント
  let _handler = app.to_handler()
}
```

`astra.config.json` で `base: "/docs/"` を設定すれば、生成 HTML 内のリンクがルートではなく prefix 付きのパスを指すようになります。

## ミドルウェアが実際に配信するもの

各リクエストで:

1. URL を解決済みのページツリー (`docs_dir` の探索 + i18n フォールバック) と照合
2. ヒットしたら Markdown / MDX をキャッシュ済みのドキュメントパイプラインで描画して HTML を返す
3. ヒットしなければアセットリスト (`/assets/*.css`、`/scripts/*.js`、フォント、画像) を確認。ヒットしたらバンドル済みバイトを返す
4. どれにもヒットしなければ 404

別途、静的アセット用のミドルウェアを配線する必要はありません。astra がドキュメントを描画するために必要なものは、すべて `list_urls()` で列挙され、`handler()` で配信されます。

## ビルドとの一致

`astra build` は同じ 2 つのメソッドを回す薄いループです。サーバーもソケットも使いません:

```mbt check
///|
test "build は list_urls と render_url のループ" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  for url in mw.list_urls() {
    let res = mw.render_url(url)
    // `astra build` は `res.body` を `<out>/<url>/index.html` に書き出します。
    assert_true(res.status > 0)
    assert_true(res.content_type != "")
  }
}
```

これが dev と build が常に一致する理由です。差異を見つけたらバグとして扱ってください。既知のギャップ（utility CSS 抽出、sitemap 生成、Cloudflare adapter マニフェストなど）は [`astra/docs/parity-notes.md`](https://github.com/mizchi/luna.mbt/blob/main/astra/docs/parity-notes.md) で追跡しています。

## ホットリロード

`astra dev` は `docs_dir` を監視し、変更時にドキュメントツリーのリビジョンを更新します。次のリクエストでミドルウェアが新しいリビジョンを見て再レンダリング。dev パスでは MoonBit の再コンパイルは発生せず、Markdown の変更はレンダラーが走る速度で反映されます。
