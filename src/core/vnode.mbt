///| VNode - DOM-independent virtual node representation

///|

///| Type parameter E represents the event type for handlers:

///| - Browser: E = DomEvent (or specific event types)

///| - SSR: E = Unit (no events)

///| - Other platforms: custom event types

///|
/// Event handler type - newtype wrapper for callback function
pub struct EventHandler[E] {
  callback : (E) -> Unit
}

///|
/// Create an event handler from a callback
pub fn[E] handler(f : (E) -> Unit) -> EventHandler[E] {
  { callback: f }
}

///|
/// Get the callback function
pub fn[E] EventHandler::get_callback(self : EventHandler[E]) -> (E) -> Unit {
  self.callback
}

///|
/// Attribute value that can be static or dynamic (signal-based)
pub enum Attr[E] {
  VStatic(String)
  VDynamic(() -> String)
  VHandler(EventHandler[E])
  VAction(String) // Action name for declarative event handling
}

///|
/// Island hydration trigger types
pub(all) enum IslandTrigger {
  Load // Hydrate immediately on page load
  Idle // Hydrate during browser idle time
  Visible // Hydrate when element becomes visible
  Media(String) // Hydrate when media query matches
}

///|
/// Virtual Island node - serializable hydration unit
pub struct VIsland[E] {
  id : String // Unique identifier (ln:id)
  url : String // Script URL for loading implementation (ln:url)
  state : String // Serialized state JSON (ln:state)
  trigger : IslandTrigger // Hydration trigger (ln:trigger)
  children : Array[Node[E]] // SSR-rendered content (can contain nested Islands)
}

///|
/// Virtual DOM node types
pub enum Node[E] {
  Element(VElement[E])
  Text(String)
  DynamicText(() -> String)
  Fragment(Array[Node[E]])
  Show(condition~ : () -> Bool, child~ : () -> Node[E])
  For(render~ : () -> Array[Node[E]])
  Component(render~ : () -> Node[E])
  Island(VIsland[E]) // Hydration boundary for partial hydration
  /// Async node - renders content asynchronously with fallback
  /// - render: async function that may raise errors
  /// - fallback: shown while loading or on error
  /// - on_error: optional error handler for custom error UI
  Async(VAsync[E])
  /// ErrorBoundary node - catches rendering errors in children
  /// - children: lazy child content (may throw)
  /// - fallback: (error, reset) -> fallback UI
  ErrorBoundary(VErrorBoundary[E])
  /// Switch node - renders first matching case or fallback
  /// Similar to Solid.js <Switch>/<Match>
  Switch(VSwitch[E])
}

///|
/// Virtual Async node for async rendering with error handling
/// Note: async functions implicitly raise Error, no need for raise? annotation
pub struct VAsync[E] {
  render : async () -> Node[E]
  fallback : () -> Node[E]
  on_error : ((Error) -> Node[E])?
}

///|
/// Virtual ErrorBoundary node for catching rendering errors
/// Similar to Solid.js ErrorBoundary - catches errors during:
/// - Child component rendering
/// - Effects and memos within children
/// Does NOT catch:
/// - Event handler errors
/// - Async errors outside render cycle
pub struct VErrorBoundary[E] {
  children : () -> Node[E] raise
  fallback : (Error, () -> Unit) -> Node[E] raise // (error, reset) -> fallbackUI
}

///|
/// Match case for Switch - pairs a condition with content
pub struct MatchCase[E] {
  when : () -> Bool
  render : () -> Node[E]
}

///|
/// Virtual Switch node - renders first matching case
/// Similar to Solid.js <Switch>/<Match>
/// - cases: array of condition-content pairs, evaluated in order
/// - fallback: optional content when no case matches
pub struct VSwitch[E] {
  cases : Array[MatchCase[E]]
  fallback : (() -> Node[E])?
}

///|
/// Virtual element node
pub struct VElement[E] {
  tag : String
  attrs : Array[(String, Attr[E])]
  children : Array[Node[E]]
}

///|
/// Create a VNode element
pub fn[E] h(
  tag : String,
  attrs : Array[(String, Attr[E])],
  children : Array[Node[E]],
) -> Node[E] {
  Element({ tag, attrs, children })
}

///|
/// Create a text VNode
pub fn[E] vtext(content : String) -> Node[E] {
  Text(content)
}

///|
/// Create a dynamic text VNode
pub fn[E] text_dyn(content : () -> String) -> Node[E] {
  DynamicText(content)
}

///|
/// Create a text VNode from a signal
pub fn[E, T : Show] vtext_sig(sig : @signal.Signal[T]) -> Node[E] {
  DynamicText(fn() { sig.get().to_string() })
}

///|
/// Create a fragment VNode
pub fn[E] vfragment(children : Array[Node[E]]) -> Node[E] {
  Fragment(children)
}

///|
/// Create a conditional VNode
pub fn[E] vshow(when : () -> Bool, child : () -> Node[E]) -> Node[E] {
  Show(condition=when, child~)
}

///|
/// Create a list VNode
pub fn[E] vfor(items : () -> Array[Node[E]]) -> Node[E] {
  For(render=items)
}

///|
/// Create a component VNode
pub fn[E] vcomponent(render : () -> Node[E]) -> Node[E] {
  Component(render~)
}

///|
/// Create an island VNode for partial hydration
pub fn[E] visland(
  id : String,
  url : String,
  state : String,
  children : Array[Node[E]],
  trigger? : IslandTrigger = Load,
) -> Node[E] {
  Island({ id, url, state, trigger, children })
}

///|
/// Create an async VNode with fallback
/// - render: async function that produces the content (may raise errors)
/// - fallback: shown while loading or on error (if no on_error handler)
/// - on_error: optional custom error UI handler
pub fn[E] vasync(
  render~ : async () -> Node[E],
  fallback~ : () -> Node[E],
  on_error? : ((Error) -> Node[E])? = None,
) -> Node[E] {
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
///       vtext("Error: " + err.to_string()),
///       h("button", [("onclick", handler(fn(_) { reset() }))], [vtext("Retry")])
///     ])
///   }
/// )
/// ```
pub fn[E] error_boundary(
  children~ : () -> Node[E] raise,
  fallback~ : (Error, () -> Unit) -> Node[E] raise,
) -> Node[E] {
  ErrorBoundary({ children, fallback })
}

///|
/// Create a match case for Switch
/// - when: condition function, evaluated lazily
/// - render: content to render when condition is true
pub fn[E] match_case(
  when~ : () -> Bool,
  render~ : () -> Node[E],
) -> MatchCase[E] {
  { when, render }
}

///|
/// Create a switch VNode - renders first matching case
/// Similar to Solid.js <Switch>/<Match>
///
/// Example:
/// ```
/// vswitch(
///   cases=[
///     match_case(when=fn() { state.get() == 1 }, render=fn() { vtext("One") }),
///     match_case(when=fn() { state.get() == 2 }, render=fn() { vtext("Two") }),
///   ],
///   fallback=Some(fn() { vtext("Other") })
/// )
/// ```
pub fn[E] vswitch(
  cases~ : Array[MatchCase[E]],
  fallback? : (() -> Node[E])? = None,
) -> Node[E] {
  Switch({ cases, fallback })
}

///|
/// Convert IslandTrigger to string for ln:trigger attribute
pub fn trigger_to_string(trigger : IslandTrigger) -> String {
  match trigger {
    Load => "load"
    Idle => "idle"
    Visible => "visible"
    Media(query) => "media:" + query
  }
}

///|
/// Check if element has dynamic content that needs hydration
pub fn[E] has_dynamic_content(attrs : Array[(String, Attr[E])]) -> Bool {
  for attr in attrs {
    let (_, value) = attr
    match value {
      VDynamic(_) | VHandler(_) | VAction(_) => return true
      _ => ()
    }
  }
  false
}

// Attr factory functions for external packages

///|
/// Create a static attribute value
pub fn[E] attr_static(value : String) -> Attr[E] {
  VStatic(value)
}

///|
/// Create a dynamic attribute value
pub fn[E] attr_dynamic(getter : () -> String) -> Attr[E] {
  VDynamic(getter)
}

///|
/// Create a handler attribute value
pub fn[E] attr_handler(handler : EventHandler[E]) -> Attr[E] {
  VHandler(handler)
}

///|
/// Create a style attribute value (string form, e.g. "color: red; margin: 10px")
pub fn[E] attr_style(style : String) -> Attr[E] {
  VStatic(style)
}

///|
/// Create a dynamic style attribute value
pub fn[E] attr_dynamic_style(getter : () -> String) -> Attr[E] {
  VDynamic(getter)
}

///|
/// Create an action attribute value - dispatches named action on event
/// Used for declarative event handling with enum types:
///   ("onclick", action(Increment))  // requires derive(Show)
///
/// Example:
/// ```
/// pub enum MyAction { Increment; Decrement } derive(Show)
/// @luna.h("button", [("onclick", action(Increment))], [...])
/// ```
pub fn[E, A : Show] action(a : A) -> Attr[E] {
  VAction(a.to_string())
}

// =============================================================================
// SSR convenience functions (E = Unit)
// =============================================================================

///|
/// Create a placeholder event handler for SSR (noop)
pub fn event_handler() -> EventHandler[Unit] {
  { callback: fn(_) { () } }
}

///|
/// Create an event handler from a simple callback (ignores event, for SSR compatibility)
pub fn handler_from_callback(f : () -> Unit) -> EventHandler[Unit] {
  { callback: fn(_) { f() } }
}
