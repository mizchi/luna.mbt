// SSG (Static Site Generator) Type Definitions

// =============================================================================
// Deploy Target
// =============================================================================

///|
/// Deploy target for build output
pub(all) enum DeployTarget {
  /// Pure static files (default, works with any host)
  Static
  /// Cloudflare Workers/Pages (generates _routes.json)
  Cloudflare
  /// GitHub Pages (generates .nojekyll, CNAME)
  GithubPages
  /// Vercel (generates vercel.json)
  Vercel
  /// Netlify (generates _headers, _redirects)
  Netlify
  /// Deno Deploy (optional main.ts for SSR)
  Deno
  /// Node.js server
  Node
} derive(Eq, Show)

///|
/// Default deploy target
pub fn DeployTarget::default() -> DeployTarget {
  Static
}

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
  navigation : @ssg_core.NavigationConfig
  /// Internationalization configuration
  i18n : @ssg_core.I18nConfig
  /// Directories to exclude from scanning (e.g., ["internal", "drafts"])
  exclude : Array[String]
  /// Use trailing slashes in URLs (default: true for SSG compatibility)
  trailing_slash : Bool
  /// OGP configuration
  ogp : OgpConfig
  /// Raw OGP meta tags text (optional, added after generated OGP tags)
  ogp_text : String?
  /// Custom HTML snippets to inject at end of <head>
  head_snippets : Array[String]
  /// Custom HTML snippets to inject before </body>
  body_snippets : Array[String]
  /// Custom HTML snippets to inject before </body> (production only)
  prod_body_snippets : Array[String]
  /// Sanitize HTML content from .html files (default: false)
  /// When true, removes potentially dangerous tags like <script>
  sanitize_html : Bool
  /// Deploy target (static, cloudflare, node)
  deploy_target : DeployTarget
  /// SPA routes for client-side routing fallback (e.g., ["/wiki/"])
  /// Requests to /wiki/* will fallback to /wiki/index.html
  spa_routes : Array[String]
  /// Custom components directory (default: "components" in docs_dir)
  /// Convention: header.mbt, footer.mbt, toc.mbt, breadcrumb.mbt, prev_next.mbt
  components_dir : String?
  /// CSS utility extraction configuration
  css_utilities : CssUtilitiesConfig?
  /// Meta files generation configuration (sitemap, feed, llms.txt)
  meta_files : MetaFilesConfig
}

// I18nConfig, LocaleConfig are defined in core/ssg
// Re-exported for backward compatibility

///|
pub type I18nConfig = @ssg_core.I18nConfig

///|
pub type LocaleConfig = @ssg_core.LocaleConfig

///|
pub type RendererType = @ssg_core.RendererType

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
    navigation: @ssg_core.NavigationConfig::default(),
    i18n: @ssg_core.I18nConfig::default(),
    exclude: [],
    trailing_slash: true,
    ogp: OgpConfig::default(),
    ogp_text: None,
    head_snippets: [],
    body_snippets: [],
    prod_body_snippets: [],
    sanitize_html: false,
    deploy_target: DeployTarget::default(),
    spa_routes: [],
    components_dir: None,
    css_utilities: None,
    meta_files: MetaFilesConfig::default(),
  }
}

///|
/// Navigation item for top navbar
pub(all) struct NavItem {
  /// Display text
  text : String
  /// Link URL
  link : String
  /// Icon name (luna, sol, astra, etc.)
  icon : String?
  /// Dropdown items (optional)
  items : Array[NavItem]
} derive(ToJson, FromJson)

///|
/// Default empty NavItem
pub fn NavItem::new(text : String, link : String) -> NavItem {
  { text, link, icon: None, items: [] }
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

///|
pub type NavigationConfig = @ssg_core.NavigationConfig

///|
/// Theme configuration
pub(all) struct ThemeConfig {
  /// Primary color (hex)
  primary_color : String?
  /// Logo URL
  logo : String?
  /// Header configuration
  header : HeaderConfig?
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
  {
    primary_color: Some("#fbbf24"),
    logo: None,
    header: None,
    footer: None,
    social_links: [],
  }
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
  /// Top section elements
  top : Array[FooterElement]
  /// Bottom section elements
  bottom : Array[FooterElement]
} derive(ToJson, FromJson)

// =============================================================================
// Header/Footer Element System
// =============================================================================

///|
/// Header element types for compositional header layout
pub(all) enum HeaderElement {
  /// Site logo or title
  Logo
  /// Navigation links from config.nav
  NavLinks
  /// Search box
  Search
  /// Theme toggle button (dark/light)
  ThemeToggle
  /// Social links (GitHub, Twitter, etc.)
  SocialLinks
  /// Language switcher dropdown
  LangSwitcher
  /// Flexible spacer
  Spacer
  /// Custom component by tag name
  Custom(String)
} derive(Eq, Show, ToJson, FromJson)

///|
/// Footer element types
pub(all) enum FooterElement {
  /// Link columns
  Columns
  /// Footer message
  Message
  /// Copyright text
  Copyright
  /// Social links
  SocialLinks
  /// Custom component by tag name
  Custom(String)
} derive(Eq, Show, ToJson, FromJson)

///|
/// Header configuration with element slots
pub(all) struct HeaderConfig {
  /// Elements in left section
  left : Array[HeaderElement]
  /// Elements in center section
  center : Array[HeaderElement]
  /// Elements in right section
  right : Array[HeaderElement]
  /// Sticky header (fixed on scroll)
  sticky : Bool
} derive(ToJson, FromJson)

///|
/// Default header configuration
pub fn HeaderConfig::default() -> HeaderConfig {
  {
    left: [Logo],
    center: [],
    right: [NavLinks, LangSwitcher, SocialLinks, ThemeToggle],
    sticky: false,
  }
}

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
/// CSS utilities configuration for static extraction and optimization
pub(all) struct CssUtilitiesConfig {
  /// Enable CSS utility extraction from source files (default: true)
  enabled : Bool
  /// Enable per-page CSS splitting (default: false)
  /// When true, extracts CSS per directory/page
  split : Bool
  /// Inline CSS threshold in bytes (default: 4096)
  /// CSS below this size will be inlined in <style> tags
  /// Set to 0 to always use external files
  inline_threshold : Int
  /// Source directories to scan for CSS utilities
  /// Relative to project root (default: ["src"])
  source_dirs : Array[String]
}

///|
/// Default CSS utilities configuration
pub fn CssUtilitiesConfig::default() -> CssUtilitiesConfig {
  { enabled: true, split: false, inline_threshold: 4096, source_dirs: ["src"] }
}

///|
/// Meta files generation configuration
/// Controls generation of sitemap.xml, feed.xml (RSS), and llms.txt
pub(all) struct MetaFilesConfig {
  /// Generate sitemap.xml for SEO (default: true)
  sitemap : Bool
  /// Generate feed.xml (RSS 2.0) for content syndication (default: false)
  feed : Bool
  /// Generate llms.txt for LLM crawlers (default: false)
  llms_txt : Bool
}

///|
/// Default meta files configuration
/// Only sitemap is enabled by default as it's most commonly needed
pub fn MetaFilesConfig::default() -> MetaFilesConfig {
  { sitemap: true, feed: false, llms_txt: false }
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
// Frontmatter Types (re-exported from @frontmatter)
// =============================================================================

///|
pub type Frontmatter = @frontmatter.Frontmatter

///|
pub type OutlineConfig = @frontmatter.OutlineConfig

///|
pub type NavLink = @frontmatter.NavLink

// =============================================================================
// Page Metadata Types
// =============================================================================

///|
/// Content type for source files
pub(all) enum ContentType {
  /// Markdown file (.md)
  Markdown
  /// HTML fragment file (.html)
  Html
  /// Component directory (moon.pkg.json)
  Component
  /// TSX component file (.tsx)
  TsxComponent
  /// MDX file (.mdx) - Markdown with JSX components
  Mdx
} derive(Eq, Show)

///|
/// Page metadata for routing and generation
pub(all) struct PageMeta {
  /// Source file path (relative to docs_dir)
  source_path : String
  /// Output URL path (numeric prefixes stripped)
  url_path : String
  /// Content type (Markdown or Html)
  content_type : ContentType
  /// Renderer type for this page
  renderer_type : @ssg_core.RendererType
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
  content_type? : ContentType = Markdown,
  renderer_type? : @ssg_core.RendererType = @ssg_core.MarkdownRenderer,
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
    content_type,
    renderer_type,
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
// Markdown Types (re-exported from sol/content/markdown)
// =============================================================================

///|
pub type MdNode = @markdown.MdNode

///|
pub type IslandEmbed = @markdown.IslandEmbed

///|
pub type ComponentEmbed = @markdown.ComponentEmbed

///|
pub type JsxComponentEmbed = @markdown.JsxComponentEmbed

///|
pub type MdxAttrValue = @markdown.MdxAttrValue

///|
pub type ClsHints = @markdown.ClsHints

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
  /// Document tree for navigation (built lazily)
  doc_tree : @ssg_core.DocumentTree?
  /// Is development mode (skips prod_body_snippets)
  is_dev : Bool
}

///|
/// Create new build context
pub fn BuildContext::new(config : SsgConfig, cwd : String) -> BuildContext {
  { config, pages: [], sidebar: [], cwd, doc_tree: None, is_dev: false }
}
