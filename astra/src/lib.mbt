// Astra: Mars middleware for static site generation.

///|
/// Placeholder middleware. Returns a 501 for every request until Phase B wires
/// the real document tree and render core.
pub fn placeholder() -> @mars.Handler {
  @mars.handler(fn(ctx) {
    ctx.text("astra: not implemented yet", status=501)
  })
}
