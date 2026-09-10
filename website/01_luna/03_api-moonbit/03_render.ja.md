---
title: Render API
---

# Render API

サーバーサイドレンダリング — ノードツリーを組み立てて HTML 文字列にします。このページに出てくる名前はすべて `mizchi/luna/dom/static` のものです。慣例のエイリアスは `@server_dom` で、`sol new` が生成する `moon.pkg` でもこの名前が使われます:

```
import {
  "mizchi/luna/dom/static" @server_dom,
}
```

ノードの型は `@luna.Node[Unit, String]` です。イベント型が `Unit` であることがサーバー専用であることを意味します。ブラウザ側の要素ヘルパーは `mizchi/luna/dom`(通常 `@element`)にあり、**別の、より大きい**セットです。クライアント描画については [Signals](/ja/luna/api-moonbit/signals/) とチュートリアルを参照してください。

## render

ノードツリーを HTML 文字列にします。

```moonbit
let node = @server_dom.div([@server_dom.p([@server_dom.text("Hello, World!")])])
let html = @server_dom.render(node)
// <div><p>Hello, World!</p></div>
```

### シグネチャ

```moonbit
fn render(@luna.Node[Unit, String]) -> String
```

## render_document

`<!DOCTYPE html>` 付きで描画します。

```moonbit
let doc = @server_dom.document(
  lang="en",
  head_children=[@server_dom.title("My Page")],
  body_children=[@server_dom.h1([@server_dom.text("Hello")])],
)
let html = @server_dom.render_document(doc)
// <!DOCTYPE html><html lang="en">...
```

## document

HTML ドキュメント全体を組み立てます。`head_children` と `body_children` は必須で、それ以外は省略可能です。

### シグネチャ

```moonbit
fn document(
  lang? : String,
  head_children~ : Array[@luna.Node[Unit, String]],
  body_children~ : Array[@luna.Node[Unit, String]],
  body_class? : String,
  body_id? : String,
) -> @luna.Node[Unit, String]
```

```moonbit
let doc = @server_dom.document(
  lang="ja",
  head_children=[
    @server_dom.title("Test"),
    @server_dom.meta(charset="UTF-8"),
  ],
  body_children=[@server_dom.p([@server_dom.text("Hello World")])],
)
```

## 要素ヘルパー

どのヘルパーも `id` / `class` / `style` / `attrs` を省略可能引数として取り、void 要素以外は末尾に `Array[@luna.Node[Unit, String]]` の子要素を取ります。

### ブロック・インライン

```moonbit
@server_dom.div(children)
@server_dom.div(id="main", class="container", children)
@server_dom.p(children)
@server_dom.span(children)
@server_dom.article(children)
@server_dom.section(children)
@server_dom.main_(children)     // 末尾のアンダースコア: `main` は予約語
@server_dom.header_(children)
@server_dom.footer_(children)
@server_dom.nav(children)
@server_dom.aside(children)
@server_dom.pre(children)
@server_dom.code(children)
@server_dom.em(children)
@server_dom.strong(children)
```

### 見出しとリスト

```moonbit
@server_dom.h1(children)  // h6 まで
@server_dom.ul([@server_dom.li([@server_dom.text("Item 1")])])
@server_dom.ol(children)
```

### リンクとメディア

```moonbit
@server_dom.a(href="https://example.com", target="_blank", children)
@server_dom.img(src="/image.png", alt="説明", width="64", height="64")
@server_dom.br()
@server_dom.hr()
```

### ドキュメント構造

```moonbit
@server_dom.html(lang="ja", children)
@server_dom.head(children)
@server_dom.body(children)
@server_dom.title("ページタイトル")
@server_dom.meta(charset="UTF-8")
@server_dom.meta(name="description", content="…")
```

### スクリプトとスタイル

```moonbit
@server_dom.script(src="/app.js", type_="module", defer_=true)
@server_dom.script(content="console.log('inline')")
@server_dom.style_("body { margin: 0; }")
@server_dom.link(rel="stylesheet", href="/style.css")
```

`script_trusted` と `style_trusted` は `unsafe_trusted_script` / `unsafe_trusted_style` が作る `TrustedScript` / `TrustedStyle` を取ります。自分で内容を確認したコンテンツ用です。

### フォーム

```moonbit
@server_dom.form(action="/search", http_method="get", [
  @server_dom.label(for_="q", [@server_dom.text("検索語")]),
  @server_dom.input(type_="text", name="q", placeholder="入力してください"),
  @server_dom.button([@server_dom.text("送信")]),
])
```

`input` は `value` / `disabled` / `readonly_` / `required` / `checked` も取ります。`button` は `disabled` を取ります。

### 用意されていない要素

static パッケージには `<table>` / `<tr>` / `<td>` / `<select>` / `<option>` / `<textarea>` のヘルパーはありません。`@server_dom` がカバーしているのは、このリポジトリの SSR 経路が実際に出力する要素だけです。それ以外はタグ名から要素を作る `@luna.h` を使ってください:

```moonbit
@luna.h("table", [], [
  @luna.h("tr", [], [
    @luna.h("td", [], [@server_dom.text("Item 1")]),
    @luna.h("td", [], [@server_dom.text("$10")]),
  ]),
])
```

`h` はノードのイベント型に対してジェネリックなので、同じ呼び出しがブラウザ側でも使えます。第 2 引数は `attrs` と同じ `(名前, Attr)` のタプル列です。同じタグを繰り返し書くようなら、`luna/src/dom/static/` にヘルパーを追加してください。

## text

テキストノードを作ります。描画時にエスケープされます。

```moonbit
@server_dom.text("Hello, World!")

@server_dom.text("<script>alert('xss')</script>")
// &lt;script&gt;alert('xss')&lt;/script&gt; として出力される
```

## fragment

ラッパー要素なしでノードをまとめます。

```moonbit
let nodes = @server_dom.fragment([
  @server_dom.text("A"),
  @server_dom.text("B"),
])
@server_dom.render(nodes) // "AB"
```

## attr

`attr` が包むのは**値**だけです。属性**名**は `attrs` に渡すタプルの前半に書きます:

```moonbit
@server_dom.div(
  attrs=[
    ("data-id", @server_dom.attr("123")),
    ("aria-label", @server_dom.attr("Item 123")),
  ],
  [@server_dom.text("Content")],
)
```

真偽値属性は空文字列を渡します:

```moonbit
@server_dom.input(attrs=[("disabled", @server_dom.attr(""))])
// <input disabled>
```

`input` と `button` は `disabled` を名前付き引数として持っているので、`attrs` を使うのは専用引数がない属性に限ります。

### シグネチャ

```moonbit
fn attr(String) -> @luna.Attr[Unit, String]
```

## 生 HTML(エスケープハッチ)

`raw_html` は static パッケージではなく `mizchi/luna` にあり、ジェネリックなので同じ呼び出しがサーバーでもブラウザでも動きます:

```moonbit
@luna.raw_html("<svg>…</svg>")
```

**注意**: 文字列はそのまま出力されます。信頼できる内容だけを渡してください。

## render_with_preloads

描画すると同時に、ツリーが参照している Island モジュールの URL を集めます。`<link rel="modulepreload">` の生成に使えます。

```moonbit
let result = @server_dom.render_with_preloads(node)
result.html          // String
result.preload_urls  // Array[String]

let tags = @server_dom.generate_preload_tags(result.preload_urls)
```

`render_document_with_preloads` は同じことをして DOCTYPE も付けます。

## Sol 連携ヘルパー

sol の SSR パイプライン用で、その中でのみ意味を持ちます:

| 関数 | 用途 |
|------|------|
| `sol_link(href~, children, prefetch?, replace?)` | クライアントルーティングされる `<a>` |
| `outlet(name~, children)` | ネストしたレイアウトが埋める名前付きスロット |
| `template_outlet(name~, children)` / `template_title(String)` | ストリーミングテンプレート版 |
| `wc_island(tag, id, children, styles?, state?, trigger?)` | ハイドレーショントリガー付きの Web Component Island を出力 |
| `generate_utility_css()` | ページ分のユーティリティクラス CSS |

## ユーティリティクラスヘルパー

`ucss` / `ustyles` / `ucombine` / `uhover` / `ufocus` / `uactive` / `udark` / `uon` / `uat_md` / `uat_lg` が、ユーティリティ CSS パイプライン用のアトミックなクラス名を組み立てます。組み合わせ方は [CSS](/ja/luna/css/) を参照してください。

## XSS 安全性

`text` は描画時にエスケープされ、`attr` の値もエスケープされます。エスケープされない markup を出せるのは `@luna.raw_html` / `script_trusted` / `style_trusted` の 3 つだけで、いずれも名前の時点でそれが明示されています。

## 低レベル: ノード型

`@server_dom` は `mizchi/luna/core` の 1 つの enum に対するビルダー群です。手で構築することは稀ですが、この形がヘルパーで表現できること・できないことを説明しています:

```moonbit
pub enum Node[E, A] {
  Element(VElement[E, A])       // HTML 要素
  Text(String)                  // 静的テキスト(描画時にエスケープ)
  DynamicText(() -> String)     // Signal 連動のテキスト(クライアント専用)
  Fragment(Array[Node[E, A]])
  Show(condition~, child~)      // 条件付き
  For(render~)                  // リスト
  Component(render~)
  WcIsland(VWcIsland[E, A])     // ハイドレーション境界
  Async(VAsync[E, A])
  ErrorBoundary(VErrorBoundary[E, A])
  Switch(VSwitch[E, A])
  InternalRef(VInternalRef[E, A])
  RawHtml(String)               // `@luna.raw_html` が作るもの
}

pub enum Attr[E, A] {
  VStatic(A)                    // リテラル値
  VDynamic(() -> A)             // Signal 連動(クライアント専用)
  VHandler(EventHandler[E])     // イベントハンドラ
  VAction(String)               // 宣言的アクション
}
```

`E` がイベント型、`A` が属性値の型です。SSR のノードは `Node[Unit, String]` で、イベントが `Unit` ということはハンドラを付けられないということであり、それがサーバーで描画して安全な理由です。

上のヘルパーが呼び出しているレンダラ本体は `mizchi/luna/core/render` にあります:

```moonbit
fn render_to_string(@luna.Node[E, A], preload? : Bool, size_hint? : Int) -> SSRResult
fn render_to_string_with_hydration(@luna.Node[E, A], size_hint? : Int) -> String

pub struct SSRResult {
  html : String
  preload_urls : Array[String]
}
```

`render_to_string` が返すのは `String` ではなく `SSRResult` です。HTML だけを受け取りたいときのラッパーが `@server_dom.render` です。

## API まとめ

### 描画

| 関数 | 説明 |
|------|------|
| `render(node)` | HTML 文字列に描画 |
| `render_document(node)` | DOCTYPE 付きで描画 |
| `render_with_preloads(node)` | 描画 + Island の preload URL |
| `render_document_with_preloads(node)` | 上記の両方 |
| `document(head_children~, body_children~, lang?)` | ドキュメントノードを作成 |

### 要素

| グループ | ヘルパー |
|----------|----------|
| ブロック・インライン | `div` `p` `span` `article` `section` `aside` `main_` `header_` `footer_` `nav` `pre` `code` `em` `strong` |
| 見出し | `h1`–`h6` |
| リスト | `ul` `ol` `li` |
| リンク・メディア | `a` `img` `br` `hr` |
| ドキュメント | `html` `head` `body` `title` `meta` |
| リソース | `script` `script_trusted` `style_` `style_trusted` `link` |
| フォーム | `form` `input` `button` `label` |
| SVG | `svg` と `svg_*`(path, circle, rect, text, …) |

### コンテンツ

| 関数 | 説明 |
|------|------|
| `text(content)` | テキストノード(エスケープ済み) |
| `fragment(children)` | ラッパーなしのグループ |
| `attr(value)` | `attrs` タプル列に渡す属性値 |
| `@luna.h(tag, attrs, children)` | 専用ヘルパーのない要素 |
| `@luna.raw_html(html)` | エスケープなしの markup(危険) |
