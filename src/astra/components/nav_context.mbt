// NavContext - Tree-based navigation context for components
//
// Computes navigation data from DocumentTree for efficient rendering
// of sidebar, breadcrumb, and prev/next components.

// =============================================================================
// Types
// =============================================================================

///|
/// Navigation context computed from DocumentTree
/// Pre-computes all navigation-related data for a specific page
pub(all) struct NavContext {
  /// The document tree
  tree : @ssg.DocumentTree
  /// Current page info (None for non-existent pages)
  current_page : @ssg.PageInfo?
  /// Path from root to current page (for breadcrumb)
  /// Each item is (name, url_path) tuple
  breadcrumb_path : Array[(String, String)]
  /// Previous page in document order
  prev_page : @ssg.PageInfo?
  /// Next page in document order
  next_page : @ssg.PageInfo?
  /// Current locale
  locale : String
}

///|
/// Sidebar item for tree-based rendering
pub(all) enum SidebarNode {
  /// Link to a page
  Link(text~ : String, url~ : String, active~ : Bool)
  /// Section with children
  Section(
    text~ : String,
    url~ : String?,
    collapsed~ : Bool,
    active~ : Bool,
    children~ : Array[SidebarNode]
  )
}

// =============================================================================
// NavContext Builder
// =============================================================================

///|
/// Build NavContext for a specific page URL
pub fn NavContext::build(
  tree : @ssg.DocumentTree,
  current_url : String,
  locale? : String = "en",
) -> NavContext {
  // Find current page
  let current_page = tree.get_page_by_url(current_url)

  // Build breadcrumb path
  let breadcrumb_path = build_breadcrumb_path(tree, current_url)

  // Find prev/next pages
  let (prev_page, next_page) = find_siblings(tree, current_url, locale)
  { tree, current_page, breadcrumb_path, prev_page, next_page, locale }
}

///|
/// Build breadcrumb path from root to current URL
fn build_breadcrumb_path(
  tree : @ssg.DocumentTree,
  current_url : String,
) -> Array[(String, String)] {
  let path : Array[(String, String)] = []

  // Parse URL into segments
  let url = current_url.trim_start(chars="/").trim_end(chars="/").to_string()
  if url.is_empty() {
    return path
  }
  let segments = split_path(url)
  let mut accumulated = ""
  for segment in segments {
    accumulated = accumulated + "/" + segment
    let url_with_slash = accumulated + "/"

    // Find page title for this path
    let title = match tree.get_page_by_url(url_with_slash) {
      Some(page) =>
        if page.title.is_empty() {
          format_segment(segment)
        } else {
          page.title
        }
      None => format_segment(segment)
    }
    path.push((title, url_with_slash))
  }
  path
}

///|
/// Find previous and next pages in document order
fn find_siblings(
  tree : @ssg.DocumentTree,
  current_url : String,
  locale : String,
) -> (@ssg.PageInfo?, @ssg.PageInfo?) {
  // Get all pages in tree order (flattened)
  let page_ids = tree.root.flatten()

  // Build ordered list of pages for the locale
  let ordered_pages : Array[@ssg.PageInfo] = []
  for id in page_ids {
    match tree.get_page(id) {
      Some(page) => if page.locale == locale { ordered_pages.push(page) }
      None => ()
    }
  }

  // Find current page index
  let mut current_idx = -1
  for i = 0; i < ordered_pages.length(); i = i + 1 {
    if ordered_pages[i].url_path == current_url {
      current_idx = i
      break
    }
  }
  if current_idx < 0 {
    return (None, None)
  }
  let prev = if current_idx > 0 {
    Some(ordered_pages[current_idx - 1])
  } else {
    None
  }
  let next = if current_idx < ordered_pages.length() - 1 {
    Some(ordered_pages[current_idx + 1])
  } else {
    None
  }
  (prev, next)
}

// =============================================================================
// Sidebar Tree Builder
// =============================================================================

///|
/// Build sidebar tree from DocumentTree
pub fn build_sidebar_tree(
  tree : @ssg.DocumentTree,
  current_url : String,
  locale : String,
) -> Array[SidebarNode] {
  build_sidebar_from_node(tree, tree.root, current_url, locale)
}

///|
/// Recursively build sidebar from TreeNode
fn build_sidebar_from_node(
  tree : @ssg.DocumentTree,
  node : @ssg.TreeNode,
  current_url : String,
  locale : String,
) -> Array[SidebarNode] {
  match node {
    @ssg.TreeNode::Section(children~, ..) => {
      let result : Array[SidebarNode] = []
      for child in children {
        match child {
          @ssg.TreeNode::Page(page_id~, ..) =>
            match tree.get_page(page_id) {
              Some(page) =>
                if page.locale == locale {
                  let active = page.url_path == current_url
                  result.push(
                    SidebarNode::Link(
                      text=page.title,
                      url=page.url_path,
                      active~,
                    ),
                  )
                }
              None => ()
            }
          @ssg.TreeNode::Section(name~, path~, children=sub_children) => {
            // Check if this section or any child is active
            let active = is_path_active(current_url, path)

            // Find section index page
            let section_url : String? = find_section_index(
              tree, sub_children, locale,
            )

            // Build children
            let child_nodes = build_sidebar_from_node(
              tree, child, current_url, locale,
            )

            // Format section name
            let text = format_segment(name)
            result.push(
              SidebarNode::Section(
                text~,
                url=section_url,
                collapsed=false,
                active~,
                children=child_nodes,
              ),
            )
          }
        }
      }
      result
    }
    @ssg.TreeNode::Page(page_id~, ..) =>
      match tree.get_page(page_id) {
        Some(page) =>
          if page.locale == locale {
            let active = page.url_path == current_url
            [SidebarNode::Link(text=page.title, url=page.url_path, active~)]
          } else {
            []
          }
        None => []
      }
  }
}

///|
/// Check if current URL is within a path
fn is_path_active(current_url : String, section_path : String) -> Bool {
  current_url.has_prefix(section_path)
}

///|
/// Find index page for a section
fn find_section_index(
  tree : @ssg.DocumentTree,
  children : Array[@ssg.TreeNode],
  locale : String,
) -> String? {
  for child in children {
    match child {
      @ssg.TreeNode::Page(page_id~, ..) =>
        match tree.get_page(page_id) {
          Some(page) =>
            if page.locale == locale && page.url_path.has_suffix("/") {
              // Check if it's an index page (ends with just the section path)
              return Some(page.url_path)
            }
          None => ()
        }
      _ => ()
    }
  }
  None
}

// =============================================================================
// Helpers
// =============================================================================

///|
/// Split path into segments
fn split_path(path : String) -> Array[String] {
  let segments : Array[String] = []
  let chars = path.to_array()
  let mut start = 0
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '/' {
      if i > start {
        segments.push(slice_string(path, start, i))
      }
      start = i + 1
    }
  }
  if start < chars.length() {
    segments.push(slice_string_from(path, start))
  }
  segments
}

///|
/// Slice string from start to end
fn slice_string(s : String, start : Int, end : Int) -> String {
  let arr = s.to_array()
  let chars : Array[Char] = []
  for i = start; i < end && i < arr.length(); i = i + 1 {
    chars.push(arr[i])
  }
  String::from_array(chars)
}

///|
/// Slice string from start to end
fn slice_string_from(s : String, start : Int) -> String {
  let arr = s.to_array()
  let chars : Array[Char] = []
  for i = start; i < arr.length(); i = i + 1 {
    chars.push(arr[i])
  }
  String::from_array(chars)
}

///|
/// Format segment for display (remove number prefix, replace dashes)
fn format_segment(segment : String) -> String {
  // Remove leading number prefix (e.g., "01_" or "01-")
  let mut s = segment
  let chars = s.to_array()
  let mut skip = 0
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] >= '0' && chars[i] <= '9' {
      skip = i + 1
    } else if (chars[i] == '_' || chars[i] == '-') && skip == i {
      skip = i + 1
      break
    } else {
      break
    }
  }
  if skip > 0 && skip < chars.length() {
    s = slice_string_from(s, skip)
  }

  // Replace dashes/underscores with spaces and capitalize
  let result = s.replace(old="-", new=" ").replace(old="_", new=" ")
  capitalize_first(result)
}

///|
/// Capitalize first letter
fn capitalize_first(s : String) -> String {
  if s.is_empty() {
    return s
  }
  let chars = s.to_array()
  let first = chars[0]
  if first >= 'a' && first <= 'z' {
    chars[0] = Int::unsafe_to_char(first.to_int() - 32)
  }
  String::from_array(chars)
}
