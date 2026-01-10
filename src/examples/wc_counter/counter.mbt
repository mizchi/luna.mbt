// Web Component Example: Counter
//
// This file demonstrates how to implement a Web Component in MoonBit.
// It exports two functions:
//   - setup(ctx): Called when the component is connected, sets up reactivity
//   - template(props): Returns initial HTML (used when no SSR content exists)

// =============================================================================
// Props Type (matches the attributes defined in counter.wc.json)
// =============================================================================

// Props structure matching the WC config (for documentation)
// These are passed as Signals from the JS wrapper
// Fields: initial: Int, label: String, disabled: Bool

// =============================================================================
// Template Function
// =============================================================================

///|
/// Generate initial HTML template
/// Called when the element has no pre-rendered content (no SSR)
///
/// The props here are snapshot values (not Signals)
pub fn template(props_js : @js.Any) -> String {
  let initial = get_prop_int(props_js, "initial")
  let label = get_prop_string(props_js, "label")

  // Return HTML string
  // Note: Using simple string concatenation for clarity
  let html = StringBuilder::new()
  html.write_string("<div class=\"counter\">")
  html.write_string("<span class=\"label\">")
  html.write_string(label)
  html.write_string(":</span>")
  html.write_string("<button class=\"dec\">-</button>")
  html.write_string("<span class=\"value\">")
  html.write_string(initial.to_string())
  html.write_string("</span>")
  html.write_string("<button class=\"inc\">+</button>")
  html.write_string("</div>")
  html.to_string()
}

// =============================================================================
// Setup Function
// =============================================================================

///|
/// Setup reactivity and event handlers
/// Called after the component is connected to the DOM
///
/// ctx provides:
///   - ctx.props: Object with Signal properties (initial, label, disabled)
///   - ctx.bind(selector, getter): Bind text content to a reactive getter
///   - ctx.on(selector, event, handler): Add event listener
///   - ctx.bindAttr(selector, attr, signal): Bind attribute to a signal
///
/// Returns a cleanup function (optional)
pub fn setup(ctx_js : @js.Any) -> @js.Any {
  let ctx = @wc.WcContext::from_js(ctx_js)

  // Get prop signals
  let initial = ctx.prop_int("initial")
  let label = ctx.prop_string("label")
  let disabled = ctx.prop_bool("disabled")

  // Internal state: count starts at initial value
  // We use a simple mutable ref since MoonBit's Signal is separate from JS Signal
  let count = { val: initial.get() }

  // Sync with external initial changes
  let unsub_initial = initial.subscribe(fn() { count.val = initial.get() })

  // Bind value display
  // This uses auto-tracking: when count changes, the DOM updates
  let unbind_value = ctx.bind(".value", fn() { count.val.to_string() })

  // Bind label display
  let unbind_label = ctx.bind(".label", fn() { label.get() + ":" })

  // Bind disabled attribute to buttons
  let unbind_dec_disabled = ctx.bind_attr(".dec", "disabled", disabled.raw())
  let unbind_inc_disabled = ctx.bind_attr(".inc", "disabled", disabled.raw())

  // Event handlers
  let unbind_dec = ctx.on(".dec", "click", fn() {
    count.val = count.val - 1
    // Need to trigger re-render manually since count is not a JS Signal
    // This is a limitation of the current design
    trigger_update(ctx_js, ".value", count.val.to_string())
  })
  let unbind_inc = ctx.on(".inc", "click", fn() {
    count.val = count.val + 1
    trigger_update(ctx_js, ".value", count.val.to_string())
  })

  // Return cleanup function
  let cleanup : () -> Unit = fn() {
    unsub_initial()
    unbind_value()
    unbind_label()
    unbind_dec_disabled()
    unbind_inc_disabled()
    unbind_dec()
    unbind_inc()
  }
  wrap_cleanup(cleanup)
}

// =============================================================================
// FFI Helpers
// =============================================================================

///|
extern "js" fn get_prop_int(props : @js.Any, name : String) -> Int =
  #| (props, name) => props[name] ?? 0

///|
extern "js" fn get_prop_string(props : @js.Any, name : String) -> String =
  #| (props, name) => props[name] ?? ''

///|
extern "js" fn wrap_cleanup(cleanup : () -> Unit) -> @js.Any =
  #| (cleanup) => cleanup

///|
extern "js" fn trigger_update(
  ctx : @js.Any,
  selector : String,
  value : String,
) -> Unit =
  #| (ctx, selector, value) => {
  #|   const el = ctx.shadow.querySelector(selector);
  #|   if (el) el.textContent = value;
  #| }
