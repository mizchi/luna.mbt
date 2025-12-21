// SSG (Static Site Generator) Type Definitions

// =============================================================================
// Configuration Types
// =============================================================================

///|
/// SSG Configuration from sol.config.json
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
  /// Islands configuration for hydration
  islands : IslandsConfig?
  /// Theme configuration
  theme : ThemeConfig
  /// Navigation configuration
  navigation : @ssg.NavigationConfig
  /// Internationalization configuration
  i18n : @ssg.I18nConfig
  /// Directories to exclude from scanning (e.g., ["internal", "drafts"])
  exclude : Array[String]
  /// Use trailing slashes in URLs (default: true for SSG compatibility)
  trailing_slash : Bool
  /// OGP configuration
  ogp : OgpConfig
}

// I18nConfig, LocaleConfig are defined in core/ssg
// Re-exported for backward compatibility
pub type I18nConfig = @ssg.I18nConfig

pub type LocaleConfig = @ssg.LocaleConfig

///|
/// Default SSG configuration
pub fn SsgConfig::default() -> SsgConfig {
  {
    docs_dir: "docs",
    output_dir: "dist",
    title: "Documentation",
    base_url: "/",
    nav: [],
    sidebar: SidebarConfig::Auto,
    islands: None,
    theme: ThemeConfig::default(),
    navigation: @ssg.NavigationConfig::default(),
    i18n: @ssg.I18nConfig::default(),
    exclude: [],
    trailing_slash: true,
    ogp: OgpConfig::default(),
  }
}

///|
/// Navigation item for top navbar
pub(all) struct NavItem {
  /// Display text
  text : String
  /// Link URL
  link : String
  /// Dropdown items (optional)
  items : Array[NavItem]
} derive(ToJson, FromJson)

///|
/// Default empty NavItem
pub fn NavItem::new(text : String, link : String) -> NavItem {
  { text, link, items: [] }
}

///|
/// Sidebar configuration
pub(all) enum SidebarConfig {
  /// Auto-generate from directory structure
  Auto
  /// Manual sidebar definition
  Manual(Array[SidebarGroup])
}

///|
/// Sidebar group
pub(all) struct SidebarGroup {
  /// Group title
  text : String
  /// Link URL for the group title (from index.md)
  link : String?
  /// Whether collapsed by default
  collapsed : Bool
  /// Items in the group
  items : Array[SidebarItem]
} derive(ToJson, FromJson)

///|
/// Sidebar item
pub(all) enum SidebarItem {
  /// Link to a page
  Link(text~ : String, link~ : String)
  /// Nested group
  Group(SidebarGroup)
} derive(ToJson, FromJson)

// NavigationConfig is defined in core/ssg
pub type NavigationConfig = @ssg.NavigationConfig

///|
/// Theme configuration
pub(all) struct ThemeConfig {
  /// Primary color (hex)
  primary_color : String?
  /// Logo URL
  logo : String?
  /// Footer configuration
  footer : FooterConfig?
  /// Social links (GitHub, Twitter, etc.)
  social_links : Array[SocialLink]
}

///|
/// Social link configuration
pub(all) struct SocialLink {
  /// Icon type: "github", "twitter", "discord", etc.
  icon : String
  /// Link URL
  link : String
} derive(ToJson, FromJson)

///|
/// Default theme configuration
/// Luna theme: Moon-inspired gold color
pub fn ThemeConfig::default() -> ThemeConfig {
  { primary_color: Some("#fbbf24"), logo: None, footer: None, social_links: [] }
}

///|
/// Footer link
pub(all) struct FooterLink {
  /// Link text
  label : String
  /// Link URL
  href : String
} derive(ToJson, FromJson)

///|
/// Footer column (group of links)
pub(all) struct FooterColumn {
  /// Column title
  title : String
  /// Links in this column
  items : Array[FooterLink]
} derive(ToJson, FromJson)

///|
/// Footer configuration
pub(all) struct FooterConfig {
  /// Footer message
  message : String?
  /// Copyright text
  copyright : String?
  /// Footer link columns (Docusaurus-style)
  links : Array[FooterColumn]
} derive(ToJson, FromJson)

///|
/// OGP (Open Graph Protocol) configuration
pub(all) struct OgpConfig {
  /// Site URL for og:url (required for absolute URLs)
  site_url : String?
  /// Default OGP image URL (relative or absolute)
  image : String?
  /// Site Twitter/X handle (e.g., "@mysite")
  twitter_handle : String?
  /// Default Twitter card type (summary, summary_large_image)
  twitter_card : String?
}

///|
/// Default OGP configuration
pub fn OgpConfig::default() -> OgpConfig {
  { site_url: None, image: None, twitter_handle: None, twitter_card: None }
}

///|
/// Islands configuration for SSG (legacy)
pub(all) struct IslandsConfig {
  /// Directory containing island source files (relative to cwd)
  dir : String
  /// Base path for island URLs in generated HTML
  base_path : String
}

///|
/// Default Islands configuration (uses docs/components convention)
pub fn IslandsConfig::default() -> IslandsConfig {
  { dir: "docs/components", base_path: "/components/" }
}

// =============================================================================
// Frontmatter Types
// =============================================================================

///|
/// Frontmatter parsed from markdown file
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
  /// OGP image URL (overrides site default)
  image : String?
  /// OGP type (article, website, etc.)
  og_type : String?
  /// Twitter card type (summary, summary_large_image)
  twitter_card : String?
}

///|
/// Default frontmatter
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
    image: None,
    og_type: None,
    twitter_card: None,
  }
}

///|
/// Outline (table of contents) configuration
pub(all) struct OutlineConfig {
  /// Minimum heading level (default: 2)
  level_min : Int
  /// Maximum heading level (default: 3)
  level_max : Int
} derive(ToJson, FromJson)

///|
/// Navigation link for prev/next
pub(all) struct NavLink {
  /// Display text
  text : String
  /// Link URL
  link : String
} derive(ToJson, FromJson)

// =============================================================================
// Page Metadata Types
// =============================================================================

///|
/// Page metadata for routing and generation
pub(all) struct PageMeta {
  /// Source file path (relative to docs_dir)
  source_path : String
  /// Output URL path (numeric prefixes stripped)
  url_path : String
  /// Parsed frontmatter
  frontmatter : Frontmatter
  /// Last modified timestamp (ISO 8601)
  last_modified : String?
  /// Locale code for this page
  locale : String
  /// URL path without locale prefix (for finding translations)
  canonical_path : String
  /// Sort key for ordering (preserves numeric prefixes like "00_guide/01_intro")
  sort_key : String
}

///|
/// Create PageMeta from source path
pub fn PageMeta::new(
  source_path : String,
  url_path : String,
  locale? : String = "en",
  canonical_path? : String = "",
  sort_key? : String = "",
) -> PageMeta {
  let canonical = if canonical_path.is_empty() {
    url_path
  } else {
    canonical_path
  }
  let key = if sort_key.is_empty() { source_path } else { sort_key }
  {
    source_path,
    url_path,
    frontmatter: Frontmatter::default(),
    last_modified: None,
    locale,
    canonical_path: canonical,
    sort_key: key,
  }
}

///|
/// Set frontmatter
pub fn PageMeta::with_frontmatter(
  self : PageMeta,
  fm : Frontmatter,
) -> PageMeta {
  { ..self, frontmatter: fm }
}

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
  /// Horizontal rule
  ThematicBreak
  /// Line break
  LineBreak
}

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
// Build Context
// =============================================================================

///|
/// Build context for site generation
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

///|
/// Create new build context
pub fn BuildContext::new(config : SsgConfig, cwd : String) -> BuildContext {
  { config, pages: [], sidebar: [], cwd }
}
