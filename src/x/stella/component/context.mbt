// Web Component Context API
// Context received by setup function on MoonBit side

/// Each Props field is passed as a Signal
///
/// Example: Props = { initial: Int, label: String }
/// → ctx.props.initial is treated as Signal[Int]
///
/// Since they are Signal-ized on JS side, MoonBit side
/// receives them as @js.Any and operates via FFI

/// Context passed to setup function
///
/// Example usage:
/// ```moonbit
/// pub fn setup(ctx : @js.Any) -> Unit {
///   // Get props (already Signal)
///   let initial = ctx.get_prop_signal_int("initial")
///   let label = ctx.get_prop_signal_string("label")
///
///   // Internal state
///   let count = @resource.signal(initial.get())
///
///   // Bind DOM
///   ctx.bind(".value", fn() { count.get().to_string() })
///   ctx.on(".inc", "click", fn() { count.update(fn(n) { n + 1 }) })
/// }
/// ```

// =============================================================================
// FFI: Context Access
// =============================================================================

///|
/// Get element from context
pub extern "js" fn ctx_get_element(ctx : @js.Any) -> @js.Any =
  #| (ctx) => ctx.element

///|
/// Get shadow root from context
pub extern "js" fn ctx_get_shadow(ctx : @js.Any) -> @js.Any =
  #| (ctx) => ctx.shadow

///|
/// Get props object from context
pub extern "js" fn ctx_get_props(ctx : @js.Any) -> @js.Any =
  #| (ctx) => ctx.props

// =============================================================================
// FFI: Signal Operations (for JS Signal)
// =============================================================================

///|
/// Get signal value (int)
pub extern "js" fn js_signal_get_int(signal : @js.Any) -> Int =
  #| (s) => s.get()

///|
/// Get signal value (string)
pub extern "js" fn js_signal_get_string(signal : @js.Any) -> String =
  #| (s) => s.get()

///|
/// Get signal value (bool)
pub extern "js" fn js_signal_get_bool(signal : @js.Any) -> Bool =
  #| (s) => s.get()

///|
/// Set signal value (int)
pub extern "js" fn js_signal_set_int(signal : @js.Any, value : Int) -> Unit =
  #| (s, v) => s.set(v)

///|
/// Set signal value (string)
pub extern "js" fn js_signal_set_string(
  signal : @js.Any,
  value : String,
) -> Unit =
  #| (s, v) => s.set(v)

///|
/// Set signal value (bool)
pub extern "js" fn js_signal_set_bool(signal : @js.Any, value : Bool) -> Unit =
  #| (s, v) => s.set(v)

///|
/// Subscribe to signal changes
pub extern "js" fn js_signal_subscribe(
  signal : @js.Any,
  callback : () -> Unit,
) -> () -> Unit =
  #| (s, cb) => s.subscribe(cb)

// =============================================================================
// FFI: DOM Binding
// =============================================================================

///|
/// Bind text content to a getter function (with auto-tracking)
pub extern "js" fn ctx_bind(
  ctx : @js.Any,
  selector : String,
  getter : () -> String,
) -> () -> Unit =
  #| (ctx, selector, getter) => ctx.bind(selector, getter)

///|
/// Bind attribute to a signal
pub extern "js" fn ctx_bind_attr(
  ctx : @js.Any,
  selector : String,
  attr : String,
  signal : @js.Any,
) -> () -> Unit =
  #| (ctx, selector, attr, signal) => ctx.bindAttr(selector, attr, signal)

///|
/// Add event listener
pub extern "js" fn ctx_on(
  ctx : @js.Any,
  selector : String,
  event : String,
  handler : () -> Unit,
) -> () -> Unit =
  #| (ctx, selector, event, handler) => ctx.on(selector, event, () => handler())

///|
/// Register cleanup function
pub extern "js" fn ctx_on_cleanup(ctx : @js.Any, cleanup : () -> Unit) -> Unit =
  #| (ctx, cleanup) => ctx.onCleanup(cleanup)

// =============================================================================
// FFI: Props Access Helpers
// =============================================================================

///|
/// Get prop signal by name (for int)
pub extern "js" fn ctx_prop_int(ctx : @js.Any, name : String) -> @js.Any =
  #| (ctx, name) => ctx.props[name]

///|
/// Get prop signal by name (for string)
pub extern "js" fn ctx_prop_string(ctx : @js.Any, name : String) -> @js.Any =
  #| (ctx, name) => ctx.props[name]

///|
/// Get prop signal by name (for bool)
pub extern "js" fn ctx_prop_bool(ctx : @js.Any, name : String) -> @js.Any =
  #| (ctx, name) => ctx.props[name]

// =============================================================================
// High-Level Wrapper
// =============================================================================

///|
/// Wrapper for Web Component context
pub struct WcContext {
  raw : @js.Any
}

///|
/// Create context wrapper from raw JS object
pub fn WcContext::from_js(raw : @js.Any) -> WcContext {
  { raw, }
}

///|
/// Get element
pub fn WcContext::element(self : WcContext) -> @js.Any {
  ctx_get_element(self.raw)
}

///|
/// Get shadow root
pub fn WcContext::shadow(self : WcContext) -> @js.Any {
  ctx_get_shadow(self.raw)
}

///|
/// Get int prop signal
pub fn WcContext::prop_int(self : WcContext, name : String) -> JsSignalInt {
  JsSignalInt::new(ctx_prop_int(self.raw, name))
}

///|
/// Get string prop signal
pub fn WcContext::prop_string(
  self : WcContext,
  name : String,
) -> JsSignalString {
  JsSignalString::new(ctx_prop_string(self.raw, name))
}

///|
/// Get bool prop signal
pub fn WcContext::prop_bool(self : WcContext, name : String) -> JsSignalBool {
  JsSignalBool::new(ctx_prop_bool(self.raw, name))
}

///|
/// Bind text content
pub fn WcContext::bind(
  self : WcContext,
  selector : String,
  getter : () -> String,
) -> () -> Unit {
  ctx_bind(self.raw, selector, getter)
}

///|
/// Bind attribute
pub fn WcContext::bind_attr(
  self : WcContext,
  selector : String,
  attr : String,
  signal : @js.Any,
) -> () -> Unit {
  ctx_bind_attr(self.raw, selector, attr, signal)
}

///|
/// Add event listener
pub fn WcContext::on(
  self : WcContext,
  selector : String,
  event : String,
  handler : () -> Unit,
) -> () -> Unit {
  ctx_on(self.raw, selector, event, handler)
}

///|
/// Register cleanup
pub fn WcContext::on_cleanup(self : WcContext, cleanup : () -> Unit) -> Unit {
  ctx_on_cleanup(self.raw, cleanup)
}

// =============================================================================
// JS Signal Wrappers
// =============================================================================

///|
/// Wrapper for JS Signal[Int]
pub struct JsSignalInt {
  raw : @js.Any
}

///|
pub fn JsSignalInt::new(raw : @js.Any) -> JsSignalInt {
  { raw, }
}

///|
pub fn JsSignalInt::get(self : JsSignalInt) -> Int {
  js_signal_get_int(self.raw)
}

///|
pub fn JsSignalInt::set(self : JsSignalInt, value : Int) -> Unit {
  js_signal_set_int(self.raw, value)
}

///|
pub fn JsSignalInt::update(self : JsSignalInt, f : (Int) -> Int) -> Unit {
  self.set(f(self.get()))
}

///|
pub fn JsSignalInt::subscribe(
  self : JsSignalInt,
  callback : () -> Unit,
) -> () -> Unit {
  js_signal_subscribe(self.raw, callback)
}

///|
pub fn JsSignalInt::raw(self : JsSignalInt) -> @js.Any {
  self.raw
}

///|
/// Wrapper for JS Signal[String]
pub struct JsSignalString {
  raw : @js.Any
}

///|
pub fn JsSignalString::new(raw : @js.Any) -> JsSignalString {
  { raw, }
}

///|
pub fn JsSignalString::get(self : JsSignalString) -> String {
  js_signal_get_string(self.raw)
}

///|
pub fn JsSignalString::set(self : JsSignalString, value : String) -> Unit {
  js_signal_set_string(self.raw, value)
}

///|
pub fn JsSignalString::subscribe(
  self : JsSignalString,
  callback : () -> Unit,
) -> () -> Unit {
  js_signal_subscribe(self.raw, callback)
}

///|
pub fn JsSignalString::raw(self : JsSignalString) -> @js.Any {
  self.raw
}

///|
/// Wrapper for JS Signal[Bool]
pub struct JsSignalBool {
  raw : @js.Any
}

///|
pub fn JsSignalBool::new(raw : @js.Any) -> JsSignalBool {
  { raw, }
}

///|
pub fn JsSignalBool::get(self : JsSignalBool) -> Bool {
  js_signal_get_bool(self.raw)
}

///|
pub fn JsSignalBool::set(self : JsSignalBool, value : Bool) -> Unit {
  js_signal_set_bool(self.raw, value)
}

///|
pub fn JsSignalBool::subscribe(
  self : JsSignalBool,
  callback : () -> Unit,
) -> () -> Unit {
  js_signal_subscribe(self.raw, callback)
}

///|
pub fn JsSignalBool::raw(self : JsSignalBool) -> @js.Any {
  self.raw
}
