---
title: Client DOM
description: MoonBit からのマウント・イベント・ポータル・context
---

# Client DOM

`mizchi/luna/dom` は Luna のクライアント側レンダラです。要素 DSL、イベントハンドラ、
ポータル、そしてツリーをページに載せる呼び出しがここにあります。Luna 自身のサンプルは
これを `@element` として import し、デフォルトの `@dom` は `mizchi/js_browser/dom`
のブラウザバインディングに残しています:

```moonbit
import {
  "mizchi/luna/dom" @element,
  "mizchi/luna/js/resource",
  "mizchi/js_browser/dom",
  "mizchi/js/core" @js,
}
```

> このページは `.mbt.md` です。以下の ` ```mbt check ` ブロックはすべて `moon check`
> でコンパイルされ、`moon test` で実行されるので、サンプルコードがドキュメントの記述と
> 乖離することはありません。DOM に触れるサンプルは test 内の関数として書き、呼び出して
> いません。`moon test` は Node 上で動き `document` を持たないため、実行ではなく
> 型チェックの対象になります。末尾の `let _ = …` はその関数を「使用済み」と示すためのものです。

## ツリーをマウントする

`render_to` はコンテナを空にしてからマウントし、`mount_to` は既存の内容に追加します。
どちらも**構築済みの `DomNode`** を取ります:

```mbt check
///|
test "render_to は構築済みノードを要素にマウントする" {
  fn hello() -> @element.DomNode {
    @element.div() <| [@element.p() <| [@element.text("Hello, Luna")]]
  }

  fn boot() -> Unit {
    match @dom.document().getElementById("app") {
      Some(el) => @element.render_to(el, hello())
      None => println("Error: #app element not found")
    }
  }

  let _ = boot
}
```

`getElementById` が返すのは `@dom.Element` で、これがそのまま `render_to` /
`mount_to` の引数になります。`render` / `mount` の方は Luna 独自の `DomElement`
ラッパーを取るので、そちらを使うときは要素を包んでください:

```mbt check
///|
test "render は Luna の DomElement ラッパーを取る" {
  fn boot() -> Unit {
    match @dom.document().getElementById("app") {
      Some(el) =>
        @element.render(
          el |> @element.DomElement::from_dom,
          @element.text("Hello, Luna"),
        )
      None => ()
    }
  }

  let _ = boot
}
```

### シグネチャ

```moonbit
fn render_to(@dom.Element, DomNode) -> Unit   // 空にしてからマウント
fn mount_to(@dom.Element, DomNode) -> Unit    // 追加
fn render(DomElement, DomNode) -> Unit
fn mount(DomElement, DomNode) -> Unit
fn clear_jsdom(@dom.Element) -> Unit
fn clear(DomElement) -> Unit
```

サンクを受け取る形はありませんし、必要もありません。第 2 引数の型が `DomNode` なので、
ノードを**返す関数**を渡すのは実行時エラーではなくコンパイルエラーになります。JavaScript
API が両方の形を受け付けざるを得ないのは `LunaNode` が `unknown`
だからです。[JavaScript API との違い](#javascript-api-との違い)を参照してください。

## イベントハンドラ

`events()` は `HandlerMap` を開き、各ハンドラメソッドがそこに追加してマップ自身を返すので
チェーンできます。結果を DSL のどの要素にも `on` 引数として渡せます:

```mbt check
///|
test "events() は型付きハンドラを要素にチェーンする" {
  fn counter() -> @element.DomNode {
    let count = @resource.signal(0)
    @element.div()
    <| [
      @element.p() <| [@element.text_dyn(fn() { "Count: \{count.get()}" })],
      @element.button(
        on=@element.events().click(fn(_e) { count.update(fn(n) { n + 1 }) }),
      )
      <| [@element.text("Increment")],
      @element.button(on=@element.events().click(fn(_e) { count.set(0) }))
      <| [@element.text("Reset")],
    ]
  }

  let _ = counter
}
```

各ハンドラは名前に対応するイベント型を受け取ります。`click` / `dblclick` /
`mouseenter` は `MouseEvent`、`keydown` / `keyup` / `keypress` は `KeyboardEvent`、
`input` は `InputEvent`、`change` は `ChangeEvent`、`submit` は `FormEvent`、
`focus` / `blur` は `FocusEvent` です。

input イベントから値を読むには `mizchi/js/core` を経由します。`@dom.Element` 自体には
`value` アクセサがないので、target をキャストしてプロパティを読みます:

```mbt check
///|
test "複数のハンドラを 1 つの式でチェーンする" {
  fn search_box() -> @element.DomNode {
    let query = @resource.signal("")
    @element.input(
      type_="text",
      on=@element
        .events()
        .input(fn(e) {
          let target : @js.Any = e.target() |> @js.identity
          query.set(target._get("value").cast())
        })
        .focus(fn(_e) { println("focused") }),
    )
  }

  let _ = search_box
}
```

## ポータル

ポータルは children を Luna の差分計算下に置いたまま、ドキュメントの別の場所へ移します。
children は素の `Array[DomNode]` で、遅延させるためのコールバックはありません:

```mbt check
///|
test "ポータルはコールバックではなく素のノードを取る" {
  fn modal() -> @element.DomNode {
    @element.portal_to_body([
      @element.div(class="modal") <| [@element.text("Modal content")],
    ])
  }

  fn modal_in_selector() -> @element.DomNode {
    @element.portal_to("#modal-root", [
      @element.div(class="modal") <| [@element.text("Modal content")],
    ])
  }

  let _ = modal
  let _ = modal_in_selector
}
```

```moonbit
fn portal_to_body(Array[DomNode]) -> DomNode
fn portal_to(String, Array[DomNode]) -> DomNode
fn portal(target~ : @dom.Element, children~ : Array[DomNode]) -> DomNode
```

## Context

Context は `mizchi/signals` にあります。`provide` は**サンク**を取ります。値がスコープに
入っているのはその関数の実行中だけで、これがネストと復帰を成り立たせています。以下の 2 つは
DOM に触れないので実際に実行されます:

```mbt check
///|
test "provide は context の値をサンクのスコープに閉じ込める" {
  let theme = @signals.create_context("light")
  assert_eq(@signals.use_context(theme), "light")
  let inner = @signals.provide(theme, "dark", fn() {
    @signals.use_context(theme)
  })
  assert_eq(inner, "dark")
  // 抜けると外側の値に戻る
  assert_eq(@signals.use_context(theme), "light")
}

///|
test "provide はネストする" {
  let theme = @signals.create_context("light")
  let seen = @signals.provide(theme, "outer", fn() {
    let a = @signals.use_context(theme)
    let b = @signals.provide(theme, "inner", fn() {
      @signals.use_context(theme)
    })
    let c = @signals.use_context(theme)
    (a, b, c)
  })
  assert_eq(seen, ("outer", "inner", "outer"))
}
```

ここでもサンクは慣習ではなく型です。`provide` の型は
`fn[T, R] (Context[T], T, () -> R) -> R` なので、計算済みの値を渡すとコンパイルが通りません。

## JavaScript API との違い

`@luna_ui/luna` は同じレンダラを包んでいますが、その `LunaNode` は `unknown` なので、
MoonBit がコンパイル時に弾く誤りが向こうでは実行時にしか現れません。そのため JavaScript
側はより多くの形を受け付けます:

| | MoonBit | JavaScript |
|---|---|---|
| マウント | `render_to(el, node)` — 構築済みノードのみ | `render(el, node)` **または** `render(el, () => node)` |
| ポータルの children | `Array[DomNode]` | ノード **または** サンク |
| context の children | `provide(ctx, v, fn)` — サンクは型で強制 | `Provider` は children が関数でなければ例外 |
| イベント | `events().click(fn)` | JSX の `onClick={fn}` — `events()` は JS に export されない |

唯一そのまま移植できないのが `events()` です。`HandlerMap::click` などは MoonBit の
`extern "js"` メソッドで、ここでは動きますが、コンパイル後の関数が返すオブジェクトには
決して結び付きません。そのため JavaScript から `events()` を呼ぶと素の `{}` が返って
いました。これは MoonBit 専用の DSL であり、JavaScript パッケージはもう export していません。

引数の順序は両者で同じ(コンテナが先)で、これは SolidJS の `render(code, element)`
とは逆です。

## API 一覧

| 関数 | 説明 |
|------|------|
| `render_to(el, node)` | 要素を空にしてノードをマウント |
| `mount_to(el, node)` | 要素にノードを追加 |
| `render(dom_el, node)` | `render_to` と同じ。`DomElement` を取る |
| `mount(dom_el, node)` | `mount_to` と同じ。`DomElement` を取る |
| `DomElement::from_dom(el)` | `@dom.Element` を包む |
| `events()` | ハンドラをチェーンする `HandlerMap` を開く |
| `portal_to_body(children)` | children を `<body>` に描画 |
| `portal_to(selector, children)` | children を最初に一致した要素に描画 |
| `portal(target~, children~)` | children を指定要素に描画 |
| `@signals.create_context(default)` | context を作る |
| `@signals.provide(ctx, value, fn)` | `value` をスコープに入れて `fn` を実行 |
| `@signals.use_context(ctx)` | 最も内側で提供された値を読む |
