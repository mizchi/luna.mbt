// Luna Testing - Query Tests

///|
test "get_element returns Element" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [])
  assert_true(get_element(node) is Some(_))
}

///|
test "get_element returns None for Text" {
  let node : @luna.Node[Unit] = @luna.text("hello")
  assert_true(get_element(node) is None)
}

///|
test "get_text returns text content" {
  let node : @luna.Node[Unit] = @luna.text("hello")
  assert_eq(get_text(node), Some("hello"))
}

///|
test "get_dynamic_text returns current value" {
  let node : @luna.Node[Unit] = @luna.text_dyn(fn() { "dynamic" })
  assert_eq(get_dynamic_text(node), Some("dynamic"))
}

///|
test "get_tag returns tag name" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [])
  assert_eq(get_tag(node), Some("div"))
}

///|
test "child_count returns children count" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.text("a"),
    @luna.text("b"),
    @luna.text("c"),
  ])
  assert_eq(child_count(node), 3)
}

///|
test "get_children returns children array" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.text("a"),
    @luna.text("b"),
  ])
  assert_eq(get_children(node).length(), 2)
}

///|
test "get_static_attr returns static attribute value" {
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [("class", @luna.attr_static("container"))],
    [],
  )
  assert_eq(get_static_attr(node, "class"), Some("container"))
}

///|
test "get_dynamic_attr returns current value" {
  let sig = @signal.signal("initial")
  let node : @luna.Node[Unit] = @luna.h(
    "input",
    [("value", @luna.attr_dynamic(fn() { sig.get() }))],
    [],
  )
  assert_eq(get_dynamic_attr(node, "value"), Some("initial"))
  sig.set("updated")
  assert_eq(get_dynamic_attr(node, "value"), Some("updated"))
}

///|
test "has_handler returns true for handler" {
  let node : @luna.Node[Unit] = @luna.h(
    "button",
    [("onclick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [],
  )
  assert_true(has_handler(node, "onclick"))
}

///|
test "find_by_tag finds element" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.h("span", [], []),
    @luna.h("button", [], [@luna.text("Click")]),
  ])
  assert_true(find_by_tag(node, "button") is Some(_))
}

///|
test "find_all_by_tag finds all elements" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.h("span", [], []),
    @luna.h("div", [], [@luna.h("span", [], [])]),
    @luna.h("span", [], []),
  ])
  let spans = find_all_by_tag(node, "span")
  assert_eq(spans.length(), 3)
}

///|
test "find_by_attr finds element with attribute" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.h("input", [("type", @luna.attr_static("text"))], []),
    @luna.h("input", [("type", @luna.attr_static("submit"))], []),
  ])
  let submit = find_by_attr(node, "type", "submit")
  assert_true(submit is Some(_))
}

///|
test "get_all_text collects all text" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.text("Hello "),
    @luna.h("span", [], [@luna.text("World")]),
  ])
  assert_eq(get_all_text(node), "Hello World")
}

///|
test "contains_text returns true when text exists" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [@luna.text("Hello World")])
  assert_true(contains_text(node, "Hello"))
  assert_true(contains_text(node, "World"))
  assert_false(contains_text(node, "Foo"))
}

///|
test "node_type_name returns correct type" {
  let div : @luna.Node[Unit] = @luna.h("div", [], [])
  let txt : @luna.Node[Unit] = @luna.text("hello")
  let dyn_node : @luna.Node[Unit] = @luna.text_dyn(fn() { "x" })
  let frag : @luna.Node[Unit] = @luna.fragment([])
  assert_eq(node_type_name(div), "Element")
  assert_eq(node_type_name(txt), "Text")
  assert_eq(node_type_name(dyn_node), "DynamicText")
  assert_eq(node_type_name(frag), "Fragment")
}

///|
test "is_element returns true for Element" {
  let div : @luna.Node[Unit] = @luna.h("div", [], [])
  let txt : @luna.Node[Unit] = @luna.text("hello")
  assert_true(is_element(div))
  assert_false(is_element(txt))
}

///|
test "find_by_tag searches through Show" {
  let node : @luna.Node[Unit] = @luna.show(fn() { true }, fn() {
    @luna.h("button", [], [@luna.text("Click")])
  })
  assert_true(find_by_tag(node, "button") is Some(_))
}

///|
test "find_by_tag respects Show condition" {
  let visible = @signal.signal(false)
  let node : @luna.Node[Unit] = @luna.show(fn() { visible.get() }, fn() {
    @luna.h("button", [], [])
  })
  assert_true(find_by_tag(node, "button") is None)
  visible.set(true)
  assert_true(find_by_tag(node, "button") is Some(_))
}

///|
test "get_all_text handles For" {
  let items = @signal.signal(["A", "B", "C"])
  let node : @luna.Node[Unit] = @luna.for_each(fn() {
    items.get().map(fn(item) { @luna.text(item) })
  })
  assert_eq(get_all_text(node), "ABC")
}
