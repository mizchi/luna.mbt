///| Debounced Signal - Timer-based signal debouncing (requires JS runtime)

///|
/// Debounce signal updates using setTimeout
pub fn[T] debounced(
  sig : @ui.Signal[T],
  delay_ms : Int,
) -> @ui.Signal[T] {
  let result = @ui.Signal::new(sig.peek())
  let timer_id : Ref[@global.Timer?] = { val: None }
  let _ = @ui.on(sig, fn(value) {
    // Cancel previous timer
    match timer_id.val {
      Some(id) => @global.clearTimeout(id)
      None => ()
    }
    // Set new timer
    timer_id.val = Some(
      @global.setTimeout(fn() { result.set(value) }, delay_ms),
    )
  })
  result
}
