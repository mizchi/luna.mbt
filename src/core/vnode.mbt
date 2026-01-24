// VNode - DOM-independent virtual node representation
//
// Type parameter E represents the event type for handlers:
// - Browser: E = DomEvent (or specific event types)
// - SSR: E = Unit (no events)
// - Other platforms: custom event types
//

///|
/// Event handler type - newtype wrapper for callback function
pub struct EventHandler[E] {
  callback : (E) -> Unit
}

///|
/// Create an event handler from a callback.
/// ```mbt check
/// test {
///   let h : EventHandler[Int] = handler(fn(x) {
///     let _ = x * 2
///
///   })
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
/// Attribute value that can be static or dynamic (signal-based)
/// Type parameter A represents the attribute value type:
/// - Web: A = String (HTML attributes are strings)
/// - TUI: A = TuiAttrValue (typed values like Dimension, Color)
pub(all) enum Attr[E, A] {
  VStatic(A)
  VDynamic(() -> A)
  VHandler(EventHandler[E])
  VAction(String) // Action name for declarative event handling (kept as String for SSR)
}

///|
/// Hydration trigger types - when to hydrate a component
pub(all) enum TriggerType {
  /// Hydrate on page load (DOMContentLoaded)
  Load
  /// Hydrate when browser is idle (requestIdleCallback)
  Idle
  /// Hydrate when element enters viewport (IntersectionObserver)
  Visible
  /// Hydrate when media query matches
  Media(String)
  /// Never auto-hydrate (manual only via __LUNA_HYDRATE__)
  None
}

///|
/// Virtual Island node - serializable hydration unit
pub struct VIsland[E, A] {
  id : String // Unique identifier (luna:id)
  url : String // Script URL for loading implementation (luna:url)
  state : String // Serialized state JSON (luna:state)
  trigger : TriggerType // Hydration trigger (luna:client-trigger)
  children : Array[Node[E, A]] // SSR-rendered content (can contain nested Islands)
}

///|
/// Virtual Web Components Island node - Web Components based hydration unit
/// Uses Declarative Shadow DOM for SSR and DOM Parts for partial updates
pub struct VWcIsland[E, A] {
  name : String // Custom element name (e.g., "wc-counter")
  url : String // Hydration script URL (luna:wc-url)
  styles : String // CSS for Shadow DOM
  state : String // Serialized state JSON
  trigger : TriggerType // Hydration trigger
  children : Array[Node[E, A]] // SSR content inside Shadow DOM
}

///|
/// Virtual DOM node types
/// Type parameter A represents the attribute value type (see Attr[E, A])
pub(all) enum Node[E, A] {
  Element(VElement[E, A])
  Text(String)
  DynamicText(() -> String)
  Fragment(Array[Node[E, A]])
  Show(condition~ : () -> Bool, child~ : () -> Node[E, A])
  For(render~ : () -> Array[Node[E, A]])
  Component(render~ : () -> Node[E, A])
  Island(VIsland[E, A]) // Hydration boundary for partial hydration (luna:* style)
  WcIsland(VWcIsland[E, A]) // Web Components based hydration (Declarative Shadow DOM)
  /// Async node - renders content asynchronously with fallback
  /// - render: async function that may raise errors
  /// - fallback: shown while loading or on error
  /// - on_error: optional error handler for custom error UI
  Async(VAsync[E, A])
  /// ErrorBoundary node - catches rendering errors in children
  /// - children: lazy child content (may throw)
  /// - fallback: (error, reset) -> fallback UI
  ErrorBoundary(VErrorBoundary[E, A])
  /// Switch node - renders first matching case or fallback
  /// Similar to Solid.js <Switch>/<Match>
  Switch(VSwitch[E, A])
  /// Internal reference to a client component (for type-safe Island embedding)
  /// Generated from ComponentRef[T] via server_dom.island()
  /// - url: Client script path
  /// - state: JSON serialized props
  /// - trigger: Hydration trigger
  /// - wc: Whether Web Components based
  /// - styles: CSS for Shadow DOM (WC only)
  /// - children: SSR content
  InternalRef(VInternalRef[E, A])
  /// Raw HTML string - rendered without escaping
  /// Use with caution: content is not sanitized
  RawHtml(String)
}

///|
/// Virtual Internal Reference node for type-safe Island embedding
pub struct VInternalRef[E, A] {
  url : String
  state : String
  trigger : TriggerType
  wc : Bool
  styles : String // CSS for Shadow DOM (empty for non-WC)
  children : Array[Node[E, A]]
}

///|
/// Virtual Async node for async rendering with error handling
/// Note: async functions implicitly raise Error, no need for raise? annotation
pub struct VAsync[E, A] {
  render : async () -> Node[E, A]
  fallback : () -> Node[E, A]
  on_error : ((Error) -> Node[E, A])?
}

///|
/// Virtual ErrorBoundary node for catching rendering errors
/// Similar to Solid.js ErrorBoundary - catches errors during:
/// - Child component rendering
/// - Effects and memos within children
/// Does NOT catch:
/// - Event handler errors
/// - Async errors outside render cycle
pub struct VErrorBoundary[E, A] {
  children : () -> Node[E, A] raise
  fallback : (Error, () -> Unit) -> Node[E, A] raise // (error, reset) -> fallbackUI
}

///|
/// Match case for Switch - pairs a condition with content
pub struct MatchCase[E, A] {
  when : () -> Bool
  render : () -> Node[E, A]
}

///|
/// Virtual Switch node - renders first matching case
/// Similar to Solid.js <Switch>/<Match>
/// - cases: array of condition-content pairs, evaluated in order
/// - fallback: optional content when no case matches
pub struct VSwitch[E, A] {
  cases : Array[MatchCase[E, A]]
  fallback : (() -> Node[E, A])?
}

///|
/// Virtual element node
pub struct VElement[E, A] {
  tag : String
  attrs : Array[(String, Attr[E, A])]
  children : Array[Node[E, A]]
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

///|
/// Convert TriggerType to attribute value.
/// ```mbt check
/// test {
///   inspect(TriggerType::Load.to_string(), content="load")
///   inspect(TriggerType::Idle.to_string(), content="idle")
///   inspect(TriggerType::Visible.to_string(), content="visible")
///   inspect(
///     TriggerType::Media("(max-width: 768px)").to_string(),
///     content="media:(max-width: 768px)",
///   )
///   inspect(TriggerType::None.to_string(), content="none")
/// }
/// ```
pub fn TriggerType::to_string(self : TriggerType) -> String {
  match self {
    Load => "load"
    Idle => "idle"
    Visible => "visible"
    Media(query) => "media:" + query
    None => "none"
  }
}

///|
/// Parse TriggerType from string.
/// ```mbt check
/// test {
///   // Round-trip test: parse then to_string
///   inspect(TriggerType::parse("load").to_string(), content="load")
///   inspect(TriggerType::parse("idle").to_string(), content="idle")
///   inspect(TriggerType::parse("visible").to_string(), content="visible")
///   inspect(TriggerType::parse("none").to_string(), content="none")
///   inspect(
///     TriggerType::parse("media:(min-width: 1024px)").to_string(),
///     content="media:(min-width: 1024px)",
///   )
/// }
/// ```
pub fn TriggerType::parse(s : String) -> TriggerType {
  match s {
    "load" => Load
    "idle" => Idle
    "visible" => Visible
    "none" => None
    _ =>
      if s.has_prefix("media:") {
        let sb = StringBuilder::new()
        for i = 6; i < s.length(); i = i + 1 {
          sb.write_char(s.iter().nth(i).unwrap())
        }
        Media(sb.to_string())
      } else {
        Load // default
      }
  }
}

///|
/// Check if element has dynamic content that needs hydration
pub fn[E, A] has_dynamic_content(attrs : Array[(String, Attr[E, A])]) -> Bool {
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
/// Create a static attribute value.
/// ```mbt check
/// test {
///   let attr : Attr[Unit, String] = attr_static("my-class")
///   guard attr is VStatic(v) else { fail("expected VStatic") }
///   inspect(v, content="my-class")
/// }
/// ```
pub fn[E, A] attr_static(value : A) -> Attr[E, A] {
  VStatic(value)
}

///|
/// Create a dynamic attribute value.
/// The value is computed lazily on each render.
/// ```mbt check
/// test {
///   let mut count = 0
///   let attr : Attr[Unit, String] = attr_dynamic(fn() {
///     "count-" + count.to_string()
///   })
///   guard attr is VDynamic(getter) else { fail("expected VDynamic") }
///   inspect(getter(), content="count-0")
///   count = 5
///   inspect(getter(), content="count-5")
/// }
/// ```
pub fn[E, A] attr_dynamic(getter : () -> A) -> Attr[E, A] {
  VDynamic(getter)
}

///|
/// Create a handler attribute value
pub fn[E, A] attr_handler(handler : EventHandler[E]) -> Attr[E, A] {
  VHandler(handler)
}

///|
/// Create a style attribute value (string form, e.g. "color: red; margin: 10px")
/// Note: For Web (A = String), pass the style string directly
pub fn[E] attr_style(style : String) -> Attr[E, String] {
  VStatic(style)
}

///|
/// Create a dynamic style attribute value
/// Note: For Web (A = String), the getter returns a style string
pub fn[E] attr_dynamic_style(getter : () -> String) -> Attr[E, String] {
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
/// h("button", [("onclick", action(Increment))], [...])
/// ```
pub fn[E, V, Act : Show] action(a : Act) -> Attr[E, V] {
  VAction(a.to_string())
}

// =============================================================================
// ComponentRef - Opaque type for Island component references
// =============================================================================

///|
/// Hydration trigger type alias for external use
pub type Trigger = TriggerType

///|
/// Component reference for type-safe Island embedding
/// Represents a client-side component that can be embedded in server-rendered HTML
/// - url: Path to the client JavaScript (e.g., "/static/counter.js")
/// - props: Component props (must be ToJson serializable)
/// - wc: Whether this is a Web Components based Island
/// - trigger: When to hydrate the component
pub(all) struct ComponentRef[T] {
  url : String
  props : T
  wc : Bool
  trigger : TriggerType
}

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
  { callback: fn(_) { () } }
}

///|
/// Create an event handler from a simple callback (ignores event, for SSR compatibility)
pub fn handler_from_callback(f : () -> Unit) -> EventHandler[Unit] {
  { callback: fn(_) { f() } }
}
