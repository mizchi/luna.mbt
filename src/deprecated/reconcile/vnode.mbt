///| VNode types for reconciliation
///| Extracted from proto_vdom for reference implementation

///|
/// Virtual Node - parameterized by handler type H for multi-backend support
pub enum VNode[H] {
  Element(ElementNode[H])
  Text(String)
  Fragment(Array[VNode[H]])
  Empty
}

///|
/// DOM Element node
pub struct ElementNode[H] {
  tag : String
  props : Props[H]
  children : Array[VNode[H]]
  key : String?
}

///|
/// Attribute value - typed representation of prop values
pub enum AttrValue[H] {
  Str(String)
  Num(Int)
  Bool(Bool)
  Handler(H)
  StyleObj(Array[(String, String)])
}

///|
/// Props - array of key-value pairs
pub type Props[H] = Array[(String, AttrValue[H])]

///|
/// JS-specific handler type
pub type JSHandler = (@core.Any) -> Unit

///|
/// JS-specific type aliases
pub type JSVNode = VNode[JSHandler]

///|
pub type JSProps = Props[JSHandler]

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
    _ => false
  }
}

///|
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
