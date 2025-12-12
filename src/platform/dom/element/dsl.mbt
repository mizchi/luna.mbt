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
pub type Handler = (@js.Any) -> Unit

// =============================================================================
// Attr - Attribute value for attrs array
// =============================================================================

///|
/// Attribute value type for attrs array
/// Usage: Attr::AttrString("value"), Attr::AttrInt(42), etc.
pub(all) enum Attr {
  AttrString(String)
  AttrNumber(Double)
  AttrInt(Int)
  AttrBool(Bool)
}

///|
/// Convert Double to String using JS toString
/// Note: We avoid MoonBit's Double.to_string() which uses ryu algorithm (~31KB overhead)
fn double_to_string(d : Double) -> String {
  let any : @js.Any = d |> @js.identity
  any._call("toString", []).cast()
}

///|
impl Show for Attr with output(self, logger) {
  match self {
    AttrString(s) => logger.write_string(s)
    AttrNumber(d) => logger.write_string(double_to_string(d))
    AttrInt(i) => logger.write_string(i.to_string())
    AttrBool(b) => logger.write_string(b.to_string())
  }
}

///|
/// Convert Attr to AttrValue
pub fn Attr::to_attr_value(self : Attr) -> AttrValue {
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
///
/// Each handler receives the appropriate typed event:
/// - click, dblclick, mouseenter, etc. -> MouseHandler (@js_dom.MouseEvent)
/// - keydown, keyup, keypress -> KeyboardHandler (@js_dom.KeyboardEvent)
/// - input -> InputHandler (@js_dom.InputEvent)
/// - change -> ChangeHandler (@js_dom.ChangeEvent)
/// - submit -> FormHandler (@js_dom.FormEvent)
/// - focus, blur -> FocusHandler (@js_dom.FocusEvent)
///
/// For type-safe target element access, use the generic versions:
/// - MouseEventHandler[HTMLButtonElement], ChangeEventHandler[HTMLInputElement], etc.
pub extern "js" fn on(
  click? : MouseHandler?,
  dblclick? : MouseHandler?,
  input? : InputHandler?,
  change? : ChangeHandler?,
  submit? : FormHandler?,
  keydown? : KeyboardHandler?,
  keyup? : KeyboardHandler?,
  keypress? : KeyboardHandler?,
  focus? : FocusHandler?,
  blur? : FocusHandler?,
  mouseenter? : MouseHandler?,
  mouseleave? : MouseHandler?,
  mouseover? : MouseHandler?,
  mouseout? : MouseHandler?,
  mousedown? : MouseHandler?,
  mouseup? : MouseHandler?,
) -> HandlerMap =
  #|(click, dblclick, input, change, submit, keydown, keyup, keypress, focus, blur, mouseenter, mouseleave, mouseover, mouseout, mousedown, mouseup) => {
  #|  const m = {};
  #|  if (click?._0) m.click = click._0;
  #|  if (dblclick?._0) m.dblclick = dblclick._0;
  #|  if (input?._0) m.input = input._0;
  #|  if (change?._0) m.change = change._0;
  #|  if (submit?._0) m.submit = submit._0;
  #|  if (keydown?._0) m.keydown = keydown._0;
  #|  if (keyup?._0) m.keyup = keyup._0;
  #|  if (keypress?._0) m.keypress = keypress._0;
  #|  if (focus?._0) m.focus = focus._0;
  #|  if (blur?._0) m.blur = blur._0;
  #|  if (mouseenter?._0) m.mouseenter = mouseenter._0;
  #|  if (mouseleave?._0) m.mouseleave = mouseleave._0;
  #|  if (mouseover?._0) m.mouseover = mouseover._0;
  #|  if (mouseout?._0) m.mouseout = mouseout._0;
  #|  if (mousedown?._0) m.mousedown = mousedown._0;
  #|  if (mouseup?._0) m.mouseup = mouseup._0;
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
  ref_ : ElementRef?,
  attrs : Array[(String, Attr)]?,
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

  // ref callback - stored as special __ref key with Handler variant
  // Will be processed during render to call the callback with the element
  match ref_ {
    Some(cb) => {
      // Wrap ElementRef callback as Handler for storage in AttrValue
      // ElementRef is type alias for (@js_dom.Element) -> Unit
      let handler : (@js.Any) -> Unit = fn(el) { cb(el.cast()) }
      result.push(("__ref", Handler(handler)))
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
