// Round-trip tests for Luna Node -> AbstractNode conversion

///|
test "convert simple element" {
  let luna_node : @luna.Node[Unit] = @luna.h(
    "div",
    [("class", @luna.attr_static("container"))],
    [@luna.text("Hello")],
  )
  let abstract_node = to_abstract(luna_node)

  // Verify structure
  match abstract_node {
    Element(tag~, attrs~, children~) => {
      assert_eq(tag, "div")
      assert_eq(attrs.length(), 1)
      assert_eq(children.length(), 1)
    }
    _ => fail("Expected Element")
  }
}

///|
test "convert nested elements" {
  let luna_node : @luna.Node[Unit] = @luna.h("ul", [], [
    @luna.h("li", [], [@luna.text("Item 1")]),
    @luna.h("li", [], [@luna.text("Item 2")]),
  ])
  let abstract_node = to_abstract(luna_node)

  // Count nodes
  assert_eq(abstract_node.count_nodes(), 5)
}

///|
test "convert dynamic text" {
  let luna_node : @luna.Node[Unit] = @luna.text_dyn(fn() { "Dynamic" })
  let abstract_node = to_abstract(luna_node)
  match abstract_node {
    Text(content) => assert_eq(content, "Dynamic")
    _ => fail("Expected Text")
  }
}

///|
test "convert fragment" {
  let luna_node : @luna.Node[Unit] = @luna.fragment([
    @luna.text("A"),
    @luna.text("B"),
    @luna.text("C"),
  ])
  let abstract_node = to_abstract(luna_node)
  match abstract_node {
    Fragment(children) => assert_eq(children.length(), 3)
    _ => fail("Expected Fragment")
  }
}

///|
test "convert Show node - true condition" {
  let luna_node : @luna.Node[Unit] = @luna.show(fn() { true }, fn() {
    @luna.text("Visible")
  })
  let abstract_node = to_abstract(luna_node)
  match abstract_node {
    Text(content) => assert_eq(content, "Visible")
    _ => fail("Expected Text")
  }
}

///|
test "convert Show node - false condition" {
  let luna_node : @luna.Node[Unit] = @luna.show(fn() { false }, fn() {
    @luna.text("Hidden")
  })
  let abstract_node = to_abstract(luna_node)
  match abstract_node {
    Fragment(children) => assert_eq(children.length(), 0)
    _ => fail("Expected empty Fragment")
  }
}

///|
test "convert For node" {
  let luna_node : @luna.Node[Unit] = @luna.for_each(fn() {
    [@luna.text("A"), @luna.text("B")]
  })
  let abstract_node = to_abstract(luna_node)
  match abstract_node {
    Fragment(children) => assert_eq(children.length(), 2)
    _ => fail("Expected Fragment")
  }
}

///|
test "convert RawHtml" {
  let luna_node : @luna.Node[Unit] = @luna.raw_html(
    "<custom-element>Content</custom-element>",
  )
  let abstract_node = to_abstract(luna_node)
  match abstract_node {
    RawHtml(html) =>
      assert_eq(html, "<custom-element>Content</custom-element>")
    _ => fail("Expected RawHtml")
  }
}

///|
test "round-trip simple element html output" {
  // Create Luna node
  let luna_node : @luna.Node[Unit] = @luna.h(
    "div",
    [("class", @luna.attr_static("container"))],
    [@luna.text("Hello")],
  )

  // Convert to AbstractNode
  let abstract_node = to_abstract(luna_node)

  // Render to HTML via AbstractNode
  let abstract_html = abstract_node.render_html()

  // Compare with Luna's direct rendering
  let luna_html = render_to_string(luna_node).html
  assert_eq(abstract_html, luna_html)
}

///|
test "round-trip nested elements html output" {
  let luna_node : @luna.Node[Unit] = @luna.h("ul", [], [
    @luna.h("li", [], [@luna.text("Item 1")]),
    @luna.h("li", [], [@luna.text("Item 2")]),
  ])
  let abstract_node = to_abstract(luna_node)
  let abstract_html = abstract_node.render_html()
  let luna_html = render_to_string(luna_node).html
  assert_eq(abstract_html, luna_html)
}

///|
test "round-trip void elements html output" {
  let luna_node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.h("br", [], []),
    @luna.h("img", [("src", @luna.attr_static("test.png"))], []),
  ])
  let abstract_node = to_abstract(luna_node)
  let abstract_html = abstract_node.render_html()
  let luna_html = render_to_string(luna_node).html
  assert_eq(abstract_html, luna_html)
}

///|
test "round-trip fragment html output" {
  let luna_node : @luna.Node[Unit] = @luna.fragment([
    @luna.text("Hello "),
    @luna.h("strong", [], [@luna.text("World")]),
  ])
  let abstract_node = to_abstract(luna_node)
  let abstract_html = abstract_node.render_html()
  let luna_html = render_to_string(luna_node).html
  assert_eq(abstract_html, luna_html)
}

///|
test "round-trip escaped content html output" {
  let luna_node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.text("<script>alert('XSS')</script>"),
  ])
  let abstract_node = to_abstract(luna_node)
  let abstract_html = abstract_node.render_html()
  let luna_html = render_to_string(luna_node).html
  assert_eq(abstract_html, luna_html)
}
