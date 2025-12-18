///| Counter Client - Client-side hydration using @dom.hydrate

///|

///| This module provides the hydrate function that connects SSR'd HTML

///|
/// to the reactive counter component using the @dom.hydrate runtime.

// FFI for JSON parsing
extern "js" fn js_getCount(state : @js.Any) -> Int =
  #|(s) => (s && typeof s.count === 'number') ? s.count : 0

// FFI to set data-hydrated attribute

///|
extern "js" fn js_setAttribute(
  el : @js_dom.Element,
  name : String,
  value : String,
) -> Unit =
  #|(el, n, v) => { el.setAttribute(n, v); }

///|
/// Hydrate a counter element
/// Called by ln-loader with: hydrate(element, state)
/// Uses @dom.hydrate to connect the VNode to existing DOM
pub fn hydrate(el : @js_dom.Element, state : @js.Any) -> Unit {
  // Parse initial count from state
  let initial_count = js_getCount(state)

  // Create reactive signal
  let count_sig = @signal.signal(initial_count)

  // Create browser event handlers that update the signal
  let on_inc = @luna.handler(fn(_event : @js.Any) {
    count_sig.update(fn(c) { c + 1 })
  })
  let on_dec = @luna.handler(fn(_event : @js.Any) {
    count_sig.update(fn(c) { c - 1 })
  })

  // Build counter VNode for browser (with @js.Any event type)
  let vnode : @luna.Node[@js.Any] = @luna.h(
    "div",
    [
      ("class", @luna.attr_static("counter")),
      ("data-count", @luna.attr_dynamic(fn() { count_sig.get().to_string() })),
    ],
    [
      @luna.h("span", [("data-count", @luna.attr_static("true"))], [
        @luna.text_dyn(fn() { count_sig.get().to_string() }),
      ]),
      @luna.h(
        "button",
        [
          ("data-inc", @luna.attr_static("true")),
          ("onClick", @luna.attr_handler(on_inc)),
        ],
        [@luna.text("+1")],
      ),
      @luna.h(
        "button",
        [
          ("data-dec", @luna.attr_static("true")),
          ("onClick", @luna.attr_handler(on_dec)),
        ],
        [@luna.text("-1")],
      ),
    ],
  )

  // Hydrate: connect VNode to existing DOM
  let _ = @client.hydrate(el, vnode)

  // Mark as hydrated
  js_setAttribute(el, "data-hydrated", "true")
}
