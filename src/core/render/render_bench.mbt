// Benchmarks for render_to_string
// Run with: moon bench --target js -p mizchi/luna/core/render
// moon bench --target wasm-gc -p mizchi/luna/core/render
//
// Compare JS FFI escape vs pure MoonBit escape impact on full rendering

// =============================================================================
// Test Data - VNode Trees
// =============================================================================

///|
/// Simple text node
fn vnode_text() -> @core.Node[Unit, String] {
  @core.text("Hello, World!")
}

///|
/// Text with HTML special characters (needs escaping)
fn vnode_text_escape() -> @core.Node[Unit, String] {
  @core.text("<script>alert('xss')</script> & \"dangerous\" content")
}

///|
/// Simple element with no attrs
fn vnode_simple_element() -> @core.Node[Unit, String] {
  @core.h("div", [], [@core.text("content")])
}

///|
/// Element with multiple attributes (needs attr escaping)
fn vnode_with_attrs() -> @core.Node[Unit, String] {
  @core.h(
    "div",
    [
      ("id", @core.attr_static("main")),
      ("class", @core.attr_static("container mx-auto")),
      ("data-value", @core.attr_static("{\"count\":42,\"name\":\"test\"}")),
    ],
    [@core.text("content")],
  )
}

///|
/// Nested elements (typical component structure)
fn vnode_nested() -> @core.Node[Unit, String] {
  @core.h("div", [("class", @core.attr_static("card"))], [
    @core.h("header", [("class", @core.attr_static("card-header"))], [
      @core.h("h2", [], [@core.text("Title")]),
    ]),
    @core.h("div", [("class", @core.attr_static("card-body"))], [
      @core.h("p", [], [@core.text("This is the card body content.")]),
      @core.h("button", [("class", @core.attr_static("btn"))], [
        @core.text("Click me"),
      ]),
    ]),
  ])
}

///|
/// List of items (common pattern)
fn vnode_list() -> @core.Node[Unit, String] {
  let items : Array[@core.Node[Unit, String]] = []
  for i in 0..<10 {
    items.push(
      @core.h("li", [("class", @core.attr_static("item"))], [
        @core.text("Item \{i}"),
      ]),
    )
  }
  @core.h("ul", [("class", @core.attr_static("list"))], items)
}

///|
/// Large list (stress test)
fn vnode_large_list() -> @core.Node[Unit, String] {
  let items : Array[@core.Node[Unit, String]] = []
  for i in 0..<100 {
    items.push(
      @core.h("li", [("class", @core.attr_static("item"))], [
        @core.text("Item \{i} with some <special> & \"characters\""),
      ]),
    )
  }
  @core.h("ul", [("class", @core.attr_static("list"))], items)
}

///|
/// Typical page structure
fn vnode_page() -> @core.Node[Unit, String] {
  @core.h("html", [], [
    @core.h("head", [], [
      @core.h("meta", [("charset", @core.attr_static("utf-8"))], []),
      @core.h("title", [], [@core.text("Test Page")]),
    ]),
    @core.h("body", [], [
      @core.h("header", [], [
        @core.h("nav", [("class", @core.attr_static("navbar"))], [
          @core.h("a", [("href", @core.attr_static("/"))], [@core.text("Home")]),
          @core.h("a", [("href", @core.attr_static("/about"))], [
            @core.text("About"),
          ]),
        ]),
      ]),
      @core.h("main", [("class", @core.attr_static("container"))], [
        @core.h("h1", [], [@core.text("Welcome")]),
        @core.h("p", [], [
          @core.text("This is a test page with <special> & \"characters\"."),
        ]),
      ]),
      @core.h("footer", [], [@core.text("© 2024")]),
    ]),
  ])
}

// =============================================================================
// Render Benchmarks
// =============================================================================

///|
test "render: text" (b : @bench.T) {
  let node = vnode_text()
  b.bench(fn() { b.keep(render_to_string(node).html) })
}

///|
test "render: text_escape" (b : @bench.T) {
  let node = vnode_text_escape()
  b.bench(fn() { b.keep(render_to_string(node).html) })
}

///|
test "render: simple_element" (b : @bench.T) {
  let node = vnode_simple_element()
  b.bench(fn() { b.keep(render_to_string(node).html) })
}

///|
test "render: with_attrs" (b : @bench.T) {
  let node = vnode_with_attrs()
  b.bench(fn() { b.keep(render_to_string(node).html) })
}

///|
test "render: nested" (b : @bench.T) {
  let node = vnode_nested()
  b.bench(fn() { b.keep(render_to_string(node).html) })
}

///|
test "render: list (10 items)" (b : @bench.T) {
  let node = vnode_list()
  b.bench(fn() { b.keep(render_to_string(node).html) })
}

///|
test "render: large_list (100 items with escape)" (b : @bench.T) {
  let node = vnode_large_list()
  b.bench(fn() { b.keep(render_to_string(node).html) })
}

///|
test "render: page" (b : @bench.T) {
  let node = vnode_page()
  b.bench(fn() { b.keep(render_to_string(node).html) })
}

// =============================================================================
// Visitor Pattern Comparison (Experimental)
// =============================================================================
// Compare direct pattern matching vs visitor pattern for VNode traversal
// This helps decide whether to refactor for deduplication

///|
/// Visitor interface for VNode traversal
priv trait NodeVisitor {
  on_text(Self, String) -> Unit
  on_element_open(Self, String, Array[(String, @core.Attr[Unit, String])]) -> Unit
  on_element_close(Self, String, Bool) -> Unit // (tag, is_void)
  on_fragment_start(Self) -> Unit
  on_fragment_end(Self) -> Unit
}

///|
/// Visitor-based traversal (experimental)
fn visitor_traverse(
  node : @core.Node[Unit, String],
  visitor : &NodeVisitor,
) -> Unit {
  match node {
    Text(content) => visitor.on_text(content)
    DynamicText(getter) => visitor.on_text(getter())
    Fragment(children) => {
      visitor.on_fragment_start()
      for child in children {
        visitor_traverse(child, visitor)
      }
      visitor.on_fragment_end()
    }
    Element(elem) => {
      let tag = elem.tag
      let is_void = is_void_element(tag)
      visitor.on_element_open(tag, elem.attrs)
      if not(is_void) {
        for child in elem.children {
          visitor_traverse(child, visitor)
        }
      }
      visitor.on_element_close(tag, is_void)
    }
    // Skip other node types for this benchmark
    _ => ()
  }
}

///|
/// Simple StringBuilder visitor for comparison
priv struct SBVisitor {
  sb : StringBuilder
}

///|
fn SBVisitor::new() -> SBVisitor {
  { sb: StringBuilder::new(size_hint=256) }
}

///|
impl NodeVisitor for SBVisitor with on_text(self, content) {
  escape_html_to(self.sb, content)
}

///|
impl NodeVisitor for SBVisitor with on_element_open(self, tag, attrs) {
  self.sb.write_char('<')
  self.sb.write_string(tag)
  render_attrs_to(self.sb, attrs)
  if is_void_element(tag) {
    self.sb.write_string(" />")
  } else {
    self.sb.write_char('>')
  }
}

///|
impl NodeVisitor for SBVisitor with on_element_close(self, tag, is_void) {
  if not(is_void) {
    self.sb.write_string("</")
    self.sb.write_string(tag)
    self.sb.write_char('>')
  }
}

///|
impl NodeVisitor for SBVisitor with on_fragment_start(_self) {
  // No output for fragment
}

///|
impl NodeVisitor for SBVisitor with on_fragment_end(_self) {
  // No output for fragment
}

///|
/// Render using visitor pattern (for benchmark comparison)
fn render_with_visitor(node : @core.Node[Unit, String]) -> String {
  let visitor = SBVisitor::new()
  visitor_traverse(node, visitor)
  visitor.sb.to_string()
}

// =============================================================================
// Visitor vs Direct Comparison Benchmarks
// =============================================================================

///|
test "compare: nested - direct vs visitor" (b : @bench.T) {
  let node = vnode_nested()
  b.bench(name="direct", fn() { b.keep(render_to_string(node).html) })
  b.bench(name="visitor", fn() { b.keep(render_with_visitor(node)) })
}

///|
test "compare: list - direct vs visitor" (b : @bench.T) {
  let node = vnode_list()
  b.bench(name="direct", fn() { b.keep(render_to_string(node).html) })
  b.bench(name="visitor", fn() { b.keep(render_with_visitor(node)) })
}

///|
test "compare: large_list - direct vs visitor" (b : @bench.T) {
  let node = vnode_large_list()
  b.bench(name="direct", fn() { b.keep(render_to_string(node).html) })
  b.bench(name="visitor", fn() { b.keep(render_with_visitor(node)) })
}

///|
test "compare: page - direct vs visitor" (b : @bench.T) {
  let node = vnode_page()
  b.bench(name="direct", fn() { b.keep(render_to_string(node).html) })
  b.bench(name="visitor", fn() { b.keep(render_with_visitor(node)) })
}
