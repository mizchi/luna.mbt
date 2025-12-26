// Web Component Types
// Type definitions for Web Components generation

/// Attribute type for Web Components
pub enum AttrType {
  /// String attribute: foo="bar"
  String(default~ : String)
  /// Integer attribute: count="42"
  Int(default~ : Int)
  /// Float attribute: ratio="0.5"
  Float(default~ : Double)
  /// Boolean attribute: disabled (presence = true)
  Bool(default~ : Bool)
}

/// Attribute definition
pub struct AttrDef {
  /// Attribute name (kebab-case in HTML)
  name : String
  /// Attribute type and default value
  attr_type : AttrType
  /// Whether to reflect property changes to attribute
  reflect : Bool
}

/// Shadow DOM mode
pub enum ShadowMode {
  /// Open shadow root (default)
  Open
  /// Closed shadow root
  Closed
  /// No shadow DOM (light DOM)
  None
} derive(Eq)

/// Component metadata for code generation
pub struct ComponentMeta {
  /// Custom element tag name (e.g., "x-counter")
  tag : String
  /// Attribute definitions
  attributes : Array[AttrDef]
  /// Shadow DOM mode
  shadow : ShadowMode
  /// CSS styles (Constructable Stylesheets)
  styles : String
}

// =============================================================================
// Attribute Definition Helpers
// =============================================================================

/// Create a string attribute definition
pub fn attr_string(name : String, default~ : String = "") -> AttrDef {
  { name, attr_type: String(default=default), reflect: false }
}

/// Create an integer attribute definition
pub fn attr_int(name : String, default~ : Int = 0) -> AttrDef {
  { name, attr_type: Int(default=default), reflect: false }
}

/// Create a float attribute definition
pub fn attr_float(name : String, default~ : Double = 0.0) -> AttrDef {
  { name, attr_type: Float(default=default), reflect: false }
}

/// Create a boolean attribute definition
pub fn attr_bool(name : String, default~ : Bool = false) -> AttrDef {
  { name, attr_type: Bool(default=default), reflect: false }
}

/// Set reflect option on attribute
pub fn AttrDef::with_reflect(self : AttrDef) -> AttrDef {
  { ..self, reflect: true }
}

// =============================================================================
// ComponentMeta Builder
// =============================================================================

/// Create a new component metadata
pub fn ComponentMeta::new(tag : String) -> ComponentMeta {
  { tag, attributes: [], shadow: Open, styles: "" }
}

/// Add an attribute definition
pub fn ComponentMeta::with_attr(self : ComponentMeta, attr : AttrDef) -> ComponentMeta {
  let attrs = self.attributes.copy()
  attrs.push(attr)
  { ..self, attributes: attrs }
}

/// Set shadow DOM mode
pub fn ComponentMeta::with_shadow(self : ComponentMeta, mode : ShadowMode) -> ComponentMeta {
  { ..self, shadow: mode }
}

/// Set CSS styles
pub fn ComponentMeta::with_styles(self : ComponentMeta, css : String) -> ComponentMeta {
  { ..self, styles: css }
}
