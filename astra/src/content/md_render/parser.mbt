// Markdown Parser - Pure MoonBit Implementation
// Uses the CST-based parser from @cst for parsing

// =============================================================================
// Markdown Parsing
// =============================================================================

///|
/// Parse markdown content and return frontmatter + AST
/// This uses the native MoonBit parser (no external dependencies)
pub fn parse_markdown(
  content : String,
) -> (@frontmatter.Frontmatter, Array[@markdown.MdNode]) {
  @cst.parse_markdown_native(content)
}

// =============================================================================
// Re-exports from @cst
// =============================================================================

///|
/// Parse markdown using the native MoonBit parser (no FFI)
/// Alias for @cst.parse_markdown_native
pub fn parse_markdown_native(
  content : String,
) -> (@frontmatter.Frontmatter, Array[@markdown.MdNode]) {
  @cst.parse_markdown_native(content)
}

///|
/// Parse Island directive from HTML string
/// Re-exported from @cst
pub fn parse_island_directive(html : String) -> @markdown.IslandEmbed? {
  @cst.parse_island_directive(html)
}

///|
/// Parse custom element tag from HTML string
/// Re-exported from @cst
pub fn parse_custom_element(html : String) -> @markdown.ComponentEmbed? {
  @cst.parse_custom_element(html)
}

///|
/// Generate heading ID from text (for anchor links)
/// Re-exported from @slug
pub fn generate_heading_id(text : String) -> String {
  @slug.generate_heading_id(text)
}

///|
/// Parse code block info string
/// Re-exported from @info_string
pub fn parse_code_block_info(info : String) -> @info_string.CodeBlockInfo {
  @info_string.parse(info)
}
