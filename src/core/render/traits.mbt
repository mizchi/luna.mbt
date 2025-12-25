// Renderer Traits
//
// Interfaces that different renderers (Luna, React, Preact) implement.

///|
/// Component metadata for registration and optimization
pub(all) struct ComponentMeta {
  /// Unique component name
  name : String
  /// Props JSON Schema (optional)
  props_schema : Json?
  /// Whether component has client-side code
  has_client_code : Bool
  /// Dependencies (other component names)
  dependencies : Array[String]
  /// Supported render modes
  supported_modes : Array[RenderMode]
} derive(Eq, Show)

///|
/// Result of server-side rendering
pub(all) struct SSRResult {
  /// Rendered HTML string
  html : String
  /// Hydration markers present
  has_hydration_markers : Bool
  /// Head content to inject (styles, preloads)
  head_content : String?
  /// Scripts to inject
  scripts : Array[String]
}

///|
/// Server-side renderer interface
pub(open) trait ServerRenderer {
  /// Render abstract node to HTML string
  render_to_string(Self, AbstractNode) -> String

  /// Render with hydration markers for client takeover
  render_with_hydration(Self, AbstractNode) -> SSRResult

  /// Get component metadata by name
  get_component_meta(Self, String) -> ComponentMeta?

  /// Check if renderer supports a given mode
  supports_mode(Self, RenderMode) -> Bool
}

///|
/// Renderer configuration
pub(all) struct RendererConfig {
  /// Renderer identifier
  name : String
  /// Server-side module path
  server_module : String
  /// Client-side bundle path
  client_bundle : String?
  /// File extensions this renderer handles
  extensions : Array[String]
  /// Supported features
  features : RendererFeatures
} derive(Eq, Show)

///|
/// Feature flags for renderer capabilities
pub(all) struct RendererFeatures {
  /// Supports server-side rendering
  supports_ssr : Bool
  /// Supports client-side hydration
  supports_hydration : Bool
  /// Supports streaming SSR
  supports_streaming : Bool
  /// Supports server islands (deferred rendering)
  supports_server_islands : Bool
  /// Supports Web Components output
  supports_web_components : Bool
} derive(Eq, Show)

///|
/// Default renderer features
pub fn RendererFeatures::default() -> RendererFeatures {
  {
    supports_ssr: true,
    supports_hydration: true,
    supports_streaming: false,
    supports_server_islands: false,
    supports_web_components: false,
  }
}

///|
/// Full-featured renderer
pub fn RendererFeatures::full() -> RendererFeatures {
  {
    supports_ssr: true,
    supports_hydration: true,
    supports_streaming: true,
    supports_server_islands: true,
    supports_web_components: true,
  }
}
