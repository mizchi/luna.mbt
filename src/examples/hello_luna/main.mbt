///|
/// Minimal Luna Counter - for bundle size measurement
///
/// This is the simplest possible Luna app:
/// - One Signal (count)
/// - One button with click handler
/// - Text that updates reactively
fn main {
  let doc = @dom.document()
  match doc.getElementById("app") {
    Some(el) => {
      let count = @signal.signal(0)
      let app = @luna_dom.div([
        @luna_dom.p([
          @luna_dom.text_dyn(fn() { "Count: " + count.get().to_string() }),
        ]),
        @luna_dom.button(
          on=@luna_dom.events().click(fn(_) { count.update(fn(n) { n + 1 }) }),
          [@luna_dom.text("Click me")],
        ),
      ])
      @luna_dom.render(el |> @luna_dom.DomElement::from_dom, app)
    }
    None => ()
  }
}
