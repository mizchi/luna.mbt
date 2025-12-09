///| Tests for UI library

///| VNode construction tests

///|
test "create empty VNode" {
  let node : JSVNode = empty()
  inspect(node.is_empty(), content="true")
}

///|
test "create text VNode" {
  let node : JSVNode = text("Hello")
  inspect(node.debug_string(), content="Text(\"Hello\")")
}

///|
test "create div element with empty props" {
  let node : JSVNode = div([], [text("content")])
  inspect(node.debug_string(), content="Element(div, 1 children)")
}

///|
test "create nested elements" {
  let node : JSVNode = div([], [
    h1([], [text("Title")]),
    p([], [text("Paragraph")]),
  ])
  inspect(node.debug_string(), content="Element(div, 2 children)")
}

///|
test "create fragment" {
  let node : JSVNode = fragment([text("A"), text("B"), text("C")])
  inspect(node.debug_string(), content="Fragment(3 children)")
}

///| Props with typed API tests

///|
test "element with props" {
  let node : JSVNode = div([class_name("container")], [text("content")])
  inspect(node.debug_string(), content="Element(div, 1 children)")
}

///|
test "button with props and handler" {
  let node : JSVNode = button(
    [class_name("btn"), on_click(fn(_event : @core.Any) { () })],
    [text("Click")],
  )
  inspect(node.debug_string(), content="Element(button, 1 children)")
}

///|
test "input with props" {
  let node : JSVNode = input([type_("text"), placeholder("Enter text")])
  inspect(node.debug_string(), content="Element(input, 0 children)")
}

///| Props with multiple attributes

///|
test "element with multiple props" {
  let props : JSProps = [class_name("my-class"), id("my-id")]
  let node : JSVNode = div(props, [text("content")])
  inspect(node.debug_string(), content="Element(div, 1 children)")
}

///|
test "element with style" {
  let props : JSProps = [style([("color", "red"), ("fontSize", "16px")])]
  let node : JSVNode = div(props, [text("styled")])
  inspect(node.debug_string(), content="Element(div, 1 children)")
}

///| Element with key

///|
test "element with key" {
  let empty_props : JSProps = []
  let node : JSVNode = el_key("li", empty_props, [text("Item")], "item-1")
  match node.get_key() {
    Some(key) => inspect(key, content="item-1")
    None => inspect(false, content="true")
  }
}

///| No-props elements

///|
test "br and hr elements" {
  let br_node : JSVNode = br()
  let hr_node : JSVNode = hr()
  inspect(br_node.debug_string(), content="Element(br, 0 children)")
  inspect(hr_node.debug_string(), content="Element(hr, 0 children)")
}
