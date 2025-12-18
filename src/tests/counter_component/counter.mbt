///| Counter Component - Shared component for SSR and hydration testing

///|

///| This component is used to verify idempotent hydration:

///| SSR output should match the DOM after hydration.

///| Uses Signal for reactive state management.

///|
/// Render counter component to VNode
/// Takes a signal for reactive updates and callbacks for event handlers
/// For SSR: pass noop handlers (event_handler())
/// For client: pass actual callbacks that update the signal
pub fn render_counter(
  count_sig : @signal.Signal[Int],
  on_inc : @luna.EventHandler[Unit],
  on_dec : @luna.EventHandler[Unit],
) -> @luna.Node[Unit] {
  @luna.h(
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
}

///|
/// Render counter to HTML string (for SSR)
/// Uses static signal value and noop handlers
/// Uses render_to_string_with_hydration to add data-hk markers for client hydration
pub fn render_counter_html(count : Int) -> String {
  let sig = @signal.signal(count)
  let noop = @luna.event_handler()
  let vnode = render_counter(sig, noop, noop)
  @render.render_to_string_with_hydration(vnode)
}

///|
/// Serialize state to JSON string
pub fn serialize_state(count : Int) -> String {
  "{\"count\":" + count.to_string() + "}"
}
