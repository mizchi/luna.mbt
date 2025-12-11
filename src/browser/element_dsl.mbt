///| Element DSL - Simplified API for creating reactive elements

///|

///| Usage:

///|   div(class="myapp", on=on(click=fn(_) { ... }), [text("Hello")])

///|
/// Type alias for event handler
pub type Handler = (@core.Any) -> Unit

// =============================================================================
// AttrVal - Simplified attribute value for attrs array
// =============================================================================

///|
/// Simplified attribute value type for attrs array
pub enum AttrVal {
  String(String)
  Bool(Bool)
  Int(Int)
  Double(Double)
}

///|
/// Convert Double to String using JS toString (avoids MoonBit's ryu algorithm overhead)
fn double_to_string(d : Double) -> String {
  let any : @core.Any = d |> @core.identity
  any._call("toString", []).cast()
}

///|
impl Show for AttrVal with output(self, logger) {
  match self {
    String(s) => logger.write_string(s)
    Bool(b) => logger.write_string(b.to_string())
    Int(i) => logger.write_string(i.to_string())
    Double(d) => logger.write_string(double_to_string(d))
  }
}

///|
/// Convert AttrVal to AttrValue
fn AttrVal::to_attr_value(self : AttrVal) -> AttrValue {
  Static(self.to_string())
}

// =============================================================================
// HandlerMap - Event handlers collection
// =============================================================================

///|
/// Event handlers collection - use with `on()` function
pub struct HandlerMap {
  click : ((@js_dom.MouseEvent) -> Unit)?
  dblclick : ((@js_dom.MouseEvent) -> Unit)?
  input : ((@js_dom.InputEvent) -> Unit)?
  change : ((@js_dom.ChangeEvent) -> Unit)?
  submit : ((@js_dom.FormEvent) -> Unit)?
  keydown : ((@js_dom.KeyboardEvent) -> Unit)?
  keyup : ((@js_dom.KeyboardEvent) -> Unit)?
  keypress : ((@js_dom.KeyboardEvent) -> Unit)?
  focus : ((@js_dom.FocusEvent) -> Unit)?
  blur : ((@js_dom.FocusEvent) -> Unit)?
  mouseenter : ((@js_dom.MouseEvent) -> Unit)?
  mouseleave : ((@js_dom.MouseEvent) -> Unit)?
  mouseover : ((@js_dom.MouseEvent) -> Unit)?
  mouseout : ((@js_dom.MouseEvent) -> Unit)?
  mousedown : ((@js_dom.MouseEvent) -> Unit)?
  mouseup : ((@js_dom.MouseEvent) -> Unit)?
}

///|
/// Create a HandlerMap with optional event handlers
pub fn on(
  click? : ((@js_dom.MouseEvent) -> Unit)? = None,
  dblclick? : ((@js_dom.MouseEvent) -> Unit)? = None,
  input? : ((@js_dom.InputEvent) -> Unit)? = None,
  change? : ((@js_dom.ChangeEvent) -> Unit)? = None,
  submit? : ((@js_dom.FormEvent) -> Unit)? = None,
  keydown? : ((@js_dom.KeyboardEvent) -> Unit)? = None,
  keyup? : ((@js_dom.KeyboardEvent) -> Unit)? = None,
  keypress? : ((@js_dom.KeyboardEvent) -> Unit)? = None,
  focus? : ((@js_dom.FocusEvent) -> Unit)? = None,
  blur? : ((@js_dom.FocusEvent) -> Unit)? = None,
  mouseenter? : ((@js_dom.MouseEvent) -> Unit)? = None,
  mouseleave? : ((@js_dom.MouseEvent) -> Unit)? = None,
  mouseover? : ((@js_dom.MouseEvent) -> Unit)? = None,
  mouseout? : ((@js_dom.MouseEvent) -> Unit)? = None,
  mousedown? : ((@js_dom.MouseEvent) -> Unit)? = None,
  mouseup? : ((@js_dom.MouseEvent) -> Unit)? = None,
) -> HandlerMap {
  {
    click,
    dblclick,
    input,
    change,
    submit,
    keydown,
    keyup,
    keypress,
    focus,
    blur,
    mouseenter,
    mouseleave,
    mouseover,
    mouseout,
    mousedown,
    mouseup,
  }
}

///|
/// Convert HandlerMap to Array of attribute tuples
pub fn HandlerMap::to_attrs(self : HandlerMap) -> Array[(String, AttrValue)] {
  let attrs : Array[(String, AttrValue)] = []
  if self.click is Some(h) {
    attrs.push(("onClick", Handler(h |> @core.identity)))
  }
  if self.dblclick is Some(h) {
    attrs.push(("onDblclick", Handler(h |> @core.identity)))
  }
  if self.input is Some(h) {
    attrs.push(("onInput", Handler(h |> @core.identity)))
  }
  if self.change is Some(h) {
    attrs.push(("onChange", Handler(h |> @core.identity)))
  }
  if self.submit is Some(h) {
    attrs.push(("onSubmit", Handler(h |> @core.identity)))
  }
  if self.keydown is Some(h) {
    attrs.push(("onKeydown", Handler(h |> @core.identity)))
  }
  if self.keyup is Some(h) {
    attrs.push(("onKeyup", Handler(h |> @core.identity)))
  }
  if self.keypress is Some(h) {
    attrs.push(("onKeypress", Handler(h |> @core.identity)))
  }
  if self.focus is Some(h) {
    attrs.push(("onFocus", Handler(h |> @core.identity)))
  }
  if self.blur is Some(h) {
    attrs.push(("onBlur", Handler(h |> @core.identity)))
  }
  if self.mouseenter is Some(h) {
    attrs.push(("onMouseenter", Handler(h |> @core.identity)))
  }
  if self.mouseleave is Some(h) {
    attrs.push(("onMouseleave", Handler(h |> @core.identity)))
  }
  if self.mouseover is Some(h) {
    attrs.push(("onMouseover", Handler(h |> @core.identity)))
  }
  if self.mouseout is Some(h) {
    attrs.push(("onMouseout", Handler(h |> @core.identity)))
  }
  if self.mousedown is Some(h) {
    attrs.push(("onMousedown", Handler(h |> @core.identity)))
  }
  if self.mouseup is Some(h) {
    attrs.push(("onMouseup", Handler(h |> @core.identity)))
  }
  attrs
}


// =============================================================================
// Internal: Build props from DSL parameters
// =============================================================================

///|
fn build_props(
  id : String?,
  class : String?,
  style : Array[(String, String)]?,
  on : HandlerMap?,
  attrs : Array[(String, AttrVal)]?,
) -> Array[(String, AttrValue)] {
  let result : Array[(String, AttrValue)] = []

  // id
  match id {
    Some(v) => result.push(("id", Static(v)))
    None => ()
  }

  // class
  match class {
    Some(v) => result.push(("className", Static(v)))
    None => ()
  }

  // style
  match style {
    Some(styles) => result.push(("style", StyleObj(styles)))
    None => ()
  }

  // event handlers
  match on {
    Some(handlers) => {
      let event_attrs = handlers.to_attrs()
      for attr in event_attrs {
        result.push(attr)
      }
    }
    None => ()
  }

  // additional attrs
  match attrs {
    Some(extra) => {
      for pair in extra {
        let (key, val) = pair
        result.push((key, val.to_attr_value()))
      }
    }
    None => ()
  }
  result
}

// =============================================================================
// Element factories with DSL syntax
// =============================================================================

///|
/// Create a div element
pub fn div(
  id? : String,
  class? : String,
  style? : Array[(String, String)],
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
  style? : Array[(String, String)],
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
  style? : Array[(String, String)],
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
  style? : Array[(String, String)],
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
  style? : Array[(String, String)],
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
  style? : Array[(String, String)],
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
  style? : Array[(String, String)],
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
  style? : Array[(String, String)],
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
  style? : Array[(String, String)],
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
  style? : Array[(String, String)],
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
  style? : Array[(String, String)],
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
  style? : Array[(String, String)],
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
  style? : Array[(String, String)],
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
  style? : Array[(String, String)],
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
  style? : Array[(String, String)],
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
  style? : Array[(String, String)],
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
/// Create a static style object
pub fn attr_style(styles : Array[(String, String)]) -> AttrValue {
  StyleObj(styles)
}

///|
/// Create a dynamic style
pub fn attr_dynamic_style(getter : () -> Array[(String, String)]) -> AttrValue {
  DynamicStyle(getter)
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
