// Benchmarks for portable stream rendering

///|
fn vnode_stream_list() -> @luna.Node[Unit, String] {
  let items : Array[@luna.Node[Unit, String]] = []
  for i in 0..<10 {
    items.push(
      @luna.h("li", [("class", @luna.attr_static("item"))], [
        @luna.text("Item \{i}"),
      ]),
    )
  }
  @luna.h("ul", [("class", @luna.attr_static("list"))], items)
}

///|
fn vnode_stream_large_list() -> @luna.Node[Unit, String] {
  let items : Array[@luna.Node[Unit, String]] = []
  for i in 0..<100 {
    items.push(
      @luna.h("li", [("class", @luna.attr_static("item"))], [
        @luna.text("Item \{i} with some <special> & \"characters\""),
      ]),
    )
  }
  @luna.h("ul", [("class", @luna.attr_static("list"))], items)
}

///|
fn vnode_stream_page() -> @luna.Node[Unit, String] {
  @luna.h("html", [], [
    @luna.h("head", [], [
      @luna.h("meta", [("charset", @luna.attr_static("utf-8"))], []),
      @luna.h("title", [], [@luna.text("Test Page")]),
    ]),
    @luna.h("body", [], [
      @luna.h("header", [], [
        @luna.h("nav", [("class", @luna.attr_static("navbar"))], [
          @luna.h("a", [("href", @luna.attr_static("/"))], [@luna.text("Home")]),
          @luna.h("a", [("href", @luna.attr_static("/about"))], [
            @luna.text("About"),
          ]),
        ]),
      ]),
      @luna.h("main", [("class", @luna.attr_static("container"))], [
        @luna.h("h1", [], [@luna.text("Welcome")]),
        @luna.h("p", [], [
          @luna.text("This is a test page with <special> & \"characters\"."),
        ]),
      ]),
      @luna.h("footer", [], [@luna.text("© 2024")]),
    ]),
  ])
}

///|
fn stream_to_string(node : @luna.Node[Unit, String]) -> String {
  let sb = StringBuilder::new(size_hint=1024)
  let writer = StreamWriter::from_callback(fn(chunk) { sb.write_string(chunk) })
  render_to_stream(node, writer)
  sb.to_string()
}

///|
test "stream render: list (10 items)" (b : @bench.T) {
  let node = vnode_stream_list()
  b.bench(fn() { b.keep(stream_to_string(node)) })
}

///|
test "stream render: large_list (100 items with escape)" (b : @bench.T) {
  let node = vnode_stream_large_list()
  b.bench(fn() { b.keep(stream_to_string(node)) })
}

///|
test "stream render: page" (b : @bench.T) {
  let node = vnode_stream_page()
  b.bench(fn() { b.keep(stream_to_string(node)) })
}
