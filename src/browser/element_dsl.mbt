///| Element DSL - Simplified API for creating reactive elements

///|

///| Usage:

///|   div(class="myapp", on=on(click=fn(_) { ... }), [text("Hello")])

///|

///| ## Bundle Size Optimization Notes

///|

///| This module uses JS FFI extensively to minimize bundle size:

///|

///| 1. **Double.to_string via JS FFI**: MoonBit's native Double.to_string uses the

///|    ryu algorithm which pulls in ~31KB of Int64 operations. We use JS's native

///|    toString() instead.

///|

///| 2. **HandlerMap as opaque JS object**: Instead of a MoonBit struct with 16 fields,

///|    we use a plain JS object created via FFI. This avoids generating large

///|    to_attrs() functions with 16 if-statements.

///|

///| 3. **Lowercase event names**: Event names are stored as lowercase DOM standard

///|    names (click, input) instead of React-style camelCase (onClick, onInput).

///|    This avoids runtime string conversion and prevents future bloat from

///|    conversion dictionaries.

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
/// Convert Double to String using JS toString
/// Note: We avoid MoonBit's Double.to_string() which uses ryu algorithm (~31KB overhead)
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
// HandlerMap - Event handlers collection (JS FFI optimized)
// =============================================================================

///|
/// Event handlers collection - opaque JS object
/// Internally stores { click?: fn, input?: fn, ... } (lowercase DOM event names)
/// Note: Using opaque JS object instead of MoonBit struct to avoid code bloat
pub type HandlerMap

///|
/// Create a HandlerMap with optional event handlers
/// Uses JS FFI to create a plain object directly, avoiding MoonBit struct overhead
/// Event names are lowercase DOM standard (click, not onClick) to avoid conversion
pub extern "js" fn on(
  click? : ((@js_dom.MouseEvent) -> Unit)?,
  dblclick? : ((@js_dom.MouseEvent) -> Unit)?,
  input? : ((@js_dom.InputEvent) -> Unit)?,
  change? : ((@js_dom.ChangeEvent) -> Unit)?,
  submit? : ((@js_dom.FormEvent) -> Unit)?,
  keydown? : ((@js_dom.KeyboardEvent) -> Unit)?,
  keyup? : ((@js_dom.KeyboardEvent) -> Unit)?,
  keypress? : ((@js_dom.KeyboardEvent) -> Unit)?,
  focus? : ((@js_dom.FocusEvent) -> Unit)?,
  blur? : ((@js_dom.FocusEvent) -> Unit)?,
  mouseenter? : ((@js_dom.MouseEvent) -> Unit)?,
  mouseleave? : ((@js_dom.MouseEvent) -> Unit)?,
  mouseover? : ((@js_dom.MouseEvent) -> Unit)?,
  mouseout? : ((@js_dom.MouseEvent) -> Unit)?,
  mousedown? : ((@js_dom.MouseEvent) -> Unit)?,
  mouseup? : ((@js_dom.MouseEvent) -> Unit)?,
) -> HandlerMap =
  #|(click, dblclick, input, change, submit, keydown, keyup, keypress, focus, blur, mouseenter, mouseleave, mouseover, mouseout, mousedown, mouseup) => {
  #|  const m = {};
  #|  if (click) m.click = click;
  #|  if (dblclick) m.dblclick = dblclick;
  #|  if (input) m.input = input;
  #|  if (change) m.change = change;
  #|  if (submit) m.submit = submit;
  #|  if (keydown) m.keydown = keydown;
  #|  if (keyup) m.keyup = keyup;
  #|  if (keypress) m.keypress = keypress;
  #|  if (focus) m.focus = focus;
  #|  if (blur) m.blur = blur;
  #|  if (mouseenter) m.mouseenter = mouseenter;
  #|  if (mouseleave) m.mouseleave = mouseleave;
  #|  if (mouseover) m.mouseover = mouseover;
  #|  if (mouseout) m.mouseout = mouseout;
  #|  if (mousedown) m.mousedown = mousedown;
  #|  if (mouseup) m.mouseup = mouseup;
  #|  return m;
  #|}

///|
/// Convert HandlerMap to Array of attribute tuples using JS Object.entries
/// Keys are already lowercase event names, tag 2 = Handler variant
extern "js" fn HandlerMap::to_attrs(
  self : HandlerMap,
) -> Array[(String, AttrValue)] =
  #|(m) => Object.entries(m).map(([k, v]) => ({ _0: k, _1: { $tag: 2, _0: v } }))

// =============================================================================
// Internal: Build props from DSL parameters
// =============================================================================

///|
fn build_props(
  id : String?,
  class : String?,
  style : String?,
  on : HandlerMap?,
  attrs : Array[(String, AttrVal)]?,
) -> Array[(String, AttrValue)] {
  let result : Array[(String, AttrValue)] = []

  // id
  if id is Some(v) {
    result.push(("id", Static(v)))
  }

  // class
  if class is Some(v) {
    result.push(("className", Static(v)))
  }

  // style (now a simple string like "color: red; margin: 10px")
  if style is Some(s) {
    result.push(("style", Static(s)))
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
    Some(extra) =>
      for pair in extra {
        let (key, val) = pair
        result.push((key, val.to_attr_value()))
      }
    None => ()
  }
  result
}
