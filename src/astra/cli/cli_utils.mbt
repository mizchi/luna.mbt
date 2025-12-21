// CLI utilities

///|
fn console_error(msg : String) -> Unit {
  @console.error(@js.any(msg))
}
