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
/// Parse code block info string.
///
/// Delegates to @md, but first splits off bare (unbraced) attributes that
/// follow the language token. CommonMark lets an info string carry anything
/// after the language, and MoonBit's literate markdown uses that: a compiled
/// fence is written ` ```mbt check `, where `check` is an attribute rather
/// than part of the language name. Without this split the block would be
/// tagged `data-lang="mbt check"` and fall through the highlighter.
///
/// "mbt check"                -> lang "mbt",  meta "check"
/// "js {highlight=[1,3]}"     -> lang "js",   meta "{highlight=[1,3]}"
/// "ts:index.ts twoslash"     -> lang "ts",   filename "index.ts", meta "twoslash"
pub fn parse_code_block_info(info : String) -> @md.CodeBlockInfo {
  let trimmed = info.trim(chars=" \t\n\r")
  match trimmed.find(" ") {
    None => @md.parse_code_block_info(trimmed.to_owned())
    Some(idx) => {
      let head = @md.parse_code_block_info(trimmed[0:idx].to_owned())
      let rest = trimmed[idx + 1:].trim(chars=" \t\n\r").to_owned()
      { lang: head.lang, filename: head.filename, meta: rest }
    }
  }
}
