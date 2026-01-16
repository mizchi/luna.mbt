//

///|
/// Render tests - cross-platform (js, wasm-gc, native)
test "escape_html basic" {
  assert_eq(escape_html("hello"), "hello")
  assert_eq(escape_html("<script>"), "&lt;script&gt;")
  assert_eq(escape_html("a & b"), "a &amp; b")
  assert_eq(escape_html("\"quoted\""), "&quot;quoted&quot;")
}

///|
test "escape_attr basic" {
  assert_eq(escape_attr("hello"), "hello")
  assert_eq(escape_attr("a\"b"), "a&quot;b")
  assert_eq(escape_attr("a&b"), "a&amp;b")
}

///|
test "escape_js_string basic" {
  assert_eq(escape_js_string("hello"), "hello")
  assert_eq(escape_js_string("line\nbreak"), "line\\nbreak")
  assert_eq(escape_js_string("tab\there"), "tab\\there")
}

///|
test "is_void_element" {
  assert_true(is_void_element("br"))
  assert_true(is_void_element("img"))
  assert_true(is_void_element("input"))
  assert_true(is_void_element("meta"))
  assert_true(is_void_element("link"))
  assert_false(is_void_element("div"))
  assert_false(is_void_element("span"))
  assert_false(is_void_element("p"))
}

///|
test "needs_html_escape" {
  assert_false(needs_html_escape("hello"))
  assert_true(needs_html_escape("<script>"))
  assert_true(needs_html_escape("a & b"))
  assert_true(needs_html_escape("\"quoted\""))
}

///|
test "needs_attr_escape" {
  assert_false(needs_attr_escape("hello"))
  assert_true(needs_attr_escape("a\"b"))
  assert_true(needs_attr_escape("a&b"))
  // Note: < is not escaped in attributes, only in HTML content
  assert_false(needs_attr_escape("a<b"))
}

///|
test "escape_html_to" {
  let sb = StringBuilder::new()
  escape_html_to(sb, "<div>")
  assert_eq(sb.to_string(), "&lt;div&gt;")
}

///|
test "escape_attr_to" {
  let sb = StringBuilder::new()
  escape_attr_to(sb, "class=\"foo\"")
  assert_eq(sb.to_string(), "class=&quot;foo&quot;")
}

///|
test "render_to_string text node" {
  let node : @luna.Node[Unit] = @luna.text("Hello")
  let result = render_to_string(node)
  assert_eq(result.html, "Hello")
}

///|
test "render_to_string element" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [@luna.text("content")])
  let result = render_to_string(node)
  assert_eq(result.html, "<div>content</div>")
}

///|
test "render_to_string void element" {
  let node : @luna.Node[Unit] = @luna.h("br", [], [])
  let result = render_to_string(node)
  assert_eq(result.html, "<br />")
}

///|
test "render_to_string with static attr" {
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [("class", @luna.attr_static("container"))],
    [],
  )
  let result = render_to_string(node)
  assert_eq(result.html, "<div class=\"container\"></div>")
}

///|
test "render_to_string escapes content" {
  let node : @luna.Node[Unit] = @luna.text("<script>alert('xss')</script>")
  let result = render_to_string(node)
  assert_eq(result.html, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
}

///|
test "render_to_string fragment" {
  let node : @luna.Node[Unit] = @luna.fragment([
    @luna.text("a"),
    @luna.text("b"),
    @luna.text("c"),
  ])
  let result = render_to_string(node)
  assert_eq(result.html, "abc")
}

///|
test "generate_preload_tags empty" {
  let tags = generate_preload_tags([])
  assert_eq(tags, "")
}

///|
test "generate_preload_tags with urls" {
  let tags = generate_preload_tags(["/a.js", "/b.js"])
  assert_true(tags.contains("modulepreload"))
  assert_true(tags.contains("/a.js"))
  assert_true(tags.contains("/b.js"))
}
