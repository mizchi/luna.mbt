// Element DSL - Simplified API for creating reactive elements
//
// Usage:
// div(class="myapp", on=events().click(fn(_) { ... }), [text("Hello")])
//
// ## Bundle Size Optimization Notes
//
// This module uses JS FFI extensively to minimize bundle size:
//
// 1. **Double.to_string via JS FFI**: MoonBit's native Double.to_string uses the
// ryu algorithm which pulls in ~31KB of Int64 operations. We use JS's native
// toString() instead.
//
// 2. **HandlerMap as opaque JS object**: Instead of a MoonBit struct with 16 fields,
// we use a plain JS object created via FFI. This avoids generating large
// to_attrs() functions with 16 if-statements.
//
// 3. **Lowercase event names**: Event names are stored as lowercase DOM standard
// names (click, input) instead of React-style camelCase (onClick, onInput).
// This avoids runtime string conversion and prevents future bloat from
// conversion dictionaries.
//
// 4. **Method chaining via events() DSL**: Using events().click(...).input(...)
// instead of on(click=Some(...)) avoids generating Option wrappers for all
// 16 event types. MoonBit's dead code elimination removes unused handlers.
//

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
/// Create an empty HandlerMap, then chain event handlers
/// Example: events().click(fn(_) { ... }).input(fn(e) { ... })
///
/// Each handler receives the appropriate typed event:
/// - click, dblclick, mouseenter, etc. -> MouseHandler (@js_dom.MouseEvent)
/// - keydown, keyup, keypress -> KeyboardHandler (@js_dom.KeyboardEvent)
/// - input -> InputHandler (@js_dom.InputEvent)
/// - change -> ChangeHandler (@js_dom.ChangeEvent)
/// - submit -> FormHandler (@js_dom.FormEvent)
/// - focus, blur -> FocusHandler (@js_dom.FocusEvent)
pub fn events() -> HandlerMap {
  @js.new_object().cast()
}

///|
pub extern "js" fn HandlerMap::click(
  self : Self,
  handler : MouseHandler,
) -> HandlerMap =
  #|(m, handler) => { m.click = handler; return m; }

///|
pub extern "js" fn HandlerMap::dblclick(
  self : Self,
  handler : MouseHandler,
) -> HandlerMap =
  #|(m, handler) => { m.dblclick = handler; return m; }

///|
pub extern "js" fn HandlerMap::input(
  self : Self,
  handler : InputHandler,
) -> HandlerMap =
  #|(m, handler) => { m.input = handler; return m; }

///|
pub extern "js" fn HandlerMap::change(
  self : Self,
  handler : ChangeHandler,
) -> HandlerMap =
  #|(m, handler) => { m.change = handler; return m; }

///|
pub extern "js" fn HandlerMap::submit(
  self : Self,
  handler : FormHandler,
) -> HandlerMap =
  #|(m, handler) => { m.submit = handler; return m; }

///|
pub extern "js" fn HandlerMap::keydown(
  self : Self,
  handler : KeyboardHandler,
) -> HandlerMap =
  #|(m, handler) => { m.keydown = handler; return m; }

///|
pub extern "js" fn HandlerMap::keyup(
  self : Self,
  handler : KeyboardHandler,
) -> HandlerMap =
  #|(m, handler) => { m.keyup = handler; return m; }

///|
pub extern "js" fn HandlerMap::keypress(
  self : Self,
  handler : KeyboardHandler,
) -> HandlerMap =
  #|(m, handler) => { m.keypress = handler; return m; }

///|
pub extern "js" fn HandlerMap::focus(
  self : Self,
  handler : FocusHandler,
) -> HandlerMap =
  #|(m, handler) => { m.focus = handler; return m; }

///|
pub extern "js" fn HandlerMap::blur(
  self : Self,
  handler : FocusHandler,
) -> HandlerMap =
  #|(m, handler) => { m.blur = handler; return m; }

///|
pub extern "js" fn HandlerMap::mouseenter(
  self : Self,
  handler : MouseHandler,
) -> HandlerMap =
  #|(m, handler) => { m.mouseenter = handler; return m; }

///|
pub extern "js" fn HandlerMap::mouseleave(
  self : Self,
  handler : MouseHandler,
) -> HandlerMap =
  #|(m, handler) => { m.mouseleave = handler; return m; }

///|
pub extern "js" fn HandlerMap::mouseover(
  self : Self,
  handler : MouseHandler,
) -> HandlerMap =
  #|(m, handler) => { m.mouseover = handler; return m; }

///|
pub extern "js" fn HandlerMap::mouseout(
  self : Self,
  handler : MouseHandler,
) -> HandlerMap =
  #|(m, handler) => { m.mouseout = handler; return m; }

///|
pub extern "js" fn HandlerMap::mousedown(
  self : Self,
  handler : MouseHandler,
) -> HandlerMap =
  #|(m, handler) => { m.mousedown = handler; return m; }

///|
pub extern "js" fn HandlerMap::mouseup(
  self : Self,
  handler : MouseHandler,
) -> HandlerMap =
  #|(m, handler) => { m.mouseup = handler; return m; }

///|
/// Composition start event (for IME input)
pub extern "js" fn HandlerMap::compositionstart(
  self : Self,
  handler : Handler,
) -> HandlerMap =
  #|(m, handler) => { m.compositionstart = handler; return m; }

///|
/// Composition end event (for IME input)
pub extern "js" fn HandlerMap::compositionend(
  self : Self,
  handler : Handler,
) -> HandlerMap =
  #|(m, handler) => { m.compositionend = handler; return m; }

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
  dyn_attrs? : Array[(String, AttrValue)]? = None,
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
  if on is Some(handlers) {
    for attr in handlers.to_attrs() {
      result.push(attr)
    }
  }

  // ref callback - stored as special __ref key with Handler variant
  // Will be processed during render to call the callback with the element
  if ref_ is Some(cb) {
    // Wrap ElementRef callback as Handler for storage in AttrValue
    // ElementRef is type alias for (@js_dom.Element) -> Unit
    let handler : (@js.Any) -> Unit = fn(el) { cb(el.cast()) }
    result.push(("__ref", Handler(handler)))
  }

  // additional static attrs
  if attrs is Some(extra) {
    for pair in extra {
      result.push((pair.0, pair.1.to_attr_value()))
    }
  }

  // additional dynamic attrs (AttrValue - can include Dynamic, Handler)
  if dyn_attrs is Some(extra) {
    for pair in extra {
      result.push(pair)
    }
  }
  result
}

// =============================================================================
// use_style - CSS injection for Shadow DOM / document.head
// =============================================================================

///|
/// Inject CSS into the ShadowRoot containing the element, or document.head
///
/// - Uses getRootNode() to find the ShadowRoot that contains the element
/// - If element is inside a ShadowRoot, injects into that ShadowRoot
/// - Otherwise, injects into document.head
/// - Uses CSS hash as ID to prevent duplicate injection
///
/// Usage:
///   use_style(css, element)  // element can be any element inside a ShadowRoot
pub fn use_style(css : String, root : @js_dom.Element) -> Unit {
  let style_id = "style-\{hash_css(css)}"
  ffi_use_style(css, style_id, root.as_any())
}

///|
/// FFI: Inject style into Shadow DOM or document.head
/// Waits for element to be connected to DOM before injection.
/// Uses exponential backoff for retries (16ms, 32ms, 64ms, 128ms, 256ms).
/// Only injects into ShadowRoot if element is inside one; otherwise uses document.head.
extern "js" fn ffi_use_style(css : String, style_id : String, root : @js.Any) =
  #|(css, id, el) => {
  #|  const inject = () => {
  #|    const rootNode = el.getRootNode();
  #|    const isShadow = rootNode instanceof ShadowRoot;
  #|    const target = isShadow ? rootNode : document.head;
  #|    if (!target.querySelector('#' + id)) {
  #|      const style = document.createElement('style');
  #|      style.id = id;
  #|      style.textContent = css;
  #|      if (isShadow) target.prepend(style);
  #|      else target.appendChild(style);
  #|    }
  #|  };
  #|  const tryInject = (delay, maxDelay) => {
  #|    if (el.isConnected) {
  #|      inject();
  #|    } else if (delay <= maxDelay) {
  #|      // Exponential backoff: 16ms, 32ms, 64ms, 128ms, 256ms (total ~500ms)
  #|      setTimeout(() => tryInject(delay * 2, maxDelay), delay);
  #|    }
  #|    // If still not connected after max delay, assume SSR style exists
  #|  };
  #|  // Start with requestAnimationFrame, then exponential backoff
  #|  requestAnimationFrame(() => tryInject(16, 256));
  #|}

///|
/// Simple hash function for CSS string (for dedup ID)
fn hash_css(css : String) -> String {
  let mut hash : UInt = 5381
  for c in css {
    hash = (hash << 5) + hash + c.to_uint()
  }
  hash.to_string()
}
