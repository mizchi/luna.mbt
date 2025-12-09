///| Pure MoonBit Virtual DOM Implementation

///|

///| This module provides backend-agnostic VNode types.

///| The handler type H is parameterized to support different backends:

///| - JS: H = (@core.Any) -> Unit

///| - Native: H = (NativeEvent) -> Unit

///| - WASM: H = (WasmEvent) -> Unit

///|

///|
/// Virtual Node - Pure MoonBit representation of UI tree
/// Parameterized by handler type H for multi-backend support
pub enum VNode[H] {
  Element(ElementNode[H])
  Text(String)
  Component(ComponentNode[H]) // TODO: Component support (Phase 7 - planned)
  Fragment(Array[VNode[H]])
  Empty
}

///|

///|
/// DOM Element node
/// Props is Array[(String, AttrValue[H])] for type safety and comparability
pub struct ElementNode[H] {
  tag : String
  props : Props[H]
  children : Array[VNode[H]]
  key : String?
}

///|

///|
/// Component function node
pub struct ComponentNode[H] {
  render : () -> VNode[H]
  key : String?
  hooks_state : HooksState
}

///|

///|
/// Attribute value - typed representation of prop values
/// Parameterized by handler type H (backend-specific)
pub enum AttrValue[H] {
  Str(String) // String attribute (className, id, href, etc.)
  Num(Int) // Numeric attribute (tabIndex, maxLength, etc.)
  Bool(Bool) // Boolean attribute (disabled, checked, etc.)
  Handler(H) // Event handler (onClick, onChange, etc.) - type depends on backend
  StyleObj(Array[(String, String)]) // Style object {color: "red", fontSize: "16px"}
}

///|

///|
/// Props - array of key-value pairs
/// Parameterized by handler type H
pub type Props[H] = Array[(String, AttrValue[H])]

///|

///|
/// Compare two AttrValue instances for equality
/// Note: Handlers are always considered different
pub fn[H] compare_attr_value(a : AttrValue[H], b : AttrValue[H]) -> Bool {
  match (a, b) {
    (Str(s1), Str(s2)) => s1 == s2
    (Num(n1), Num(n2)) => n1 == n2
    (Bool(b1), Bool(b2)) => b1 == b2
    (Handler(_), Handler(_)) => false // Functions cannot be compared
    (StyleObj(s1), StyleObj(s2)) => compare_style_arrays(s1, s2)
    _ => false // Different types
  }
}

///|

///|
/// Compare two style arrays for equality
fn compare_style_arrays(
  s1 : Array[(String, String)],
  s2 : Array[(String, String)],
) -> Bool {
  if s1.length() != s2.length() {
    return false
  }
  for i = 0; i < s1.length(); i = i + 1 {
    let (k1, v1) = s1[i]
    let (k2, v2) = s2[i]
    if k1 != k2 || v1 != v2 {
      return false
    }
  }
  true
}

///|

///|
/// Compare two Props for equality
pub fn[H] compare_props(p1 : Props[H], p2 : Props[H]) -> Bool {
  if p1.length() != p2.length() {
    return false
  }
  for i = 0; i < p1.length(); i = i + 1 {
    let (k1, v1) = p1[i]
    let (k2, v2) = p2[i]
    if k1 != k2 || not(compare_attr_value(v1, v2)) {
      return false
    }
  }
  true
}

///|

///|
/// Helper to check if VNode is empty
pub fn[H] VNode::is_empty(self : VNode[H]) -> Bool {
  match self {
    Empty => true
    _ => false
  }
}

///|

///|
/// Get key from VNode if it has one
pub fn[H] VNode::get_key(self : VNode[H]) -> String? {
  match self {
    Element({ key, .. }) => key
    Component({ key, .. }) => key
    _ => None
  }
}

///|

///|
/// Debug representation of VNode
pub fn[H] VNode::debug_string(self : VNode[H]) -> String {
  match self {
    Empty => "Empty"
    Text(content) => "Text(\"\{content}\")"
    Element({ tag, children, .. }) =>
      "Element(\{tag}, \{children.length()} children)"
    Component(_) => "Component(...)"
    Fragment(children) => "Fragment(\{children.length()} children)"
  }
}
