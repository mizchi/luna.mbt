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

// =============================================================================
// Type aliases for static DOM (SSR/pre-rendering)
// =============================================================================

///|
/// Static DOM node - no event handlers, string attributes
/// Use for SSR, static site generation, or pre-rendering
pub type StaticDomNode = Node[Unit, String]

///|
/// Static DOM attribute - no event handlers, string values
pub type StaticDomAttr = Attr[Unit, String]
