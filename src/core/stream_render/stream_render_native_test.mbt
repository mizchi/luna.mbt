// Tests verifying actual streaming behavior (chunk-by-chunk output)

///|
test "streaming produces multiple chunks, not a single string" {
  let node : @luna.Node[Unit, String] = @luna.fragment([
    @luna.h("div", [], [@luna.text("A")]),
    @luna.h("div", [], [@luna.text("B")]),
    @luna.h("div", [], [@luna.text("C")]),
  ])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  render_to_stream(node, writer)
  // Must produce multiple chunks (not a single concatenated string)
  assert_true(chunks.length() > 1)
  // Reconstructed HTML is correct
  let html = chunks.iter().join("")
  assert_eq(html, "<div>A</div><div>B</div><div>C</div>")
}

///|
test "streaming flushes header before async fallback" {
  let node : @luna.Node[Unit, String] = @luna.fragment([
    @luna.h("h1", [], [@luna.text("Header")]),
    @luna.async_(render=fn() { @luna.h("p", [], [@luna.text("Loaded")]) }, fallback=fn() {
      @luna.h("p", [], [@luna.text("Loading...")])
    }),
    @luna.h("footer", [], [@luna.text("Footer")]),
  ])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  let boundaries = render_to_stream_collecting_async(node, writer)
  // Find indices
  let mut header_idx = -1
  let mut fallback_idx = -1
  for i, c in chunks {
    if c.contains("Header") {
      header_idx = i
    }
    if c.contains("Loading") {
      fallback_idx = i
    }
  }
  // Header chunk appears before fallback
  assert_true(header_idx >= 0)
  assert_true(fallback_idx >= 0)
  assert_true(header_idx < fallback_idx)
  // Async boundary collected
  assert_eq(boundaries.length(), 1)
}

///|
async test "render_to_stream_with_async resolves and streams replacement" {
  let node : @luna.Node[Unit, String] = @luna.fragment([
    @luna.h("div", [], [@luna.text("Static")]),
    @luna.async_(
      render=fn() { @luna.h("span", [], [@luna.text("Resolved!")]) },
      fallback=fn() { @luna.text("Loading...") },
    ),
  ])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  render_to_stream_with_async(node, writer)
  let html = chunks.iter().join("")
  // Contains both fallback placeholder and resolved replacement
  assert_true(html.contains("Loading..."))
  assert_true(html.contains("Resolved!"))
  assert_true(html.contains("<template id=\"T:0\">"))
  assert_true(html.contains("<script>"))
}
