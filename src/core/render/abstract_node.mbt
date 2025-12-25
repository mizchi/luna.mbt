// Abstract Node Definitions
//
// Framework-agnostic node structure for rendering.
// Can be converted to/from Luna Node, React elements, etc.

///|
/// Attribute value types
pub(all) enum AttrValue {
  /// String attribute value
  Str(String)
  /// Boolean attribute (presence/absence)
  Bool(Bool)
  /// Numeric attribute
  Num(Double)
  /// JSON value for complex data
  Json(Json)
} derive(Eq, Show)

///|
/// Component hydration configuration
pub(all) struct ComponentConfig {
  /// Component identifier/name
  name : String
  /// Props as JSON
  props : Json
  /// Render mode
  mode : RenderMode
  /// Client script URL (for hydration)
  client_url : String?
  /// Use Web Components
  use_web_component : Bool
} derive(Eq, Show)

///|
/// Abstract node - framework-agnostic representation
pub(all) enum AbstractNode {
  /// HTML element
  Element(
    tag~ : String,
    attrs~ : Array[(String, AttrValue)],
    children~ : Array[AbstractNode]
  )
  /// Text content
  Text(String)
  /// Fragment (multiple nodes without wrapper)
  Fragment(Array[AbstractNode])
  /// Component with render mode
  Component(config~ : ComponentConfig, children~ : Array[AbstractNode])
  /// Raw HTML (unsafe)
  RawHtml(String)
  /// Slot for content projection
  Slot(name~ : String, fallback~ : Array[AbstractNode])
} derive(Eq, Show)

// =============================================================================
// Constructors
// =============================================================================

///|
/// Create an element node
pub fn element(
  tag : String,
  attrs : Array[(String, AttrValue)],
  children : Array[AbstractNode],
) -> AbstractNode {
  Element(tag~, attrs~, children~)
}

///|
/// Create a text node
pub fn text(content : String) -> AbstractNode {
  Text(content)
}

///|
/// Create a fragment
pub fn fragment(children : Array[AbstractNode]) -> AbstractNode {
  Fragment(children)
}

///|
/// Create a component node
pub fn component(
  name : String,
  props : Json,
  mode : RenderMode,
  children : Array[AbstractNode],
  client_url? : String? = None,
  use_web_component? : Bool = false,
) -> AbstractNode {
  Component(
    config=ComponentConfig::{ name, props, mode, client_url, use_web_component },
    children~,
  )
}

///|
/// Create a raw HTML node
pub fn raw_html(html : String) -> AbstractNode {
  RawHtml(html)
}

// =============================================================================
// Tree Operations
// =============================================================================

///|
/// Count total nodes in tree
pub fn AbstractNode::count_nodes(self : AbstractNode) -> Int {
  match self {
    Element(children~, ..) =>
      1 + children.fold(init=0, fn(acc, child) { acc + child.count_nodes() })
    Text(_) => 1
    Fragment(children) =>
      children.fold(init=0, fn(acc, child) { acc + child.count_nodes() })
    Component(children~, ..) =>
      1 + children.fold(init=0, fn(acc, child) { acc + child.count_nodes() })
    RawHtml(_) => 1
    Slot(fallback~, ..) =>
      1 + fallback.fold(init=0, fn(acc, child) { acc + child.count_nodes() })
  }
}

///|
/// Get all components in tree
pub fn AbstractNode::get_components(
  self : AbstractNode,
) -> Array[ComponentConfig] {
  let result : Array[ComponentConfig] = []
  collect_components(self, result)
  result
}

///|
fn collect_components(
  node : AbstractNode,
  result : Array[ComponentConfig],
) -> Unit {
  match node {
    Element(children~, ..) =>
      for child in children {
        collect_components(child, result)
      }
    Fragment(children) =>
      for child in children {
        collect_components(child, result)
      }
    Component(config~, children~) => {
      result.push(config)
      for child in children {
        collect_components(child, result)
      }
    }
    Slot(fallback~, ..) =>
      for child in fallback {
        collect_components(child, result)
      }
    Text(_) | RawHtml(_) => ()
  }
}

///|
/// Get all render modes used in tree
pub fn AbstractNode::get_render_modes(self : AbstractNode) -> Array[RenderMode] {
  let components = self.get_components()
  let modes : Array[RenderMode] = []
  let seen : Map[String, Bool] = {}
  for comp in components {
    let key = comp.mode.to_string()
    if not(seen.contains(key)) {
      seen[key] = true
      modes.push(comp.mode)
    }
  }
  modes
}

///|
/// Check if tree has any client-side JavaScript
pub fn AbstractNode::has_client_js(self : AbstractNode) -> Bool {
  let components = self.get_components()
  for comp in components {
    if comp.mode.requires_client_js() {
      return true
    }
  }
  false
}

///|
/// Map over all nodes in tree
pub fn AbstractNode::map(
  self : AbstractNode,
  f : (AbstractNode) -> AbstractNode,
) -> AbstractNode {
  let mapped = match self {
    Element(tag~, attrs~, children~) =>
      Element(tag~, attrs~, children=children.map(fn(c) { c.map(f) }))
    Fragment(children) => Fragment(children.map(fn(c) { c.map(f) }))
    Component(config~, children~) =>
      Component(config~, children=children.map(fn(c) { c.map(f) }))
    Slot(name~, fallback~) =>
      Slot(name~, fallback=fallback.map(fn(c) { c.map(f) }))
    Text(_) | RawHtml(_) => self
  }
  f(mapped)
}
