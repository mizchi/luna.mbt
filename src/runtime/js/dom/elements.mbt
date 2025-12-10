///| HTML Element Helpers - Convenient functions for creating reactive elements

///|
/// Type alias for event handler
pub type Handler = (@core.Any) -> Unit

///|
/// Create a div element
pub fn div(attrs : Array[(String, AttrValue)], children : Array[Node]) -> Node {
  create_element("div", attrs, children)
}

///|
/// Create a span element
pub fn span(attrs : Array[(String, AttrValue)], children : Array[Node]) -> Node {
  create_element("span", attrs, children)
}

///|
/// Create a p element
pub fn p(attrs : Array[(String, AttrValue)], children : Array[Node]) -> Node {
  create_element("p", attrs, children)
}

///|
/// Create a button element
pub fn button(
  attrs : Array[(String, AttrValue)],
  children : Array[Node],
) -> Node {
  create_element("button", attrs, children)
}

///|
/// Create an a element
pub fn a(attrs : Array[(String, AttrValue)], children : Array[Node]) -> Node {
  create_element("a", attrs, children)
}

///|
/// Create an input element
pub fn input(attrs : Array[(String, AttrValue)]) -> Node {
  create_element("input", attrs, [])
}

///|
/// Create a textarea element
pub fn textarea(
  attrs : Array[(String, AttrValue)],
  children : Array[Node],
) -> Node {
  create_element("textarea", attrs, children)
}

///|
/// Create a form element
pub fn form(
  attrs : Array[(String, AttrValue)],
  children : Array[Node],
) -> Node {
  create_element("form", attrs, children)
}

///|
/// Create a label element
pub fn label(
  attrs : Array[(String, AttrValue)],
  children : Array[Node],
) -> Node {
  create_element("label", attrs, children)
}

///|
/// Create h1 element
pub fn h1(attrs : Array[(String, AttrValue)], children : Array[Node]) -> Node {
  create_element("h1", attrs, children)
}

///|
/// Create h2 element
pub fn h2(attrs : Array[(String, AttrValue)], children : Array[Node]) -> Node {
  create_element("h2", attrs, children)
}

///|
/// Create h3 element
pub fn h3(attrs : Array[(String, AttrValue)], children : Array[Node]) -> Node {
  create_element("h3", attrs, children)
}

///|
/// Create ul element
pub fn ul(attrs : Array[(String, AttrValue)], children : Array[Node]) -> Node {
  create_element("ul", attrs, children)
}

///|
/// Create ol element
pub fn ol(attrs : Array[(String, AttrValue)], children : Array[Node]) -> Node {
  create_element("ol", attrs, children)
}

///|
/// Create li element
pub fn li(attrs : Array[(String, AttrValue)], children : Array[Node]) -> Node {
  create_element("li", attrs, children)
}

///|
/// Create img element
pub fn img(attrs : Array[(String, AttrValue)]) -> Node {
  create_element("img", attrs, [])
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

// Attribute helpers

///|
/// Create a static className attribute
pub fn class(value : String) -> (String, AttrValue) {
  ("className", Static(value))
}

///|
/// Create a dynamic className attribute
pub fn class_name_dyn(getter : () -> String) -> (String, AttrValue) {
  ("className", Dynamic(getter))
}

///|
/// Create a static id attribute
pub fn id(value : String) -> (String, AttrValue) {
  ("id", Static(value))
}

///|
/// Create a static href attribute
pub fn href(value : String) -> (String, AttrValue) {
  ("href", Static(value))
}

///|
/// Create a static src attribute
pub fn src(value : String) -> (String, AttrValue) {
  ("src", Static(value))
}

///|
/// Create a static alt attribute
pub fn alt(value : String) -> (String, AttrValue) {
  ("alt", Static(value))
}

///|
/// Create a static placeholder attribute
pub fn placeholder(value : String) -> (String, AttrValue) {
  ("placeholder", Static(value))
}

///|
/// Create a static value attribute
pub fn value(val : String) -> (String, AttrValue) {
  ("value", Static(val))
}

///|
/// Create a dynamic value attribute
pub fn value_dyn(getter : () -> String) -> (String, AttrValue) {
  ("value", Dynamic(getter))
}

///|
/// Create a static type attribute
pub fn type_(value : String) -> (String, AttrValue) {
  ("type", Static(value))
}

///|
/// Create a static disabled attribute
pub fn disabled(val : Bool) -> (String, AttrValue) {
  ("disabled", Static(if val { "true" } else { "false" }))
}

///|
/// Create a dynamic disabled attribute
pub fn disabled_dyn(getter : () -> Bool) -> (String, AttrValue) {
  ("disabled", Dynamic(fn() { if getter() { "true" } else { "false" } }))
}

// Type-safe event handlers using mizchi/js/browser/dom event types

///|
/// Create an onClick handler with typed MouseEvent
pub fn on_click(handler : (@js_dom.MouseEvent) -> Unit) -> (String, AttrValue) {
  let wrapper : (@core.Any) -> Unit = fn(e) { handler(e.cast()) }
  ("onClick", Handler(wrapper))
}

///|
/// Create an onInput handler with typed InputEvent
pub fn on_input(handler : (@js_dom.InputEvent) -> Unit) -> (String, AttrValue) {
  let wrapper : (@core.Any) -> Unit = fn(e) { handler(e.cast()) }
  ("onInput", Handler(wrapper))
}

///|
/// Create an onChange handler with typed ChangeEvent
pub fn on_change(handler : (@js_dom.ChangeEvent) -> Unit) -> (String, AttrValue) {
  let wrapper : (@core.Any) -> Unit = fn(e) { handler(e.cast()) }
  ("onChange", Handler(wrapper))
}

///|
/// Create an onSubmit handler with typed FormEvent
pub fn on_submit(handler : (@js_dom.FormEvent) -> Unit) -> (String, AttrValue) {
  let wrapper : (@core.Any) -> Unit = fn(e) { handler(e.cast()) }
  ("onSubmit", Handler(wrapper))
}

///|
/// Create an onKeyDown handler with typed KeyboardEvent
pub fn on_key_down(
  handler : (@js_dom.KeyboardEvent) -> Unit,
) -> (String, AttrValue) {
  let wrapper : (@core.Any) -> Unit = fn(e) { handler(e.cast()) }
  ("onKeyDown", Handler(wrapper))
}

///|
/// Create an onKeyUp handler with typed KeyboardEvent
pub fn on_key_up(handler : (@js_dom.KeyboardEvent) -> Unit) -> (String, AttrValue) {
  let wrapper : (@core.Any) -> Unit = fn(e) { handler(e.cast()) }
  ("onKeyUp", Handler(wrapper))
}

///|
/// Create an onFocus handler with typed FocusEvent
pub fn on_focus(handler : (@js_dom.FocusEvent) -> Unit) -> (String, AttrValue) {
  let wrapper : (@core.Any) -> Unit = fn(e) { handler(e.cast()) }
  ("onFocus", Handler(wrapper))
}

///|
/// Create an onBlur handler with typed FocusEvent
pub fn on_blur(handler : (@js_dom.FocusEvent) -> Unit) -> (String, AttrValue) {
  let wrapper : (@core.Any) -> Unit = fn(e) { handler(e.cast()) }
  ("onBlur", Handler(wrapper))
}

///|
/// Create an onMouseEnter handler with typed MouseEvent
pub fn on_mouse_enter(
  handler : (@js_dom.MouseEvent) -> Unit,
) -> (String, AttrValue) {
  let wrapper : (@core.Any) -> Unit = fn(e) { handler(e.cast()) }
  ("onMouseEnter", Handler(wrapper))
}

///|
/// Create an onMouseLeave handler with typed MouseEvent
pub fn on_mouse_leave(
  handler : (@js_dom.MouseEvent) -> Unit,
) -> (String, AttrValue) {
  let wrapper : (@core.Any) -> Unit = fn(e) { handler(e.cast()) }
  ("onMouseLeave", Handler(wrapper))
}

///|
/// Create a static style attribute
pub fn style(styles : Array[(String, String)]) -> (String, AttrValue) {
  ("style", StyleObj(styles))
}

///|
/// Create a dynamic style attribute
pub fn style_dyn(getter : () -> Array[(String, String)]) -> (String, AttrValue) {
  ("style", DynamicStyle(getter))
}

///|
/// Create a generic static attribute
pub fn attr(key : String, value : String) -> (String, AttrValue) {
  (key, Static(value))
}

///|
/// Create a generic dynamic attribute
pub fn attr_dyn(key : String, getter : () -> String) -> (String, AttrValue) {
  (key, Dynamic(getter))
}
