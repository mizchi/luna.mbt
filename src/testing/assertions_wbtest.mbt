// Luna Testing - Assertion Tests

///|
test "assert_tag succeeds for correct tag" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [])
  assert_tag(node, "div")
}

///|
test "assert_is_element succeeds for Element" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [])
  assert_is_element(node)
}

///|
test "assert_static_attr succeeds for correct value" {
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [("class", @luna.attr_static("container"))],
    [],
  )
  assert_static_attr(node, "class", "container")
}

///|
test "assert_attr succeeds for static attr" {
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [("class", @luna.attr_static("container"))],
    [],
  )
  assert_attr(node, "class", "container")
}

///|
test "assert_attr succeeds for dynamic attr" {
  let sig = @signal.signal("value")
  let node : @luna.Node[Unit] = @luna.h(
    "input",
    [("value", @luna.attr_dynamic(fn() { sig.get() }))],
    [],
  )
  assert_attr(node, "value", "value")
}

///|
test "assert_has_handler succeeds when handler exists" {
  let node : @luna.Node[Unit] = @luna.h(
    "button",
    [("onclick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [],
  )
  assert_has_handler(node, "onclick")
}

///|
test "assert_text succeeds for correct text" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [@luna.text("Hello World")])
  assert_text(node, "Hello World")
}

///|
test "assert_text_contains succeeds when text contains substring" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [@luna.text("Hello World")])
  assert_text_contains(node, "Hello")
  assert_text_contains(node, "World")
}

///|
test "assert_child_count succeeds for correct count" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.text("a"),
    @luna.text("b"),
    @luna.text("c"),
  ])
  assert_child_count(node, 3)
}

///|
test "assert_has_element succeeds when element exists" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.h("button", [], [@luna.text("Click")]),
  ])
  assert_has_element(node, "button")
}

///|
test "assert_no_element succeeds when element does not exist" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [@luna.text("Hello")])
  assert_no_element(node, "button")
}

///|
test "assert_element_count succeeds for correct count" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.h("span", [], []),
    @luna.h("span", [], []),
    @luna.h("span", [], []),
  ])
  assert_element_count(node, "span", 3)
}

///|
test "assert_show_visible succeeds when condition is true" {
  let node : @luna.Node[Unit] = @luna.show(fn() { true }, fn() {
    @luna.text("visible")
  })
  assert_show_visible(node)
}

///|
test "assert_show_hidden succeeds when condition is false" {
  let node : @luna.Node[Unit] = @luna.show(fn() { false }, fn() {
    @luna.text("hidden")
  })
  assert_show_hidden(node)
}

///|
test "assert_for_count succeeds for correct count" {
  let items = @signal.signal(["a", "b", "c"])
  let node : @luna.Node[Unit] = @luna.for_each(fn() {
    items.get().map(fn(item) { @luna.text(item) })
  })
  assert_for_count(node, 3)
}
