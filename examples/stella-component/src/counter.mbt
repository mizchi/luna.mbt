// Stella Component Example: Counter
// A standalone Web Component built with MoonBit

// =============================================================================
// Template - Initial HTML (used when no SSR content exists)
// =============================================================================

pub fn template(props : @js.Any) -> String {
  let initial = props_get_int(props, "initial")
  let label = props_get_string(props, "label")

  let sb = StringBuilder::new()
  sb.write_string("<div class=\"counter\">")
  sb.write_string("<span class=\"label\">")
  sb.write_string(label)
  sb.write_string(":</span>")
  sb.write_string("<button class=\"dec\" aria-label=\"Decrement\">−</button>")
  sb.write_string("<span class=\"value\" aria-live=\"polite\">")
  sb.write_string(initial.to_string())
  sb.write_string("</span>")
  sb.write_string("<button class=\"inc\" aria-label=\"Increment\">+</button>")
  sb.write_string("</div>")
  sb.to_string()
}

// =============================================================================
// Setup - Reactivity and Event Handling
// =============================================================================

pub fn setup(ctx : @js.Any) -> @js.Any {
  // Get prop signals
  let initial_signal = ctx_get_prop(ctx, "initial")
  let label_signal = ctx_get_prop(ctx, "label")
  let disabled_signal = ctx_get_prop(ctx, "disabled")

  // Internal count state (starts at initial value)
  let count = Ref::new(signal_get_int(initial_signal))

  // Sync with external initial changes
  let unsub_initial = signal_subscribe(initial_signal, fn() {
    count.val = signal_get_int(initial_signal)
    update_dom(ctx, ".value", count.val.to_string())
  })

  // Bind label
  let unbind_label = ctx_bind(ctx, ".label", fn() {
    signal_get_string(label_signal) + ":"
  })

  // Bind disabled attribute
  let unbind_dec_disabled = ctx_bind_attr(ctx, ".dec", "disabled", disabled_signal)
  let unbind_inc_disabled = ctx_bind_attr(ctx, ".inc", "disabled", disabled_signal)

  // Decrement handler
  let unbind_dec = ctx_on(ctx, ".dec", "click", fn() {
    count.val = count.val - 1
    update_dom(ctx, ".value", count.val.to_string())
    dispatch_event(ctx, "change", count.val)
  })

  // Increment handler
  let unbind_inc = ctx_on(ctx, ".inc", "click", fn() {
    count.val = count.val + 1
    update_dom(ctx, ".value", count.val.to_string())
    dispatch_event(ctx, "change", count.val)
  })

  // Return cleanup function
  make_cleanup(fn() {
    unsub_initial()
    unbind_label()
    unbind_dec_disabled()
    unbind_inc_disabled()
    unbind_dec()
    unbind_inc()
  })
}

// =============================================================================
// Mutable Reference Helper
// =============================================================================

struct Ref[T] {
  mut val : T
}

fn Ref::new[T](val : T) -> Ref[T] {
  { val, }
}

// =============================================================================
// FFI Functions
// =============================================================================

extern "js" fn props_get_int(props : @js.Any, name : String) -> Int =
  #| (props, name) => props[name] ?? 0

extern "js" fn props_get_string(props : @js.Any, name : String) -> String =
  #| (props, name) => props[name] ?? ''

extern "js" fn ctx_get_prop(ctx : @js.Any, name : String) -> @js.Any =
  #| (ctx, name) => ctx.props[name]

extern "js" fn signal_get_int(signal : @js.Any) -> Int =
  #| (s) => s.get()

extern "js" fn signal_get_string(signal : @js.Any) -> String =
  #| (s) => s.get()

extern "js" fn signal_subscribe(
  signal : @js.Any,
  callback : () -> Unit,
) -> () -> Unit =
  #| (s, cb) => s.subscribe(cb)

extern "js" fn ctx_bind(
  ctx : @js.Any,
  selector : String,
  getter : () -> String,
) -> () -> Unit =
  #| (ctx, selector, getter) => ctx.bind(selector, getter)

extern "js" fn ctx_bind_attr(
  ctx : @js.Any,
  selector : String,
  attr : String,
  signal : @js.Any,
) -> () -> Unit =
  #| (ctx, selector, attr, signal) => ctx.bindAttr(selector, attr, signal)

extern "js" fn ctx_on(
  ctx : @js.Any,
  selector : String,
  event : String,
  handler : () -> Unit,
) -> () -> Unit =
  #| (ctx, selector, event, handler) => ctx.on(selector, event, handler)

extern "js" fn update_dom(ctx : @js.Any, selector : String, value : String) -> Unit =
  #| (ctx, selector, value) => {
  #|   const el = ctx.shadow.querySelector(selector);
  #|   if (el) el.textContent = value;
  #| }

extern "js" fn dispatch_event(ctx : @js.Any, name : String, value : Int) -> Unit =
  #| (ctx, name, value) => {
  #|   ctx.element.dispatchEvent(new CustomEvent(name, { detail: { value }, bubbles: true }));
  #| }

extern "js" fn make_cleanup(cleanup : () -> Unit) -> @js.Any =
  #| (cleanup) => cleanup
