---
title: Islands
description: 静的ページにインタラクティブな Luna コンポーネントを埋め込む
---

# Islands アーキテクチャ

Islands を使用すると、静的ページ内にインタラクティブな Luna（MoonBit）コンポーネントを埋め込むことができます。ページは静的 HTML としてレンダリングされ、特定のインタラクティブ領域（「島」）がクライアントでハイドレートされます。

## 概要

```
┌─────────────────────────────────────┐
│  静的 HTML (SSG)                     │
│  ┌─────────────────────────────┐    │
│  │  Island (インタラクティブ)    │    │
│  │  - Luna/MoonBit コンポーネント │    │
│  │  - クライアントでハイドレート  │    │
│  └─────────────────────────────┘    │
│  さらに静的コンテンツ...             │
└─────────────────────────────────────┘
```

## 設定

### 1. sol.config.json

Islands ディレクトリを設定します：

```json
{
  "islands": {
    "dir": "docs/public/islands",
    "basePath": "/islands/"
  }
}
```

### 2. コンポーネントのビルド

`hydrate` エクスポートを持つ MoonBit コンポーネントを作成します：

```moonbit
// src/examples/wiki/main.mbt
pub fn hydrate(el : @dom.Element, _state : @js.Any) -> Unit {
  // コンポーネントを初期化
  let container = el |> @luna_dom.DomElement::from_dom
  // ... レンダリングロジック
}
```

パッケージ設定（`moon.pkg.json`）：

```json
{
  "is-main": true,
  "supported-targets": ["js"],
  "import": [
    "mizchi/luna/luna/signal",
    { "path": "mizchi/luna/luna/dom/element", "alias": "dom" },
    { "path": "mizchi/js/browser/dom", "alias": "js_dom" },
    { "path": "mizchi/js/core", "alias": "js" }
  ],
  "link": {
    "js": {
      "format": "esm",
      "exports": ["hydrate"]
    }
  }
}
```

### 3. Islands ディレクトリにコピー

ビルド後、コンパイルされた JS を Islands ディレクトリにコピーします：

```bash
moon build --target js
cp target/js/release/build/examples/wiki/wiki.js docs/public/islands/
```

### 4. Markdown で使用

Markdown で Island を参照します：

```markdown
---
title: Wiki
islands:
  - wiki
---

# Wiki デモ

<Island name="wiki" trigger="load" />
```

## Island ディレクティブ構文

```html
<Island name="component-name" trigger="load" />
```

### 属性

| 属性 | 説明 |
|-----|------|
| `name` | コンポーネント名（.js を除いたファイル名に一致） |
| `trigger` | ハイドレーショントリガー（下記参照） |

### トリガー型

| トリガー | 説明 |
|--------|------|
| `load` | ページロード時に即座にハイドレート |
| `idle` | ブラウザがアイドル時にハイドレート |
| `visible` | 要素がビューポートに入った時にハイドレート |

## BrowserRouter によるクライアントサイドルーティング

Islands は Luna の BrowserRouter を使用した完全なクライアントサイドルーティングを実装できます：

```moonbit
fn create_routes() -> Array[@routes.Routes] {
  [
    Page(path="", component="home", title="Home", meta=[]),
    Page(path="/:slug", component="page", title="Page", meta=[]),
  ]
}

pub fn hydrate(el : @dom.Element, _state : @js.Any) -> Unit {
  let base = "/wiki"
  let routes = create_routes()
  let router = @router.BrowserRouter::new(routes, base~)

  let container = el |> @luna_dom.DomElement::from_dom
  render_app(router, container)
}
```

これにより以下が可能になります：
- ページリロードなしのクライアントサイドナビゲーション
- 動的 URL パラメータ（`:slug`）
- ブラウザ履歴（戻る/進む）サポート

## 生成される HTML

Island ディレクティブは以下を生成します：

```html
<!--luna:island:wiki url=/islands/wiki.js trigger=load-->
<div luna:id="wiki"
     luna:url="/islands/wiki.js"
     luna:state="{}"
     luna:client-trigger="load">
</div>
<!--/luna:island:wiki-->
```

Luna ローダーは自動的にこれらの要素を検出してハイドレートします。

## 例：動的ルーティングを持つ Wiki

完全な例は `examples/sol_docs/docs/wiki/` を参照してください：

1. **静的エントリー**: `/wiki/` - Island プレースホルダーを持つ単一の HTML ページ
2. **クライアントルーティング**: BrowserRouter が `/wiki/:slug` パターンを処理
3. **サーバー不要**: 完全に静的、任意のファイルサーバーで動作

```
/wiki/                    → Wiki Home (インデックスページ)
/wiki/getting-started     → BrowserRouter で処理
/wiki/configuration       → BrowserRouter で処理
```

## Islands vs ダイナミックルート

| ユースケース | ソリューション |
|------------|--------------|
| ブログ投稿（SEO 重要） | ダイナミックルート（`_slug_`） |
| インタラクティブなドキュメント | Islands |
| 静的サイト内の SPA | Islands + BrowserRouter |
| 静的コンテンツページ | 通常の Markdown |
