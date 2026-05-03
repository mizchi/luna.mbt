// SSG Document Tree Types
//
// Intermediate representation for document trees.
// Scanned from filesystem and can be converted to multiple output formats
// (HTML, RSS, sitemap, llms.txt).
//
// These types are shared between Sol (SSR framework) and Sol SSG.

// =============================================================================
// Core Types
// =============================================================================

///|
/// Root structure representing an entire site
pub(all) struct DocumentTree {
  site : SiteInfo
  pages : Array[PageInfo]
  root : TreeNode
}

///|
/// Site-wide metadata
pub(all) struct SiteInfo {
  title : String
  description : String
  base_url : String
  language : String
  updated_at : String
}

///|
/// Complete information for a single page
pub(all) struct PageInfo {
  // Identifier
  id : String
  url_path : String
  source_path : String
  // Metadata
  title : String
  description : String
  locale : String
  // Renderer
  renderer_type : RendererType
  // Timestamp (ISO 8601)
  updated_at : String
  // Content
  content_md : String
  // Structure
  headings : Array[Heading]
  // Sorting
  sort_key : String
}

///|
/// Tree node representing hierarchical structure
pub(all) enum TreeNode {
  /// Section (corresponds to a directory)
  Section(name~ : String, path~ : String, children~ : Array[TreeNode])
  /// Reference to a page with renderer info
  Page(page_id~ : String, renderer~ : RendererType)
}

///|
/// Heading information (for TOC, llms.txt)
pub(all) struct Heading {
  level : Int
  text : String
  id : String
}

// =============================================================================
// Constructors
// =============================================================================

///|
pub fn SiteInfo::new(
  title~ : String,
  description? : String = "",
  base_url? : String = "",
  language? : String = "en",
  updated_at? : String = "",
) -> SiteInfo {
  { title, description, base_url, language, updated_at }
}

///|
pub fn PageInfo::new(
  id~ : String,
  url_path~ : String,
  source_path? : String = "",
  title? : String = "",
  description? : String = "",
  locale? : String = "en",
  renderer_type? : RendererType = MarkdownRenderer,
  updated_at? : String = "",
  content_md? : String = "",
  headings? : Array[Heading] = [],
  sort_key? : String = "",
) -> PageInfo {
  {
    id,
    url_path,
    source_path,
    title,
    description,
    locale,
    renderer_type,
    updated_at,
    content_md,
    headings,
    sort_key,
  }
}

///|
pub fn Heading::new(level~ : Int, text~ : String, id? : String = "") -> Heading {
  { level, text, id }
}

///|
pub fn DocumentTree::new(
  site~ : SiteInfo,
  pages? : Array[PageInfo] = [],
  root? : TreeNode = TreeNode::Section(name="", path="/", children=[]),
) -> DocumentTree {
  { site, pages, root }
}

// =============================================================================
// DocumentTree Methods
// =============================================================================

///|
/// Get PageInfo by page ID
pub fn DocumentTree::get_page(self : DocumentTree, id : String) -> PageInfo? {
  for page in self.pages {
    if page.id == id {
      return Some(page)
    }
  }
  None
}

///|
/// Get PageInfo by URL path
pub fn DocumentTree::get_page_by_url(
  self : DocumentTree,
  url_path : String,
) -> PageInfo? {
  for page in self.pages {
    if page.url_path == url_path {
      return Some(page)
    }
  }
  None
}

///|
/// Get pages filtered by locale
pub fn DocumentTree::get_pages_by_locale(
  self : DocumentTree,
  locale : String,
) -> Array[PageInfo] {
  let result : Array[PageInfo] = []
  for page in self.pages {
    if page.locale == locale {
      result.push(page)
    }
  }
  result
}

///|
/// Get pages sorted by date (newest first)
pub fn DocumentTree::get_pages_sorted_by_date(
  self : DocumentTree,
  limit? : Int,
) -> Array[PageInfo] {
  let pages = self.pages.copy()
  pages.sort_by(fn(a, b) { b.updated_at.compare(a.updated_at) })
  match limit {
    Some(n) => {
      let result : Array[PageInfo] = []
      for i = 0; i < n && i < pages.length(); i = i + 1 {
        result.push(pages[i])
      }
      result
    }
    None => pages
  }
}

// =============================================================================
// PageInfo Methods
// =============================================================================

///|
/// Generate canonical URL
pub fn PageInfo::canonical_url(self : PageInfo, base_url : String) -> String {
  let base = if base_url.has_suffix("/") {
    base_url[:base_url.length() - 1].to_string() catch {
      _ => base_url
    }
  } else {
    base_url
  }
  base + self.url_path
}

// =============================================================================
// TreeNode Methods
// =============================================================================

///|
/// Flatten TreeNode to array of page IDs
pub fn TreeNode::flatten(self : TreeNode) -> Array[String] {
  let result : Array[String] = []
  self.flatten_into(result)
  result
}

///|
fn TreeNode::flatten_into(self : TreeNode, result : Array[String]) -> Unit {
  match self {
    Page(page_id~, ..) => result.push(page_id)
    Section(children~, ..) =>
      for child in children {
        child.flatten_into(result)
      }
  }
}
