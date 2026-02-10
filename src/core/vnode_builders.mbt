///|
/// Create an event handler from a callback.
/// ```mbt check
/// test {
///   let h : EventHandler[Int] = handler(fn(x) { let _ = x * 2 })
///   inspect(h.get_callback()(5), content="()")
/// }
/// ```
pub fn[E] handler(f : (E) -> Unit) -> EventHandler[E] {
  { callback: f }
}

///|
/// Get the callback function
pub fn[E] EventHandler::get_callback(self : EventHandler[E]) -> (E) -> Unit {
  self.callback
}

///|
/// Create a VNode element.
/// The main building block for creating virtual DOM elements.
/// ```mbt check
/// test {
///   let node : Node[Unit, String] = h(
///     "div",
///     [("class", attr_static("container"))],
///     [text("Hello")],
///   )
///   guard node is Element(el) else { fail("expected Element") }
///   inspect(el.tag, content="div")
/// }
/// ```
pub fn[E, A] h(
  tag : String,
  attrs : Array[(String, Attr[E, A])],
  children : Array[Node[E, A]],
) -> Node[E, A] {
  Element({ tag, attrs, children })
}

///|
/// Create a text VNode.
/// ```mbt check
/// test {
///   let node : Node[Unit, String] = text("Hello World")
///   guard node is Text(s) else { fail("expected Text") }
///   inspect(s, content="Hello World")
/// }
/// ```
pub fn[E, A] text(content : String) -> Node[E, A] {
  Text(content)
}

///|
/// Create a dynamic text VNode.
/// The content is computed lazily on each render.
/// ```mbt check
/// test {
///   let mut count = 5
///   let node : Node[Unit, String] = text_dyn(fn() { count.to_string() })
///   guard node is DynamicText(getter) else { fail("expected DynamicText") }
///   inspect(getter(), content="5")
///   count = 10
///   inspect(getter(), content="10")
/// }
/// ```
pub fn[E, A] text_dyn(content : () -> String) -> Node[E, A] {
  DynamicText(content)
}

///|
/// Create a fragment VNode.
/// Groups multiple nodes without a wrapper element.
/// ```mbt check
/// test {
///   let node : Node[Unit, String] = fragment([
///     text("Hello"),
///     text(" "),
///     text("World"),
///   ])
///   guard node is Fragment(children) else { fail("expected Fragment") }
///   inspect(children.length(), content="3")
/// }
/// ```
pub fn[E, A] fragment(children : Array[Node[E, A]]) -> Node[E, A] {
  Fragment(children)
}

///|
/// Create a raw HTML VNode (content is not escaped).
/// Use with caution: content should be trusted or sanitized.
/// ```mbt check
/// test {
///   let node : Node[Unit, String] = raw_html("<strong>Bold</strong>")
///   guard node is RawHtml(html) else { fail("expected RawHtml") }
///   inspect(html, content="<strong>Bold</strong>")
/// }
/// ```
pub fn[E, A] raw_html(content : String) -> Node[E, A] {
  RawHtml(content)
}

///|
/// Create a conditional VNode.
/// Only renders the child when the condition is true.
/// ```mbt check
/// test {
///   let visible = true
///   let node : Node[Unit, String] = show(fn() { visible }, fn() {
///     text("Visible!")
///   })
///   guard node is Show(condition~, ..) else { fail("expected Show") }
///   inspect(condition(), content="true")
/// }
/// ```
pub fn[E, A] show(when : () -> Bool, child : () -> Node[E, A]) -> Node[E, A] {
  Show(condition=when, child~)
}

///|
/// Create a list VNode.
/// Renders a dynamic list of nodes.
/// ```mbt check
/// test {
///   let items = ["a", "b", "c"]
///   let node : Node[Unit, String] = for_each(fn() { items.map(fn(s) { text(s) }) })
///   guard node is For(render~) else { fail("expected For") }
///   inspect(render().length(), content="3")
/// }
/// ```
pub fn[E, A] for_each(items : () -> Array[Node[E, A]]) -> Node[E, A] {
  For(render=items)
}

///|
/// Create a component VNode.
/// Wraps a render function as a component boundary.
/// ```mbt check
/// test {
///   let node : Node[Unit, String] = component(fn() {
///     h("div", [], [text("Component")])
///   })
///   guard node is Component(render~) else { fail("expected Component") }
///   guard render() is Element(el) else { fail("expected Element") }
///   inspect(el.tag, content="div")
/// }
/// ```
pub fn[E, A] component(render : () -> Node[E, A]) -> Node[E, A] {
  Component(render~)
}

///|
/// Create an island VNode for partial hydration
pub fn[E, A] island(
  id : String,
  url : String,
  state : String,
  children : Array[Node[E, A]],
  trigger? : TriggerType = Load,
) -> Node[E, A] {
  Island({ id, url, state, trigger, children })
}

///|
/// Create a Web Components island VNode for partial hydration
/// Uses Declarative Shadow DOM for SSR
pub fn[E, A] wc_island(
  name : String,
  url : String,
  styles : String,
  state : String,
  children : Array[Node[E, A]],
  trigger? : TriggerType = Load,
) -> Node[E, A] {
  WcIsland({ name, url, styles, state, trigger, children })
}

///|
/// Create an async VNode with fallback
/// - render: async function that produces the content (may raise errors)
/// - fallback: shown while loading or on error (if no on_error handler)
/// - on_error: optional custom error UI handler
pub fn[E, A] async_(
  render~ : async () -> Node[E, A],
  fallback~ : () -> Node[E, A],
  on_error? : ((Error) -> Node[E, A])? = None,
) -> Node[E, A] {
  Async({ render, fallback, on_error })
}

///|
/// Create an error boundary VNode
/// Catches errors during child rendering and displays fallback UI
/// - children: lazy function that produces child content (may throw)
/// - fallback: function receiving (error, reset) that produces fallback UI
///   - error: the caught Error
///   - reset: function to retry rendering children
///
/// Example:
/// ```
/// error_boundary(
///   children=fn() { risky_component() },
///   fallback=fn(err, reset) {
///     h("div", [], [
///       text("Error: " + err.to_string()),
///       h("button", [("onclick", handler(fn(_) { reset() }))], [text("Retry")])
///     ])
///   }
/// )
/// ```
pub fn[E, A] error_boundary(
  children~ : () -> Node[E, A] raise,
  fallback~ : (Error, () -> Unit) -> Node[E, A] raise,
) -> Node[E, A] {
  ErrorBoundary({ children, fallback })
}

///|
/// Create a match case for Switch
/// - when: condition function, evaluated lazily
/// - render: content to render when condition is true
pub fn[E, A] match_case(
  when~ : () -> Bool,
  render~ : () -> Node[E, A],
) -> MatchCase[E, A] {
  { when, render }
}

///|
/// Create a switch VNode - renders first matching case
/// Similar to Solid.js <Switch>/<Match>
///
/// Example:
/// ```
/// switch_(
///   cases=[
///     match_case(when=fn() { state.get() == 1 }, render=fn() { text("One") }),
///     match_case(when=fn() { state.get() == 2 }, render=fn() { text("Two") }),
///   ],
///   fallback=Some(fn() { text("Other") })
/// )
/// ```
pub fn[E, A] switch_(
  cases~ : Array[MatchCase[E, A]],
  fallback? : (() -> Node[E, A])? = None,
) -> Node[E, A] {
  Switch({ cases, fallback })
}

///|
/// Create an internal reference VNode (for server_dom.island())
pub fn[E, A] internal_ref(
  url : String,
  state : String,
  trigger? : TriggerType = Load,
  wc? : Bool = false,
  styles? : String = "",
  children? : Array[Node[E, A]] = [],
) -> Node[E, A] {
  InternalRef({ url, state, trigger, wc, styles, children })
}

// =============================================================================
// ComponentRef - Opaque type for Island component references
// =============================================================================

///|
/// Create a ComponentRef for a regular Island component
pub fn[T] component_ref(
  url : String,
  props : T,
  trigger? : TriggerType = Load,
) -> ComponentRef[T] {
  { url, props, wc: false, trigger }
}

///|
/// Create a ComponentRef for a Web Components Island
pub fn[T] wc_component_ref(
  url : String,
  props : T,
  trigger? : TriggerType = Load,
) -> ComponentRef[T] {
  { url, props, wc: true, trigger }
}

// =============================================================================
// SSR convenience functions (E = Unit)
// =============================================================================

///|
/// Create a placeholder event handler for SSR (noop)
pub fn event_handler() -> EventHandler[Unit] {
  handler(fn(_) { () })
}

///|
/// Create an event handler from a simple callback (ignores event, for SSR compatibility)
pub fn handler_from_callback(f : () -> Unit) -> EventHandler[Unit] {
  handler(fn(_) { f() })
}
