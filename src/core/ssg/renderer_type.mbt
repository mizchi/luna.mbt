///|
/// Renderer type for content rendering
/// Determined during file scanning based on content type and configuration

///|
/// Renderer types supported by Astra SSG
pub(all) enum RendererType {
  /// Markdown renderer - converts .md to HTML via markdown parser
  MarkdownRenderer
  /// HTML renderer - passes through .html content (optionally sanitized)
  HtmlRenderer
  /// Luna renderer - MoonBit components with SSR via compiled modules
  LunaRenderer
  /// React renderer - TSX components with React SSR
  ReactRenderer
  /// Client-only renderer - placeholder for client-side hydration
  ClientOnlyRenderer
} derive(Eq, Show)

///|
/// Default renderer type
pub fn RendererType::default() -> RendererType {
  MarkdownRenderer
}
