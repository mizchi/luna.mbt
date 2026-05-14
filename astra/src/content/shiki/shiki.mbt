// Syntax highlighting via mizchi/syntree (pure MoonBit, native compatible)
// Drop-in replacement for the previous Shiki JS FFI bindings

// =============================================================================
// Types (compatible with existing SSG code)
// =============================================================================

///|
/// Highlighter instance (now a thin wrapper around syntree theme)
pub struct Highlighter {
  theme : @highlight.HighlightTheme
}

///|
/// Create a highlighter with default theme
pub fn create_default_highlighter() -> Highlighter {
  { theme: @highlight.github_dark() }
}

///|
/// Language aliases for common shorthand names
let lang_aliases : Map[String, String] = {
  "js": "typescript",
  "ts": "typescript",
  "mbt": "moonbit",
  "sh": "bash",
  "shell": "bash",
  "zsh": "bash",
  "yml": "yaml",
  "dockerfile": "bash",
}

///|
/// Resolve language alias to actual language name
pub fn resolve_language(lang : String) -> String {
  lang_aliases.get(lang).unwrap_or(lang)
}

///|
/// Check if a language is supported by syntree
pub fn is_language_supported(lang : String) -> Bool {
  let resolved = resolve_language(lang)
  @syntree.supported_languages().contains(resolved)
}

// =============================================================================
// Highlighter Methods
// =============================================================================

///|
/// Highlight code to HTML with the configured theme
pub fn Highlighter::highlight(
  self : Highlighter,
  code : String,
  lang : String,
) -> String {
  let resolved = resolve_language(lang)
  highlight_by_language(code, resolved, self.theme)
}

///|
/// Highlight code (async signature for backward compat, actually sync)
pub fn Highlighter::highlight_sync(
  self : Highlighter,
  code : String,
  lang : String,
) -> String {
  self.highlight(code, lang)
}

///|
fn highlight_by_language(
  code : String,
  lang : String,
  theme : @highlight.HighlightTheme,
) -> String {
  match lang {
    "typescript" | "javascript" | "tsx" | "jsx" =>
      @highlight.highlight_typescript(code, theme)
    "moonbit" => @highlight.highlight_moonbit(code, theme)
    "rust" => @highlight.highlight_rust(code, theme)
    "python" => @highlight.highlight_python(code, theme)
    "go" => @highlight.highlight_go(code, theme)
    "java" => @highlight.highlight_java(code, theme)
    "c" | "cpp" | "csharp" => @highlight.highlight_c(code, theme)
    "html" => @highlight.highlight_html(code, theme)
    "css" => @highlight.highlight_css(code, theme)
    "json" => @highlight.highlight_json(code, theme)
    "yaml" => @highlight.highlight_yaml(code, theme)
    "toml" => @highlight.highlight_toml(code, theme)
    "bash" => @highlight.highlight_bash(code, theme)
    "sql" => @highlight.highlight_sql(code, theme)
    "swift" => @highlight.highlight_swift(code, theme)
    "ocaml" => @highlight.highlight_ocaml(code, theme)
    "zig" => @highlight.highlight_zig(code, theme)
    "ruby"
    | "php"
    | "kotlin"
    | "scala"
    | "lua"
    | "graphql"
    | "xml"
    | "makefile"
    | "markdown" =>
      // Unsupported language — return escaped code block
      plain_code_block(code, lang)
    _ => plain_code_block(code, lang)
  }
}

///|
/// Plain code block for unsupported languages
fn plain_code_block(code : String, lang : String) -> String {
  let escaped = @syntree.escape_html(code)
  "<pre class=\"shiki\" data-lang=\"\{lang}\"><code>\{escaped}</code></pre>"
}

// =============================================================================
// Utility Functions
// =============================================================================

///|
/// Decode HTML entities in code content
pub fn decode_html_entities(html : String) -> String {
  html
  .replace_all(old="&lt;", new="<")
  .replace_all(old="&gt;", new=">")
  .replace_all(old="&quot;", new="\"")
  .replace_all(old="&#39;", new="'")
  .replace_all(old="&#x27;", new="'")
  .replace_all(old="&#x2F;", new="/")
  .replace_all(old="&amp;", new="&") // Must be last
}

///|
/// Generate CSS for syntax highlighting
pub fn generate_shiki_css() -> String {
  let theme = @highlight.github_dark()
  let css = StringBuilder::new()
  css.write_string("/* Syntax highlighting - generated from syntree theme */\n")
  css.write_string("pre.shiki {\n")
  css.write_string("  background-color: \{theme.background};\n")
  css.write_string("  color: \{theme.foreground};\n")
  css.write_string("  padding: 1rem;\n")
  css.write_string("  border-radius: 6px;\n")
  css.write_string("  overflow-x: auto;\n")
  css.write_string("  font-size: 0.875rem;\n")
  css.write_string("  line-height: 1.6;\n")
  css.write_string("}\n\n")
  css.write_string("pre.shiki code {\n")
  css.write_string("  background: none;\n")
  css.write_string("  padding: 0;\n")
  css.write_string(
    "  font-family: ui-monospace, SFMono-Regular, \"SF Mono\", Menlo, Consolas, \"Liberation Mono\", monospace;\n",
  )
  css.write_string("}\n\n")
  css.write_string("/* Code block with filename header */\n")
  css.write_string(".code-block-wrapper {\n")
  css.write_string("  margin: 1rem 0;\n")
  css.write_string("  border-radius: 6px;\n")
  css.write_string("  overflow: hidden;\n")
  css.write_string("  border: 1px solid var(--border-color, #d0d7de);\n")
  css.write_string("}\n\n")
  css.write_string(".code-block-header {\n")
  css.write_string("  display: flex;\n")
  css.write_string("  justify-content: space-between;\n")
  css.write_string("  align-items: center;\n")
  css.write_string("  padding: 0.5rem 1rem;\n")
  css.write_string("  background: var(--sidebar-bg, #f6f8fa);\n")
  css.write_string("  border-bottom: 1px solid var(--border-color, #d0d7de);\n")
  css.write_string("  font-size: 0.75rem;\n")
  css.write_string("}\n\n")
  css.write_string(".code-block-filename {\n")
  css.write_string("  font-weight: 600;\n")
  css.write_string(
    "  font-family: ui-monospace, SFMono-Regular, \"SF Mono\", Menlo, Consolas, monospace;\n",
  )
  css.write_string("}\n\n")
  css.write_string(".code-block-lang {\n")
  css.write_string("  color: var(--text-muted, #656d76);\n")
  css.write_string("  text-transform: uppercase;\n")
  css.write_string("  font-size: 0.625rem;\n")
  css.write_string("  letter-spacing: 0.05em;\n")
  css.write_string("}\n\n")
  css.write_string(".code-block-wrapper pre.shiki {\n")
  css.write_string("  margin: 0;\n")
  css.write_string("  border-radius: 0;\n")
  css.write_string("}\n")
  css.to_string()
}
