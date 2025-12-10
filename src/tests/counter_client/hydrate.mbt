///| Counter Client - Client-side hydration using @dom.hydrate
///|
///| This module provides the hydrate function that connects SSR'd HTML
///| to the reactive counter component using the @dom.hydrate runtime.

// FFI for JSON parsing
extern "js" fn js_getCount(state : @core.Any) -> Int =
  #|(s) => (s && typeof s.count === 'number') ? s.count : 0

// FFI to set data-hydrated attribute
extern "js" fn js_setAttribute(el : @js_dom.Element, name : String, value : String) -> Unit =
  #|(el, n, v) => { el.setAttribute(n, v); }

///|
/// Hydrate a counter element
/// Called by kg-loader with: hydrate(element, state)
/// Uses @dom.hydrate to connect the VNode to existing DOM
pub fn hydrate(el : @js_dom.Element, state : @core.Any) -> Unit {
  // Parse initial count from state
  let initial_count = js_getCount(state)

  // Create reactive signal
  let count_sig = @signal.signal(initial_count)

  // Create event handlers that update the signal
  let on_inc = @kaguya.handler_from_callback(fn() { count_sig.update(fn(c) { c + 1 }) })
  let on_dec = @kaguya.handler_from_callback(fn() { count_sig.update(fn(c) { c - 1 }) })

  // Render the component with the same function used for SSR
  let vnode = @counter_component.render_counter(count_sig, on_inc, on_dec)

  // Hydrate: connect VNode to existing DOM
  let _ = @dom.hydrate(el, vnode)

  // Mark as hydrated
  js_setAttribute(el, "data-hydrated", "true")
}
