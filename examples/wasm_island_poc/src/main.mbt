// WASM Island PoC - MoonBit wasm-gc で DOM 操作

// State
let count : Ref[Int] = Ref::new(0)

///|
fn main {
  render()
}

///|
/// Render the counter UI into the target element
pub fn render() -> Unit {
  let global = @core.global_this()
  let document = global["document"]
  let el = document._call("getElementById", [@core.any("wasm-island")])
  if @core.is_nullish(el) {
    return
  }
  let html = "<div><h2>WASM Island Counter</h2><p>Count: " +
    count.val.to_string() +
    "</p><button id=\"wasm-btn\">+1</button></div>"
  el._set("innerHTML", @core.any(html))
}

///|
/// Handle button click - increment and re-render
pub fn handle_click() -> Unit {
  count.val = count.val + 1
  render()
}
