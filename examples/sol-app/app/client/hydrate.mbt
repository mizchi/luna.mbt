///| Client Hydration Entry

///| Hydration entry point (called by loader)
pub fn hydrate_counter(element : @core.Any, state : @core.Any, id : String) -> Unit {
  @dom.hydrate_island(element, state, id, fn(ctx) {
    let count = ctx.signal_int("count", 0)
    ctx.bind_actions(fn(action) {
      match action {
        "increment" => count.set(count.get() + 1)
        "decrement" => count.set(count.get() - 1)
        _ => ()
      }
    })
    ctx.on_update(".count-display", fn() { count.get().to_string() })
  })
}
