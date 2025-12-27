// DocumentTree Builder
//
// Generic builder for creating DocumentTree from various sources.
// Used by both Astra (from PageMeta) and Sol (from SolRoutes).

// =============================================================================
// Simple Builder
// =============================================================================

///|
/// Page entry for building DocumentTree
/// This is a simplified representation that can be created from various sources.
pub(all) struct PageEntry {
  /// Page identifier
  id : String
  /// URL path (e.g., "/guide/intro/")
  url_path : String
  /// Title
  title : String
  /// Description
  description : String
  /// Locale code (e.g., "en", "ja")
  locale : String
  /// Last modified timestamp (ISO 8601)
  updated_at : String
  /// Sort key for ordering
  sort_key : String
}

///|
/// Site configuration for building DocumentTree
pub(all) struct SiteConfig {
  /// Site title
  title : String
  /// Site description
  description : String
  /// Base URL (e.g., "https://example.com")
  base_url : String
  /// Default language
  language : String
}

///|
/// Build DocumentTree from simple page entries
/// This is the recommended way for Sol to create DocumentTree.
pub fn build_tree_from_entries(
  site : SiteConfig,
  entries : Array[PageEntry],
) -> DocumentTree {
  // Convert entries to PageInfo
  let pages : Array[PageInfo] = []
  let mut latest_update = ""

  for entry in entries {
    if entry.updated_at > latest_update {
      latest_update = entry.updated_at
    }
    pages.push(PageInfo::new(
      id=entry.id,
      url_path=entry.url_path,
      title=entry.title,
      description=entry.description,
      locale=entry.locale,
      updated_at=entry.updated_at,
      sort_key=entry.sort_key,
    ))
  }

  // Build SiteInfo
  let site_info = SiteInfo::new(
    title=site.title,
    description=site.description,
    base_url=site.base_url,
    language=site.language,
    updated_at=latest_update,
  )

  // Build tree structure
  let root = build_tree_node_from_pages(pages, site.language)

  DocumentTree::new(site=site_info, pages~, root~)
}

///|
/// Build TreeNode from PageInfo array
fn build_tree_node_from_pages(
  pages : Array[PageInfo],
  default_locale : String,
) -> TreeNode {
  // Filter to default locale
  let filtered : Array[PageInfo] = []
  for page in pages {
    if page.locale == default_locale {
      filtered.push(page)
    }
  }

  // Sort by sort_key
  filtered.sort_by(fn(a, b) { a.sort_key.compare(b.sort_key) })

  // Build tree
  let children = build_tree_children_from_pages(filtered, "")
  TreeNode::Section(name="", path="/", children~)
}

///|
/// Recursively build tree children
fn build_tree_children_from_pages(
  pages : Array[PageInfo],
  parent_path : String,
) -> Array[TreeNode] {
  let children : Array[TreeNode] = []
  let seen_dirs : Map[String, Bool] = {}

  for page in pages {
    let rel_path = if parent_path == "" {
      page.url_path
    } else if page.url_path.has_prefix(parent_path) {
      page.url_path[parent_path.length():].to_string() catch {
        _ => continue
      }
    } else {
      continue
    }

    // Remove leading slash
    let rel_path = if rel_path.has_prefix("/") {
      rel_path[1:].to_string() catch { _ => rel_path }
    } else {
      rel_path
    }

    // Remove trailing slash
    let rel_path = if rel_path.has_suffix("/") {
      rel_path[:rel_path.length() - 1].to_string() catch { _ => rel_path }
    } else {
      rel_path
    }

    if rel_path == "" {
      // Index page
      children.push(
        TreeNode::Page(page_id=page.id, renderer=page.renderer_type)
      )
    } else if not(rel_path.contains("/")) {
      // Direct child
      children.push(
        TreeNode::Page(page_id=page.id, renderer=page.renderer_type)
      )
    } else {
      // Subdirectory
      let segments = rel_path.split("/").collect()
      let first_segment = segments[0].to_string()
      if not(seen_dirs.contains(first_segment)) {
        seen_dirs[first_segment] = true
        let sub_path = parent_path + "/" + first_segment
        let sub_children = build_tree_children_from_pages(pages, sub_path + "/")
        children.push(
          TreeNode::Section(
            name=first_segment,
            path=sub_path + "/",
            children=sub_children,
          )
        )
      }
    }
  }

  children
}

// =============================================================================
// Helper: URL to ID conversion
// =============================================================================

///|
/// Convert URL path to page ID
/// "/guide/intro/" -> "guide-intro"
pub fn url_to_page_id(url_path : String) -> String {
  let path = if url_path.has_prefix("/") {
    url_path[1:].to_string() catch { _ => url_path }
  } else {
    url_path
  }
  let path = if path.has_suffix("/") {
    path[:path.length() - 1].to_string() catch { _ => path }
  } else {
    path
  }
  if path == "" {
    "index"
  } else {
    path.replace(old="/", new="-")
  }
}
