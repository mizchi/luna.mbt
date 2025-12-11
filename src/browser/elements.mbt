// =============================================================================
// Element factories with DSL syntax
// =============================================================================

///|
/// Create a div element
pub fn div(
  id? : String,
  class? : String,
  style? : String,
  on? : HandlerMap,
  attrs? : Array[(String, AttrVal)],
  children : Array[Node],
) -> Node {
  create_element("div", build_props(id, class, style, on, attrs), children)
}

///|
/// Create a span element
pub fn span(
  id? : String,
  class? : String,
  style? : String,
  on? : HandlerMap,
  attrs? : Array[(String, AttrVal)],
  children : Array[Node],
) -> Node {
  create_element("span", build_props(id, class, style, on, attrs), children)
}

///|
/// Create a p element
pub fn p(
  id? : String,
  class? : String,
  style? : String,
  on? : HandlerMap,
  attrs? : Array[(String, AttrVal)],
  children : Array[Node],
) -> Node {
  create_element("p", build_props(id, class, style, on, attrs), children)
}

///|
/// Create a button element
pub fn button(
  id? : String,
  class? : String,
  style? : String,
  on? : HandlerMap,
  attrs? : Array[(String, AttrVal)],
  disabled? : Bool,
  children : Array[Node],
) -> Node {
  let props = build_props(id, class, style, on, attrs)
  match disabled {
    Some(true) => props.push(("disabled", Static("true")))
    _ => ()
  }
  create_element("button", props, children)
}

///|
/// Create an anchor element
pub fn a(
  href? : String,
  id? : String,
  class? : String,
  style? : String,
  on? : HandlerMap,
  attrs? : Array[(String, AttrVal)],
  children : Array[Node],
) -> Node {
  let props = build_props(id, class, style, on, attrs)
  match href {
    Some(v) => props.push(("href", Static(v)))
    None => ()
  }
  create_element("a", props, children)
}

///|
/// Create an input element
pub fn input(
  id? : String,
  class? : String,
  style? : String,
  on? : HandlerMap,
  attrs? : Array[(String, AttrVal)],
  type_? : String,
  value? : String,
  placeholder? : String,
  disabled? : Bool,
) -> Node {
  let props = build_props(id, class, style, on, attrs)
  match type_ {
    Some(v) => props.push(("type", Static(v)))
    None => ()
  }
  match value {
    Some(v) => props.push(("value", Static(v)))
    None => ()
  }
  match placeholder {
    Some(v) => props.push(("placeholder", Static(v)))
    None => ()
  }
  match disabled {
    Some(true) => props.push(("disabled", Static("true")))
    _ => ()
  }
  create_element("input", props, [])
}

///|
/// Create a textarea element
pub fn textarea(
  id? : String,
  class? : String,
  style? : String,
  on? : HandlerMap,
  attrs? : Array[(String, AttrVal)],
  placeholder? : String,
  disabled? : Bool,
  children : Array[Node],
) -> Node {
  let props = build_props(id, class, style, on, attrs)
  match placeholder {
    Some(v) => props.push(("placeholder", Static(v)))
    None => ()
  }
  match disabled {
    Some(true) => props.push(("disabled", Static("true")))
    _ => ()
  }
  create_element("textarea", props, children)
}

///|
/// Create a form element
pub fn form(
  id? : String,
  class? : String,
  style? : String,
  on? : HandlerMap,
  attrs? : Array[(String, AttrVal)],
  children : Array[Node],
) -> Node {
  create_element("form", build_props(id, class, style, on, attrs), children)
}

///|
/// Create a label element
pub fn label(
  for_? : String,
  id? : String,
  class? : String,
  style? : String,
  on? : HandlerMap,
  attrs? : Array[(String, AttrVal)],
  children : Array[Node],
) -> Node {
  let props = build_props(id, class, style, on, attrs)
  match for_ {
    Some(v) => props.push(("for", Static(v)))
    None => ()
  }
  create_element("label", props, children)
}

///|
/// Create h1 element
pub fn h1(
  id? : String,
  class? : String,
  style? : String,
  on? : HandlerMap,
  attrs? : Array[(String, AttrVal)],
  children : Array[Node],
) -> Node {
  create_element("h1", build_props(id, class, style, on, attrs), children)
}

///|
/// Create h2 element
pub fn h2(
  id? : String,
  class? : String,
  style? : String,
  on? : HandlerMap,
  attrs? : Array[(String, AttrVal)],
  children : Array[Node],
) -> Node {
  create_element("h2", build_props(id, class, style, on, attrs), children)
}

///|
/// Create h3 element
pub fn h3(
  id? : String,
  class? : String,
  style? : String,
  on? : HandlerMap,
  attrs? : Array[(String, AttrVal)],
  children : Array[Node],
) -> Node {
  create_element("h3", build_props(id, class, style, on, attrs), children)
}

///|
/// Create ul element
pub fn ul(
  id? : String,
  class? : String,
  style? : String,
  on? : HandlerMap,
  attrs? : Array[(String, AttrVal)],
  children : Array[Node],
) -> Node {
  create_element("ul", build_props(id, class, style, on, attrs), children)
}

///|
/// Create ol element
pub fn ol(
  id? : String,
  class? : String,
  style? : String,
  on? : HandlerMap,
  attrs? : Array[(String, AttrVal)],
  children : Array[Node],
) -> Node {
  create_element("ol", build_props(id, class, style, on, attrs), children)
}

///|
/// Create li element
pub fn li(
  id? : String,
  class? : String,
  style? : String,
  on? : HandlerMap,
  attrs? : Array[(String, AttrVal)],
  children : Array[Node],
) -> Node {
  create_element("li", build_props(id, class, style, on, attrs), children)
}

///|
/// Create img element
pub fn img(
  src? : String,
  alt? : String,
  id? : String,
  class? : String,
  style? : String,
  on? : HandlerMap,
  attrs? : Array[(String, AttrVal)],
) -> Node {
  let props = build_props(id, class, style, on, attrs)
  match src {
    Some(v) => props.push(("src", Static(v)))
    None => ()
  }
  match alt {
    Some(v) => props.push(("alt", Static(v)))
    None => ()
  }
  create_element("img", props, [])
}

///|
/// Create br element
pub fn br() -> Node {
  create_element("br", [], [])
}

///|
/// Create hr element
pub fn hr() -> Node {
  create_element("hr", [], [])
}

// =============================================================================
// Text helpers
// =============================================================================

///|
/// Create a static text node
pub fn text(content : String) -> Node {
  ToNode::to_node(content)
}

///|
/// Create a reactive text node from a getter function
pub fn text_dyn(content : () -> String) -> Node {
  text_node(content)
}

///|
/// Create a reactive text node from a signal
pub fn[T : Show] text_sig(sig : @signal.Signal[T]) -> Node {
  text_from_signal(sig)
}

// =============================================================================
// AttrValue factory functions for external use
// =============================================================================

///|
/// Create a static attribute value
pub fn attr_static(value : String) -> AttrValue {
  Static(value)
}

///|
/// Create a dynamic attribute value
pub fn attr_dynamic(getter : () -> String) -> AttrValue {
  Dynamic(getter)
}

///|
/// Create an event handler attribute
pub fn attr_handler(handler : (@core.Any) -> Unit) -> AttrValue {
  Handler(handler)
}

///|
/// Create a static style attribute (string form, e.g. "color: red; margin: 10px")
pub fn attr_style(style : String) -> AttrValue {
  Static(style)
}

///|
/// Create a dynamic style attribute
pub fn attr_dynamic_style(getter : () -> String) -> AttrValue {
  Dynamic(getter)
}

// =============================================================================
// JSX Runtime - For TSX/JSX compatibility
// =============================================================================

///|
/// JSX runtime: jsx function (maps directly to create_element)
/// Usage in TSX: <div class="foo">children</div>
pub fn jsx(
  tag : String,
  attrs : Array[(String, AttrValue)],
  children : Array[Node],
) -> Node {
  create_element(tag, attrs, children)
}

///|
/// JSX runtime: jsxs function (same as jsx, for static children)
pub fn jsxs(
  tag : String,
  attrs : Array[(String, AttrValue)],
  children : Array[Node],
) -> Node {
  create_element(tag, attrs, children)
}

///|
/// JSX runtime: Fragment (returns children as-is wrapped in a container)
pub fn fragment(children : Array[Node]) -> Node {
  // Return a document fragment or first child
  // For simplicity, wrap in a span with no attributes
  // In production, this should return a proper fragment
  match children.length() {
    0 => create_element("span", [], [])
    1 => children[0]
    _ => create_element("span", [], children)
  }
}

// =============================================================================
// AttrVal factory functions - ensure all variants are used
// =============================================================================

///|
/// Create a String AttrVal
pub fn attr_string(value : String) -> AttrVal {
  String(value)
}

///|
/// Create a Bool AttrVal
pub fn attr_bool(value : Bool) -> AttrVal {
  Bool(value)
}

///|
/// Create an Int AttrVal
pub fn attr_int(value : Int) -> AttrVal {
  Int(value)
}

///|
/// Create a Double AttrVal
pub fn attr_double(value : Double) -> AttrVal {
  Double(value)
}
