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
  navigation : @ssg.NavigationConfig
  /// Internationalization configuration
  i18n : @ssg.I18nConfig
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
}

// I18nConfig, LocaleConfig are defined in core/ssg
// Re-exported for backward compatibility

///|
pub type I18nConfig = @ssg.I18nConfig

///|
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
    ogp_text: None,
    head_snippets: [],
    body_snippets: [],
    sanitize_html: false,
    deploy_target: DeployTarget::default(),
    spa_routes: [],
    components_dir: None,
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

///|
pub type NavigationConfig = @ssg.NavigationConfig

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
  renderer_type : @ssg.RendererType
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
  renderer_type? : @ssg.RendererType = @ssg.MarkdownRenderer,
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
  doc_tree : @ssg.DocumentTree?
}

///|
/// Create new build context
pub fn BuildContext::new(config : SsgConfig, cwd : String) -> BuildContext {
  { config, pages: [], sidebar: [], cwd, doc_tree: None }
}
