## luna

MoonBit (月餅)に対して、その開発者の一人の　yoorkin 氏が作ってた UI ライブラリで rabbit-tea だったので、月っぽい名前を選びました。

- react
  - ランタイムサイズがデカすぎる
- qwik
  - pros: 最適化
  - const: コンパイラの挙動が難しすぎる
- preact
  - pros
  - const
- svelte 
  - pros: 軽量
  - const: 独自拡張子で tsx ではないのが微妙

というわけで、qwik の resume とアイランドアーキテクチャを備えた、 preact のような専用のコア


qwik は難しすぎる

preact の signal

Moonbit が流行るにはキラーアプリが必要。

UIライブラリ



```mbt
///|
fn counter_example() -> @dom.DomNode {
  let count = @signal.signal(0)
  let doubled = @signal.memo(fn() { count.get() * 2 })
  let is_even = @signal.memo(fn() { count.get() % 2 == 0 })
  @dom.div(class="counter-example", [
    @dom.h2([@dom.text("Counter Example")]),
    @dom.p([@dom.text_dyn(fn() { "Count: " + count.get().to_string() })]),
    @dom.p([@dom.text_dyn(fn() { "Doubled: " + doubled().to_string() })]),
    @dom.p([@dom.text_dyn(fn() { if is_even() { "Even" } else { "Odd" } })]),
    @dom.div(class="buttons", [
      @dom.button(
        on=@dom.on(click=Some(fn(_) { count.update(fn(n) { n - 1 }) })),
        [@dom.text("-")],
      ),
      @dom.button(
        on=@dom.on(click=Some(fn(_) { count.update(fn(n) { n + 1 }) })),
        [@dom.text("+")],
      ),
      @dom.button(on=@dom.on(click=Some(fn(_) { count.set(0) })), [
        @dom.text("Reset"),
      ]),
    ]),
  ])
}
```