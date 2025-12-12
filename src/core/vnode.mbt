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
/// Used for declarative event handling: ("onclick", action("increment"))
pub fn[E] action(name : String) -> Attr[E] {
  VAction(name)
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
