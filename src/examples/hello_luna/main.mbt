///|
/// Luna Hello World - Counter with Lifecycle Hooks
///
/// Demonstrates:
/// - Reactive signals
/// - Conditional rendering with show()
/// - Lifecycle hooks (on_mount, on_cleanup)

///|
using @element {
  div,
  p,
  button,
  text,
  text_dyn,
  show,
  render_to,
  events,
  type DomNode,
}

///|
using @resource {signal, on_mount, on_cleanup}

///|
fn counter() -> DomNode {
  let count = signal(0)
  div([
    p([text_dyn(fn() { "Count: " + count.get().to_string() })]),
    button(on=events().click(fn(_) { count.update(fn(n) { n + 1 }) }), [
      text("Increment"),
    ]),
    show(fn() { count.get() % 2 == 0 }, fn() { even_message() }),
  ])
}

///|
fn even_message() -> DomNode {
  on_mount(fn() { println("even_message mounted") })
  on_cleanup(fn() { println("even_message cleaned up") })
  p([text("Count is even!")])
}

///|
fn main {
  let doc = @dom.document()
  match doc.getElementById("app") {
    Some(el) => render_to(el, counter())
    None => println("Error: #app element not found")
  }
}
