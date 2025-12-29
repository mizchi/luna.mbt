// =============================================================================
// Markdown AST Types
// =============================================================================

///|
/// Markdown node types
pub(all) enum MdNode {
  /// Heading with level (1-6)
  Heading(level~ : Int, children~ : Array[MdNode], id~ : String)
  /// Paragraph
  Paragraph(children~ : Array[MdNode])
  /// Plain text
  Text(String)
  /// Bold text
  Bold(children~ : Array[MdNode])
  /// Italic text
  Italic(children~ : Array[MdNode])
  /// Inline code
  Code(String)
  /// Code block with language
  CodeBlock(lang~ : String, code~ : String)
  /// Link
  Link(href~ : String, title~ : String, children~ : Array[MdNode])
  /// Image
  Image(src~ : String, alt~ : String, title~ : String)
  /// Unordered or ordered list
  List(ordered~ : Bool, items~ : Array[Array[MdNode]])
  /// Blockquote
  Blockquote(children~ : Array[MdNode])
  /// Table
  Table(headers~ : Array[MdNode], rows~ : Array[Array[MdNode]])
  /// Raw HTML
  Html(String)
  /// Island component directive (legacy)
  Island(IslandEmbed)
  /// Web Component custom element
  Component(ComponentEmbed)
  /// JSX component from MDX (before conversion to WebComponent)
  JsxComponent(JsxComponentEmbed)
  /// Horizontal rule
  ThematicBreak
  /// Line break
  LineBreak
}

// =============================================================================
// Island/Component Embedding Types
// =============================================================================

///|
/// Island embedding in markdown (legacy, prefer ComponentEmbed)
pub(all) struct IslandEmbed {
  /// Island component name
  name : String
  /// Props as JSON string
  props : String
  /// Hydration trigger
  trigger : @luna.Trigger
  /// Whether to render server-side (default: false, client-only placeholder)
  ssr : Bool
}

///|
/// Default Island embed
pub fn IslandEmbed::new(name : String) -> IslandEmbed {
  { name, props: "{}", trigger: @luna.Load, ssr: false }
}

///|
/// Web Component embedding in markdown
/// Custom elements (names containing `-`) are registered via customElements.define
pub(all) struct ComponentEmbed {
  /// Custom element tag name (e.g., "my-counter", "foo-bar")
  tag : String
  /// HTML attributes as key-value pairs
  attrs : Array[(String, String)]
  /// Inner HTML content
  content : String
  /// Hydration trigger
  trigger : @luna.Trigger
}

///|
/// Default Component embed
pub fn ComponentEmbed::new(tag : String) -> ComponentEmbed {
  { tag, attrs: [], content: "", trigger: @luna.Load }
}

// =============================================================================
// MDX Types
// =============================================================================

///|
/// JSX component embedding in MDX
/// Before rendering, converted to ComponentEmbed (WebComponent)
pub(all) struct JsxComponentEmbed {
  /// JSX component tag name (e.g., "Button", "Counter")
  tag : String
  /// Attributes with typed values
  attrs : Array[(String, MdxAttrValue)]
  /// Inner content (raw string, may contain nested elements)
  children : String
  /// Whether self-closing (<Component />)
  self_closing : Bool
  /// CLS optimization hints
  cls_hints : ClsHints?
}

///|
/// Default JSX component embed
pub fn JsxComponentEmbed::new(tag : String) -> JsxComponentEmbed {
  { tag, attrs: [], children: "", self_closing: false, cls_hints: None }
}

///|
/// MDX attribute value types
pub(all) enum MdxAttrValue {
  /// String literal: prop="value" or prop='value'
  StringLiteral(String)
  /// Expression: prop={expression}
  Expression(String)
  /// Boolean: prop (true when present)
  Boolean
} derive(Eq, Show)

///|
/// CLS (Cumulative Layout Shift) optimization hints
/// Used to prevent layout shifts when components load
pub(all) struct ClsHints {
  /// Expected width (CSS value, e.g., "200px", "100%")
  width : String?
  /// Expected height (CSS value, e.g., "100px", "auto")
  height : String?
} derive(Eq, Show)

///|
/// Default CLS hints (no hints)
pub fn ClsHints::new() -> ClsHints {
  { width: None, height: None }
}
