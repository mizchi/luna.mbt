///|
test "render_to_stream simple element" {
  let node : @luna.Node[Unit, String] = @luna.h("div", [], [
    @luna.text("Simple"),
  ])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  render_to_stream(node, writer)
  let html = chunks.iter().join("")
  assert_eq(html, "<div>Simple</div>")
}

///|
test "render_to_stream_collecting_async collects boundaries" {
  let node : @luna.Node[Unit, String] = @luna.fragment([
    @luna.h("div", [], [@luna.text("Header")]),
    @luna.async_(
      render=fn() { @luna.h("div", [], [@luna.text("Async 1")]) },
      fallback=fn() { @luna.h("div", [], [@luna.text("Loading 1...")]) },
    ),
    @luna.async_(
      render=fn() { @luna.h("div", [], [@luna.text("Async 2")]) },
      fallback=fn() { @luna.h("div", [], [@luna.text("Loading 2...")]) },
    ),
    @luna.h("div", [], [@luna.text("Footer")]),
  ])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  let boundaries = render_to_stream_collecting_async(node, writer)
  assert_eq(boundaries.length(), 2)
  let html = chunks.iter().join("")
  assert_true(html.contains("Loading 1..."))
  assert_true(html.contains("Loading 2..."))
  assert_true(html.contains("Header"))
  assert_true(html.contains("Footer"))
  assert_true(html.contains("id=\"A:0\""))
  assert_true(html.contains("id=\"A:1\""))
}

///|
test "render_to_stream no async returns empty boundaries" {
  let node : @luna.Node[Unit, String] = @luna.h("div", [], [
    @luna.text("Simple"),
  ])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  let boundaries = render_to_stream_collecting_async(node, writer)
  assert_eq(boundaries.length(), 0)
  let html = chunks.iter().join("")
  assert_eq(html, "<div>Simple</div>")
}

///|
test "stream_async_replacement" {
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  stream_async_replacement(42, writer, fn(w) { (w.0)("Replaced Content") })
  let html = chunks.iter().join("")
  assert_true(html.contains("<template id=\"T:42\">"))
  assert_true(html.contains("Replaced Content"))
  assert_true(html.contains("</template>"))
  assert_true(html.contains("<script>"))
}

///|
test "stream render error_boundary children when no error" {
  let node : @luna.Node[Unit, String] = @luna.error_boundary(
    children=fn() { @luna.h("div", [], [@luna.text("Stream Success")]) },
    fallback=fn(_err, _reset) { @luna.text("Error") },
  )
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  render_to_stream(node, writer)
  let html = chunks.iter().join("")
  assert_eq(html, "<div>Stream Success</div>")
}

///|
test "stream render switch first case" {
  let node : @luna.Node[Unit, String] = @luna.switch_(
    cases=[
      @luna.match_case(
        when=fn() { true },
        render=fn() { @luna.text("Stream First") },
      ),
    ],
    fallback=Some(fn() { @luna.text("Fallback") }),
  )
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  render_to_stream(node, writer)
  let html = chunks.iter().join("")
  assert_eq(html, "Stream First")
}

///|
test "stream render switch no fallback" {
  let node : @luna.Node[Unit, String] = @luna.switch_(cases=[
    @luna.match_case(
      when=fn() { false },
      render=fn() { @luna.text("Never") },
    ),
  ])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  render_to_stream(node, writer)
  let html = chunks.iter().join("")
  assert_eq(html, "<!--switch-->")
}
