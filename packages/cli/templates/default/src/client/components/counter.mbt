///| Counter - Client-side interactive component

///| Hydrate counter component
pub fn hydrate(element : @dom.Element, state_json : String) -> Unit {
  // Parse initial count from state
  let count = @signal.signal(0)

  // Create UI
  let ui = @dom.div(
    attrs=[("class", @dom.attr_string("counter"))],
    [
      @dom.span([@dom.text("Count: ")]),
      @dom.span([@dom.text_dyn(fn() { count.get().to_string() })]),
      @dom.button(
        attrs=[("onclick", @dom.on_click(fn(_e) { count.set(count.get() - 1) }))],
        [@dom.text("-")],
      ),
      @dom.button(
        attrs=[("onclick", @dom.on_click(fn(_e) { count.set(count.get() + 1) }))],
        [@dom.text("+")],
      ),
    ],
  )

  @dom.mount_to(element, ui)
}
