///|
test "style attributes render in SSR and CSS is delivered inside shadow root" {
  let style = @css.create([
    @css.rule("color", "red"),
    @css.rule("width", "var(--width)"),
  ]).with_vars([("--width", "12px")])
  let resolved = @css.attrs([style])
  let child : @core.Node[Unit, String] = @core.h(
    "button",
    [
      ("class", @core.attr_static(resolved.class_name)),
      ("style", @core.attr_static(resolved.style)),
    ],
    [@core.text("Hello")],
  )
  let node = @core.wc_island(
    "styled-button",
    "/button.js",
    @css.stylesheet([style]),
    "{}",
    [child],
  )
  let html = @render.render_to_string(node).html
  assert_true(html.contains("<template shadowrootmode=\"open\"><style"))
  assert_true(html.contains("color:red"))
  assert_true(html.contains("style=\"--width:12px\""))
  assert_true(html.contains("class=\"" + resolved.class_name + "\""))
  let chunks : Array[String] = []
  @stream.render_to_stream(
    node,
    @stream.StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) }),
  )
  let streamed = chunks.join("")
  assert_true(streamed.contains("<template shadowrootmode=\"open\"><style>"))
  assert_true(streamed.contains("style=\"--width:12px\""))
}
