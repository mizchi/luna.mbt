// Frontmatter Type Definitions
// Parsed from markdown file's YAML front matter

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
  /// Layout type (default, doc, home, blog, blog-post)
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
  /// Enable server-side rendering for component pages
  ssr : Bool
  /// Renderer for TSX components: "luna" (default) or "react"
  renderer : String?
  /// Prevent search engines from indexing this page
  noindex : Bool
  /// ISR revalidation interval in seconds (0 or None = static)
  revalidate : Int?
  // Blog-specific fields
  /// Publication date (YYYY-MM-DD format)
  date : String?
  /// Author name
  author : String?
  /// Tags for categorization
  tags : Array[String]
  /// Draft flag (hide from listings)
  draft : Bool
  /// Featured post (shown in featured sections)
  featured : Bool
  /// Cover image URL for blog cards
  cover_image : String?
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
    ssr: false,
    renderer: None,
    noindex: false,
    revalidate: None,
    date: None,
    author: None,
    tags: [],
    draft: false,
    featured: false,
    cover_image: None,
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
