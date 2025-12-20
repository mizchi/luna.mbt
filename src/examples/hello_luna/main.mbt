///|
/// Minimal Luna Counter - for bundle size measurement
///
/// This is the simplest possible Luna app:
/// - One Signal (count)
/// - One button with click handler
/// - Text that updates reactively
fn main {
  let doc = @js_dom.document()
  match doc.getElementById("app") {
    Some(el) => {
      let count = @signal.signal(0)
      let app = @dom.div([
        @dom.p([@dom.text_dyn(fn() { "Count: " + count.get().to_string() })]),
        @dom.button(
          on=@dom.events().click(fn(_) { count.update(fn(n) { n + 1 }) }),
          [@dom.text("Click me")],
        ),
      ])
      @dom.render(el |> @dom.DomElement::from_jsdom, app)
    }
    None => ()
  }
}
