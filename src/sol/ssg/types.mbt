///| SSG (Static Site Generator) Type Definitions

// =============================================================================
// Configuration Types
// =============================================================================

///| SSG Configuration from sol.config.json
pub(all) struct SsgConfig {
  /// Input directory containing markdown files (default: "docs")
  docs_dir : String
  /// Output directory for generated HTML (default: "dist")
  output_dir : String
  /// Site title
  title : String
  /// Base URL for the site (default: "/")
  base_url : String
  /// Navigation items
  nav : Array[NavItem]
  /// Sidebar configuration
  sidebar : SidebarConfig
  /// Island directories for hydration (inherits from sol.config.json)
  islands : Array[String]
  /// Theme configuration
  theme : ThemeConfig
  /// Internationalization configuration
  i18n : I18nConfig
}

///| Internationalization configuration
pub(all) struct I18nConfig {
  /// Default locale code (e.g., "en")
  default_locale : String
  /// Available locales
  locales : Array[LocaleConfig]
}

///| Default i18n configuration (English only)
pub fn I18nConfig::default() -> I18nConfig {
  {
    default_locale: "en",
    locales: [LocaleConfig::{ code: "en", label: "English", path: "" }],
  }
}

///| Locale configuration
pub(all) struct LocaleConfig {
  /// Locale code (e.g., "en", "ja", "fr")
  code : String
  /// Display label (e.g., "English", "日本語")
  label : String
  /// URL path prefix (empty for default locale)
  path : String
} derive(ToJson, FromJson)

///| Default SSG configuration
pub fn SsgConfig::default() -> SsgConfig {
  {
    docs_dir: "docs",
    output_dir: "dist",
    title: "Documentation",
    base_url: "/",
    nav: [],
    sidebar: SidebarConfig::Auto,
    islands: [],
    theme: ThemeConfig::default(),
    i18n: I18nConfig::default(),
  }
}

///| Navigation item for top navbar
pub(all) struct NavItem {
  /// Display text
  text : String
  /// Link URL
  link : String
  /// Dropdown items (optional)
  items : Array[NavItem]
} derive(ToJson, FromJson)

///| Default empty NavItem
pub fn NavItem::new(text : String, link : String) -> NavItem {
  { text, link, items: [] }
}

///| Sidebar configuration
pub(all) enum SidebarConfig {
  /// Auto-generate from directory structure
  Auto
  /// Manual sidebar definition
  Manual(Array[SidebarGroup])
}

///| Sidebar group
pub(all) struct SidebarGroup {
  /// Group title
  text : String
  /// Whether collapsed by default
  collapsed : Bool
  /// Items in the group
  items : Array[SidebarItem]
} derive(ToJson, FromJson)

///| Sidebar item
pub(all) enum SidebarItem {
  /// Link to a page
  Link(text~ : String, link~ : String)
  /// Nested group
  Group(SidebarGroup)
} derive(ToJson, FromJson)

///| Theme configuration
pub(all) struct ThemeConfig {
  /// Primary color (hex)
  primary_color : String?
  /// Logo URL
  logo : String?
  /// Footer configuration
  footer : FooterConfig?
}

///| Default theme configuration
pub fn ThemeConfig::default() -> ThemeConfig {
  { primary_color: Some("#3451b2"), logo: None, footer: None }
}

///| Footer configuration
pub(all) struct FooterConfig {
  /// Footer message
  message : String?
  /// Copyright text
  copyright : String?
} derive(ToJson, FromJson)

// =============================================================================
// Frontmatter Types
// =============================================================================

///| Frontmatter parsed from markdown file
pub(all) struct Frontmatter {
  /// Page title
  title : String?
  /// Page description (for meta tag)
  description : String?
  /// Layout type (default, doc, home)
  layout : String?
  /// Show sidebar
  sidebar : Bool
  /// Table of contents depth
  outline : OutlineConfig?
  /// Additional islands for this page
  islands : Array[String]
  /// Previous page link
  prev : NavLink?
  /// Next page link
  next : NavLink?
}

///| Default frontmatter
pub fn Frontmatter::default() -> Frontmatter {
  {
    title: None,
    description: None,
    layout: None,
    sidebar: true,
    outline: None,
    islands: [],
    prev: None,
    next: None,
  }
}

///| Outline (table of contents) configuration
pub(all) struct OutlineConfig {
  /// Minimum heading level (default: 2)
  level_min : Int
  /// Maximum heading level (default: 3)
  level_max : Int
} derive(ToJson, FromJson)

///| Navigation link for prev/next
pub(all) struct NavLink {
  /// Display text
  text : String
  /// Link URL
  link : String
} derive(ToJson, FromJson)

// =============================================================================
// Page Metadata Types
// =============================================================================

///| Page metadata for routing and generation
pub(all) struct PageMeta {
  /// Source file path (relative to docs_dir)
  source_path : String
  /// Output URL path
  url_path : String
  /// Parsed frontmatter
  frontmatter : Frontmatter
  /// Last modified timestamp (ISO 8601)
  last_modified : String?
  /// Locale code for this page
  locale : String
  /// URL path without locale prefix (for finding translations)
  canonical_path : String
}

///| Create PageMeta from source path
pub fn PageMeta::new(
  source_path : String,
  url_path : String,
  locale~ : String = "en",
  canonical_path~ : String = ""
) -> PageMeta {
  let canonical = if canonical_path.is_empty() { url_path } else { canonical_path }
  {
    source_path,
    url_path,
    frontmatter: Frontmatter::default(),
    last_modified: None,
    locale,
    canonical_path: canonical,
  }
}

///| Set frontmatter
pub fn PageMeta::with_frontmatter(self : PageMeta, fm : Frontmatter) -> PageMeta {
  { ..self, frontmatter: fm }
}

// =============================================================================
// Markdown AST Types
// =============================================================================

///| Markdown node types
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
  /// Island component directive
  Island(IslandEmbed)
  /// Horizontal rule
  ThematicBreak
  /// Line break
  LineBreak
}

///| Island embedding in markdown
pub(all) struct IslandEmbed {
  /// Island component name
  name : String
  /// Props as JSON string
  props : String
  /// Hydration trigger
  trigger : @luna.Trigger
}

///| Default Island embed
pub fn IslandEmbed::new(name : String) -> IslandEmbed {
  { name, props: "{}", trigger: @luna.Load }
}

// =============================================================================
// Build Context
// =============================================================================

///| Build context for site generation
pub(all) struct BuildContext {
  /// SSG configuration
  config : SsgConfig
  /// All pages in the site
  pages : Array[PageMeta]
  /// Auto-generated sidebar
  sidebar : Array[SidebarGroup]
  /// Current working directory
  cwd : String
}

///| Create new build context
pub fn BuildContext::new(config : SsgConfig, cwd : String) -> BuildContext {
  { config, pages: [], sidebar: [], cwd }
}
