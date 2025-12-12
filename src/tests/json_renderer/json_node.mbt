///| JSON Renderer - Platform-independent render target

///| Renders VNode to a JSON-serializable structure

///|
/// JSON-serializable node representation
pub enum JsonNode {
  Element(JsonElement)
  Text(String)
  Fragment(Array[JsonNode])
} derive(Eq, Show)

///|
/// JSON element structure
pub struct JsonElement {
  tag : String
  attrs : Map[String, JsonAttrValue]
  children : Array[JsonNode]
} derive(Eq, Show)

///|
/// Attribute value in JSON representation
pub enum JsonAttrValue {
  Static(String)
  Dynamic(String) // Evaluated value at render time
  Handler // Placeholder for event handlers
} derive(Eq, Show)

///|
/// Create a JSON element node
pub fn json_element(
  tag : String,
  attrs : Map[String, JsonAttrValue],
  children : Array[JsonNode],
) -> JsonNode {
  Element({ tag, attrs, children })
}

///|
/// Create a JSON text node
pub fn json_text(content : String) -> JsonNode {
  Text(content)
}

///|
/// Create a JSON fragment node
pub fn json_fragment(children : Array[JsonNode]) -> JsonNode {
  Fragment(children)
}

///|
/// Get the tag name of a JSON element (returns None for non-elements)
pub fn JsonNode::tag(self : JsonNode) -> String? {
  match self {
    Element(elem) => Some(elem.tag)
    _ => None
  }
}

///|
/// Get children of a JSON node
pub fn JsonNode::children(self : JsonNode) -> Array[JsonNode] {
  match self {
    Element(elem) => elem.children
    Fragment(children) => children
    Text(_) => []
  }
}

///|
/// Get attribute value from JSON element
pub fn JsonNode::get_attr(self : JsonNode, name : String) -> JsonAttrValue? {
  match self {
    Element(elem) => elem.attrs.get(name)
    _ => None
  }
}

// =============================================================================
// JsonAttrValue factory functions
// =============================================================================

///|
/// Create a static attribute value
pub fn attr_static(value : String) -> JsonAttrValue {
  Static(value)
}

///|
/// Create a dynamic attribute value
pub fn attr_dynamic_value(value : String) -> JsonAttrValue {
  Dynamic(value)
}

///|
/// Create a handler attribute value
pub fn attr_handler_value() -> JsonAttrValue {
  Handler
}
