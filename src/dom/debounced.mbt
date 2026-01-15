// Debounced Signal - Timer-based signal debouncing (requires JS runtime)
//

///|
/// Debounce signal updates using setTimeout
pub fn[T] debounced(
  sig : @signal.Signal[T],
  delay_ms : Int,
) -> @signal.Signal[T] {
  let result = @signal.Signal::new(sig.peek())
  let timer_id : Ref[@global.Timer?] = Ref::new(None)
  let first_run = Ref::new(true)
  let _ = @signal.render_effect(fn() {
    let value = sig.get()
    if first_run.val {
      first_run.val = false
    } else {
      // Cancel previous timer
      match timer_id.val {
        Some(id) => @global.clearTimeout(id)
        None => ()
      }
      // Set new timer
      timer_id.val = Some(
        @global.setTimeout(fn() { result.set(value) }, delay_ms),
      )
    }
  })
  result
}
