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

  // Create browser event handlers that update the signal
  let on_inc = @dom.browser_handler_from_callback(fn() { count_sig.update(fn(c) { c + 1 }) })
  let on_dec = @dom.browser_handler_from_callback(fn() { count_sig.update(fn(c) { c - 1 }) })

  // Build counter VNode for browser (with @core.Any event type)
  let vnode : @kaguya.Node[@core.Any] = @kaguya.h(
    "div",
    [
      ("class", @kaguya.attr_static("counter")),
      ("data-count", @kaguya.attr_dynamic(fn() { count_sig.get().to_string() })),
    ],
    [
      @kaguya.h("span", [("data-count", @kaguya.attr_static("true"))], [
        @kaguya.text_dyn(fn() { count_sig.get().to_string() }),
      ]),
      @kaguya.h(
        "button",
        [
          ("data-inc", @kaguya.attr_static("true")),
          ("onClick", @kaguya.attr_handler(on_inc)),
        ],
        [@kaguya.vtext("+1")],
      ),
      @kaguya.h(
        "button",
        [
          ("data-dec", @kaguya.attr_static("true")),
          ("onClick", @kaguya.attr_handler(on_dec)),
        ],
        [@kaguya.vtext("-1")],
      ),
    ],
  )

  // Hydrate: connect VNode to existing DOM
  let _ = @dom.hydrate(el, vnode)

  // Mark as hydrated
  js_setAttribute(el, "data-hydrated", "true")
}
