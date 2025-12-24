// MoonBit FFI bindings for Shiki syntax highlighter
// https://shiki.style

// =============================================================================
// Types
// =============================================================================

///|
/// Highlighter instance
#external
pub type Highlighter

///|
/// Convert Highlighter to Any for property access
pub extern "js" fn Highlighter::as_any(self : Highlighter) -> @core.Any =
  #| (x) => x

// =============================================================================
// Language Aliases
// =============================================================================

///|
/// Language aliases for common shorthand names
let lang_aliases : Map[String, String] = {
  "js": "javascript",
  "ts": "typescript",
  "mbt": "rust", // MoonBit syntax is similar to Rust
  "moonbit": "rust",
  "sh": "bash",
  "shell": "bash",
  "zsh": "bash",
  "yml": "yaml",
  "dockerfile": "docker",
}

///|
/// Resolve language alias to actual language name
pub fn resolve_language(lang : String) -> String {
  lang_aliases.get(lang).unwrap_or(lang)
}

// =============================================================================
// Supported Languages
// =============================================================================

///|
/// Check if a language is likely supported
/// Note: This is a best-effort check. Shiki will gracefully handle unknown languages.
pub fn is_language_supported(lang : String) -> Bool {
  let resolved = resolve_language(lang)
  // Common languages that Shiki supports
  let supported = [
    "javascript", "typescript", "json", "html", "css", "markdown", "rust", "python",
    "go", "java", "c", "cpp", "csharp", "ruby", "php", "swift", "kotlin", "scala",
    "lua", "bash", "shell", "powershell", "sql", "yaml", "toml", "xml", "graphql",
    "dockerfile", "makefile", "vue", "svelte", "jsx", "tsx", "astro",
  ]
  supported.contains(resolved)
}

// =============================================================================
// Create Highlighter
// =============================================================================

///|
/// Create a new Shiki highlighter with specified themes and languages
/// Languages are loaded eagerly to support sync highlighting
pub extern "js" fn create_highlighter_async(
  themes : Array[String],
  langs : Array[String],
) -> @core.Promise[Highlighter] =
  #| async (themes, langs) => {
  #|   const { createHighlighter } = await import("shiki");
  #|   // Default common languages if none specified
  #|   const defaultLangs = langs.length > 0 ? langs : [
  #|     "javascript", "typescript", "json", "html", "css", "bash",
  #|     "rust", "python", "go", "yaml", "markdown", "tsx", "jsx"
  #|   ];
  #|   return await createHighlighter({ themes, langs: defaultLangs });
  #| }

///|
/// Create a highlighter with default GitHub themes (light/dark)
pub fn create_default_highlighter() -> @core.Promise[Highlighter] {
  create_highlighter_async(["github-light", "github-dark"], [])
}

// =============================================================================
// Highlighter Methods
// =============================================================================

///|
/// Get list of loaded languages
pub fn Highlighter::get_loaded_languages(self : Highlighter) -> Array[String] {
  self.as_any()._call("getLoadedLanguages", []).cast()
}

///|
/// Get list of loaded themes
pub fn Highlighter::get_loaded_themes(self : Highlighter) -> Array[String] {
  self.as_any()._call("getLoadedThemes", []).cast()
}

///|
/// Load a language dynamically
pub extern "js" fn Highlighter::load_language_async(
  self : Highlighter,
  lang : String,
) -> @core.Promise[Unit] =
  #| async (h, lang) => { await h.loadLanguage(lang); }

///|
/// Check if a language is loaded
pub fn Highlighter::is_language_loaded(
  self : Highlighter,
  lang : String,
) -> Bool {
  let loaded = self.get_loaded_languages()
  loaded.contains(lang)
}

///|
/// Ensure a language is loaded (load if not already loaded)
pub extern "js" fn Highlighter::ensure_language_async(
  self : Highlighter,
  lang : String,
) -> @core.Promise[Unit] =
  #| async (h, lang) => {
  #|   const loaded = h.getLoadedLanguages();
  #|   if (!loaded.includes(lang)) {
  #|     try {
  #|       await h.loadLanguage(lang);
  #|     } catch (e) {
  #|       console.warn(`[shiki] Failed to load language: ${lang}`, e.message);
  #|     }
  #|   }
  #| }

// =============================================================================
// Code to HTML
// =============================================================================

///|
/// Highlight code to HTML with a single theme
pub fn Highlighter::code_to_html(
  self : Highlighter,
  code : String,
  lang~ : String,
  theme~ : String,
) -> String {
  let options = @core.from_entries([
    ("lang", @core.any(lang)),
    ("theme", @core.any(theme)),
  ])
  self.as_any()._call("codeToHtml", [@core.any(code), options]).cast()
}

///|
/// Highlight code to HTML with dual themes (light/dark with CSS variables)
pub fn Highlighter::code_to_html_dual(
  self : Highlighter,
  code : String,
  lang~ : String,
  light_theme? : String = "github-light",
  dark_theme? : String = "github-dark",
) -> String {
  let themes = @core.from_entries([
    ("light", @core.any(light_theme)),
    ("dark", @core.any(dark_theme)),
  ])
  let options = @core.from_entries([
    ("lang", @core.any(lang)),
    ("themes", themes),
    ("defaultColor", @core.any(false)), // Use CSS variables
  ])
  self.as_any()._call("codeToHtml", [@core.any(code), options]).cast()
}

///|
/// Highlight code with language auto-resolution and fallback
pub extern "js" fn Highlighter::highlight_async(
  self : Highlighter,
  code : String,
  lang : String,
) -> @core.Promise[String] =
  #| async (h, code, lang) => {
  #|   // Resolve language alias
  #|   const aliases = { js: "javascript", ts: "typescript", mbt: "rust", moonbit: "rust", sh: "bash", shell: "bash", yml: "yaml" };
  #|   const resolved = aliases[lang] || lang;
  #|
  #|   // Try to load language
  #|   const loaded = h.getLoadedLanguages();
  #|   if (!loaded.includes(resolved)) {
  #|     try {
  #|       await h.loadLanguage(resolved);
  #|     } catch (e) {
  #|       // Return plain code block if language not supported
  #|       return `<pre class="shiki" data-lang="${lang}"><code>${code.replace(/</g, '&lt;').replace(/>/g, '&gt;')}</code></pre>`;
  #|     }
  #|   }
  #|
  #|   // Highlight with dual themes
  #|   return h.codeToHtml(code, {
  #|     lang: resolved,
  #|     themes: { light: "github-light", dark: "github-dark" },
  #|     defaultColor: false,
  #|   });
  #| }

// =============================================================================
// Utility Functions
// =============================================================================

///|
/// Decode HTML entities in code content
/// Note: &amp; must be decoded last to avoid double-decoding
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
/// Generate CSS for Shiki dual theme support
pub fn generate_shiki_css() -> String {
  let css =
    #|/* Shiki syntax highlighting - dual theme support */
    #|/* Light theme (default) */
    #|.shiki,
    #|.shiki span {
    #|  color: var(--shiki-light);
    #|  background-color: var(--shiki-light-bg);
    #|}
    #|
    #|/* Dark theme - controlled by .dark class on html */
    #|html.dark .shiki,
    #|html.dark .shiki span {
    #|  color: var(--shiki-dark);
    #|  background-color: var(--shiki-dark-bg);
    #|}
    #|
    #|/* Code block styling */
    #|.shiki {
    #|  padding: 1rem;
    #|  border-radius: 6px;
    #|  overflow-x: auto;
    #|  font-size: 0.875rem;
    #|  line-height: 1.6;
    #|}
    #|
    #|.shiki code {
    #|  background: none;
    #|  padding: 0;
    #|  font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, "Liberation Mono", monospace;
    #|}
    #|
    #|/* Code block with filename header */
    #|.code-block-wrapper {
    #|  margin: 1rem 0;
    #|  border-radius: 6px;
    #|  overflow: hidden;
    #|  border: 1px solid var(--border-color, #d0d7de);
    #|}
    #|
    #|.code-block-header {
    #|  display: flex;
    #|  justify-content: space-between;
    #|  align-items: center;
    #|  padding: 0.5rem 1rem;
    #|  background: var(--sidebar-bg, #f6f8fa);
    #|  border-bottom: 1px solid var(--border-color, #d0d7de);
    #|  font-size: 0.75rem;
    #|}
    #|
    #|.code-block-filename {
    #|  font-weight: 600;
    #|  font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace;
    #|}
    #|
    #|.code-block-lang {
    #|  color: var(--text-muted, #656d76);
    #|  text-transform: uppercase;
    #|  font-size: 0.625rem;
    #|  letter-spacing: 0.05em;
    #|}
    #|
    #|.code-block-wrapper .shiki {
    #|  margin: 0;
    #|  border-radius: 0;
    #|}
    #|
    #|/* Improve contrast for comments in dark mode */
    #|/* WCAG AA requires 4.5:1 for normal text, 3:1 for large text */
    #|html.dark .shiki span[style*="--shiki-dark:#6e7681"],
    #|html.dark .shiki span[style*="--shiki-dark:#8b949e"] {
    #|  --shiki-dark: #9ca3af !important;
    #|}
  css
}
