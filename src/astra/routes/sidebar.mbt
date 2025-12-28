// Sidebar Generator for SSG
// Auto-generates sidebar from page structure
//
// Uses @ssg for common string operations

// =============================================================================
// Helper Functions (same pattern as transformer.mbt)
// =============================================================================

///|
/// Create a server-side element
fn h(
  tag : String,
  attrs : Array[(String, @luna.Attr[Unit])],
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(tag, attrs, children)
}

///|
/// Create a static attribute
fn attr(key : String, value : String) -> (String, @luna.Attr[Unit]) {
  (key, @luna.attr_static(value))
}

// =============================================================================
// Auto Sidebar Generation
// =============================================================================

///|
/// Generate sidebar from pages automatically (filtered by locale)
/// Supports arbitrary nesting depth
pub fn generate_auto_sidebar(
  pages : Array[@astra.PageMeta],
  locale? : String = "en",
) -> Array[@astra.SidebarGroup] {
  // Filter pages by locale and exclude pages with sidebar: false
  let locale_pages = pages.filter(
    p => p.locale == locale && p.frontmatter.sidebar,
  )

  // Build hierarchical tree structure
  let tree = build_page_tree(locale_pages)

  // Convert tree to sidebar groups
  tree_to_sidebar_groups(tree)
}

///|
/// Represents a node in the page tree
priv struct PageTreeNode {
  sort_key : String
  pages : Array[@astra.PageMeta] // Pages directly in this directory
  children : Map[String, PageTreeNode] // Subdirectories
}

///|
/// Build a hierarchical tree from flat page list
fn build_page_tree(pages : Array[@astra.PageMeta]) -> Map[String, PageTreeNode] {
  let root : Map[String, PageTreeNode] = {}
  for page in pages {
    // Get path segments from canonical_path
    // For index pages (source ends with "index.md"), don't strip last segment
    let is_index = page.source_path.has_suffix("index.md")
    let segments = get_path_segments(page.canonical_path, is_index~)
    if segments.is_empty() {
      // Root page - skip for sidebar (accessible via nav)
      continue
    }

    // Navigate/create tree structure
    let mut current_map = root
    for i = 0; i < segments.length(); i = i + 1 {
      let segment = segments[i]
      let is_last = i == segments.length() - 1
      match current_map.get(segment) {
        Some(node) =>
          if is_last {
            // Add page to this node
            node.pages.push(page)
          } else {
            // Continue down the tree
            current_map = node.children
          }
        None => {
          // Create new node
          let sort_key = get_segment_sort_key(page.sort_key, i)
          let new_node = PageTreeNode::{
            sort_key,
            pages: if is_last {
              [page]
            } else {
              []
            },
            children: {},
          }
          current_map[segment] = new_node
          if not(is_last) {
            current_map = new_node.children
          }
        }
      }
    }
  }
  root
}

///|
/// Get path segments from canonical path
/// For index pages (is_index=true), all segments are directory names
/// For non-index pages, the last segment is the page filename and should be stripped
fn get_path_segments(
  canonical_path : String,
  is_index? : Bool = false,
) -> Array[String] {
  let segments : Array[String] = []
  let trimmed = canonical_path
    .trim_start(chars="/")
    .trim_end(chars="/")
    .to_string()
  if trimmed.is_empty() {
    return segments
  }

  // Split by /
  let chars = trimmed.to_array()
  let mut start = 0
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '/' {
      if i > start {
        segments.push(slice(trimmed, start, i))
      }
      start = i + 1
    }
  }
  // Last segment
  if start < chars.length() {
    segments.push(@utils.slice_from(trimmed, start))
  }

  // For index pages, return all segments (they're all directory names)
  // For non-index pages, remove the last segment (page filename)
  if is_index {
    segments
  } else if segments.length() > 1 {
    // Remove the last segment (page name), keep directory structure
    let dir_segments : Array[String] = []
    for i = 0; i < segments.length() - 1; i = i + 1 {
      dir_segments.push(segments[i])
    }
    dir_segments
  } else {
    // Single segment non-index - this is a top-level page
    segments
  }
}

///|
/// Get sort key for a specific segment depth
fn get_segment_sort_key(full_sort_key : String, depth : Int) -> String {
  let parts : Array[String] = []
  let chars = full_sort_key.to_array()
  let mut start = 0
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '/' {
      if i > start {
        parts.push(slice(full_sort_key, start, i))
      }
      start = i + 1
    }
  }
  if start < chars.length() {
    parts.push(@utils.slice_from(full_sort_key, start))
  }
  if depth < parts.length() {
    parts[depth]
  } else if parts.length() > 0 {
    parts[0]
  } else {
    "zzzzzzzz"
  }
}

///|
/// Convert page tree to sidebar groups (top level)
fn tree_to_sidebar_groups(
  tree : Map[String, PageTreeNode],
) -> Array[@astra.SidebarGroup] {
  let groups : Array[@astra.SidebarGroup] = []

  // Collect and sort nodes
  let nodes : Array[(String, PageTreeNode)] = []
  for name in tree.keys() {
    if tree.get(name) is Some(node) {
      nodes.push((name, node))
    }
  }

  // Sort by sort_key
  let sorted_nodes = sort_tree_nodes(nodes)
  for entry in sorted_nodes {
    let (name, node) = entry
    let group = tree_node_to_sidebar_group(name, node)
    groups.push(group)
  }
  groups
}

///|
/// Sort tree nodes by sort_key
fn sort_tree_nodes(
  nodes : Array[(String, PageTreeNode)],
) -> Array[(String, PageTreeNode)] {
  let result : Array[(String, PageTreeNode)] = []
  for entry in nodes {
    let (_, node) = entry
    let mut pos = result.length()
    for i = 0; i < result.length(); i = i + 1 {
      let (_, existing) = result[i]
      if @ssg.compare_strings_lex(node.sort_key, existing.sort_key) < 0 {
        pos = i
        break
      }
    }
    if pos == result.length() {
      result.push(entry)
    } else {
      result.push(result[result.length() - 1])
      for j = result.length() - 2; j > pos; j = j - 1 {
        result[j] = result[j - 1]
      }
      result[pos] = entry
    }
  }
  result
}

///|
/// Convert a tree node to a SidebarGroup
fn tree_node_to_sidebar_group(
  name : String,
  node : PageTreeNode,
) -> @astra.SidebarGroup {
  let items : Array[@astra.SidebarItem] = []

  // Find index page for group link (source ends with index.md)
  let mut group_link : String? = None
  let mut group_title : String? = None
  for page in node.pages {
    if page.source_path.has_suffix("index.md") {
      group_link = Some(page.url_path)
      group_title = page.frontmatter.title
      break
    }
  }

  // Add pages in this directory (sorted), excluding index pages
  let sorted_pages = sort_pages(node.pages)
  for page in sorted_pages {
    // Skip index pages - they become the group link
    if page.source_path.has_suffix("index.md") {
      continue
    }
    let text = page.frontmatter.title.unwrap_or(get_page_name(page.url_path))
    items.push(@astra.SidebarItem::Link(text~, link=page.url_path))
  }

  // Add child directories as nested groups
  let child_nodes : Array[(String, PageTreeNode)] = []
  for child_name in node.children.keys() {
    if node.children.get(child_name) is Some(child_node) {
      child_nodes.push((child_name, child_node))
    }
  }
  let sorted_children = sort_tree_nodes(child_nodes)
  for entry in sorted_children {
    let (child_name, child_node) = entry
    let nested_group = tree_node_to_sidebar_group(child_name, child_node)
    items.push(@astra.SidebarItem::Group(nested_group))
  }

  // Get group title from index page or generate from name
  let text = group_title.unwrap_or(
    capitalize(name.replace(old="-", new=" ").replace(old="_", new=" ")),
  )
  @astra.SidebarGroup::{ text, link: group_link, collapsed: true, items }
}

///|
/// Slice string from start to end (exclusive)
fn slice(s : String, start : Int, end : Int) -> String {
  let arr = s.to_array()
  let chars : Array[Char] = []
  for i = start; i < end && i < arr.length(); i = i + 1 {
    chars.push(arr[i])
  }
  String::from_array(chars)
}

///|
/// Get sidebar for specific URL path (filtered by locale)
pub fn get_sidebar_for_path(
  config : @astra.SsgConfig,
  pages : Array[@astra.PageMeta],
  url_path : String,
  locale? : String = "en",
) -> Array[@astra.SidebarGroup] {
  match config.sidebar {
    @astra.SidebarConfig::Auto => generate_auto_sidebar(pages, locale~)
    @astra.SidebarConfig::Manual(groups) =>
      // For manual sidebar, find matching path group
      find_sidebar_for_path(groups, url_path)
  }
}

///|
/// Find sidebar groups that match the current path
fn find_sidebar_for_path(
  groups : Array[@astra.SidebarGroup],
  url_path : String,
) -> Array[@astra.SidebarGroup] {
  // For path /guide/intro, look for /guide sidebar
  let dir = get_url_directory(url_path)

  // Try to find exact match first
  for group in groups {
    if group.text == dir || "/" + group.text == dir {
      return [group]
    }
  }

  // Return all groups if no specific match
  groups
}

///|
/// Get directory from URL path
fn get_url_directory(url_path : String) -> String {
  let trimmed = if url_path.has_prefix("/") {
    @utils.slice_from(url_path, 1)
  } else {
    url_path
  }
  match trimmed.find("/") {
    Some(idx) => "/" + @utils.slice_to(trimmed, idx)
    None => "/"
  }
}

///|
/// Get page name from URL path
fn get_page_name(url_path : String) -> String {
  let trimmed = url_path.trim_end(chars="/")
  match trimmed.rev_find("/") {
    Some(idx) => {
      let name = @utils.slice_view_from(trimmed, idx + 1)
      if name.is_empty() {
        "Introduction"
      } else {
        capitalize(name.replace(old="-", new=" "))
      }
    }
    None =>
      if trimmed == "/" || trimmed.is_empty() {
        "Introduction"
      } else {
        capitalize(trimmed.to_string().replace(old="-", new=" "))
      }
  }
}

///|
/// Capitalize first letter
fn capitalize(s : String) -> String {
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

// =============================================================================
// Page Order (for navigation)
// =============================================================================

///|
/// Get flat list of page URLs in sidebar order (supports arbitrary nesting)
pub fn get_sidebar_page_order(
  groups : Array[@astra.SidebarGroup],
) -> Array[String] {
  let urls : Array[String] = []
  for group in groups {
    collect_urls_from_group(group, urls)
  }
  urls
}

///|
/// Recursively collect URLs from a sidebar group
fn collect_urls_from_group(
  group : @astra.SidebarGroup,
  urls : Array[String],
) -> Unit {
  for item in group.items {
    collect_urls_from_item(item, urls)
  }
}

///|
/// Recursively collect URLs from a sidebar item
fn collect_urls_from_item(
  item : @astra.SidebarItem,
  urls : Array[String],
) -> Unit {
  match item {
    @astra.SidebarItem::Link(link~, ..) => urls.push(link)
    @astra.SidebarItem::Group(nested) => collect_urls_from_group(nested, urls)
  }
}

// =============================================================================
// Sidebar Rendering
// =============================================================================

///|
/// Render sidebar to VNode (desktop version with collapse button)
pub fn render_sidebar(
  groups : Array[@astra.SidebarGroup],
  current_path : String,
) -> @luna.Node[Unit] {
  let group_vnodes = groups.map(fn(group) {
    render_sidebar_group(group, current_path)
  })
  let content = h("div", [attr("class", "sidebar-content")], group_vnodes)

  // Collapse button at bottom
  let collapse_btn = h(
    "button",
    [
      attr("class", "sidebar-collapse-btn"),
      attr("type", "button"),
      attr("onclick", "document.body.classList.toggle('sidebar-collapsed')"),
      attr("aria-label", "Toggle sidebar"),
    ],
    [h("span", [attr("class", "collapse-icon")], [])],
  )
  h("aside", [attr("class", "sidebar sidebar-desktop")], [content, collapse_btn])
}

///|
/// Render mobile sidebar dropdown (Docusaurus-style)
pub fn render_mobile_sidebar(
  groups : Array[@astra.SidebarGroup],
  current_path : String,
) -> @luna.Node[Unit] {
  // Find current page title for the dropdown summary
  let current_title = find_current_page_title(groups, current_path)
  let summary = h("summary", [attr("class", "mobile-sidebar-trigger")], [
    h("span", [attr("class", "mobile-sidebar-label")], [
      @luna.text(current_title),
    ]),
    h("span", [attr("class", "mobile-sidebar-arrow")], []),
  ])
  let group_vnodes = groups.map(fn(group) {
    render_sidebar_group(group, current_path)
  })
  let content = h(
    "nav",
    [attr("class", "mobile-sidebar-content")],
    group_vnodes,
  )
  h("details", [attr("class", "mobile-sidebar")], [summary, content])
}

///|
/// Find current page title from sidebar groups (supports arbitrary nesting)
fn find_current_page_title(
  groups : Array[@astra.SidebarGroup],
  current_path : String,
) -> String {
  for group in groups {
    match find_title_in_group(group, current_path) {
      Some(title) => return title
      None => continue
    }
  }
  "Menu"
}

///|
/// Recursively find title in a sidebar group
fn find_title_in_group(
  group : @astra.SidebarGroup,
  current_path : String,
) -> String? {
  for item in group.items {
    match find_title_in_item(item, current_path) {
      Some(title) => return Some(title)
      None => continue
    }
  }
  None
}

///|
/// Recursively find title in a sidebar item
fn find_title_in_item(
  item : @astra.SidebarItem,
  current_path : String,
) -> String? {
  match item {
    @astra.SidebarItem::Link(text~, link~) =>
      if link == current_path ||
        (link.has_suffix("/") && current_path.has_prefix(link)) {
        Some(text)
      } else {
        None
      }
    @astra.SidebarItem::Group(nested) =>
      find_title_in_group(nested, current_path)
  }
}

///|
/// Check if a sidebar item or its children are active
fn is_item_active(item : @astra.SidebarItem, current_path : String) -> Bool {
  match item {
    @astra.SidebarItem::Link(link~, ..) =>
      link == current_path ||
      (link.has_suffix("/") && current_path.has_prefix(link))
    @astra.SidebarItem::Group(nested) => is_group_active(nested, current_path)
  }
}

///|
/// Check if a sidebar group or its children are active
fn is_group_active(group : @astra.SidebarGroup, current_path : String) -> Bool {
  // Check if the group's own link matches
  match group.link {
    Some(link) =>
      if link == current_path ||
        (link.has_suffix("/") && current_path.has_prefix(link)) {
        return true
      }
    None => ()
  }
  // Check children
  group.items.iter().any(fn(item) { is_item_active(item, current_path) })
}

///|
/// Render sidebar group (collapsible with details/summary)
/// Groups with only index.md (no other items) render as simple links
fn render_sidebar_group(
  group : @astra.SidebarGroup,
  current_path : String,
) -> @luna.Node[Unit] {
  // If group has no items (only index.md), render as simple link
  if group.items.is_empty() {
    match group.link {
      Some(link) => {
        let is_active = link == current_path ||
          (link.has_suffix("/") && current_path.has_prefix(link))
        let class_name = if is_active {
          "sidebar-link active"
        } else {
          "sidebar-link"
        }
        return h("a", [attr("href", link), attr("class", class_name)], [
          @luna.text(group.text),
        ])
      }
      None => return @luna.text(group.text)
    }
  }

  // Check if any item in this group or nested groups is active
  let has_active = is_group_active(group, current_path)

  // Only open if has active item (Docusaurus behavior)
  let is_open = has_active

  // Build summary content - link if available, otherwise just text
  let summary_content : Array[@luna.Node[Unit]] = match group.link {
    Some(link) => {
      let is_link_active = link == current_path
      let link_class = if is_link_active {
        "sidebar-group-link active"
      } else {
        "sidebar-group-link"
      }
      [
        h("a", [attr("href", link), attr("class", link_class)], [
          @luna.text(group.text),
        ]),
        h("span", [attr("class", "sidebar-chevron")], []),
      ]
    }
    None =>
      [
        @luna.text(group.text),
        h("span", [attr("class", "sidebar-chevron")], []),
      ]
  }
  let summary = h(
    "summary",
    [attr("class", "sidebar-group-summary")],
    summary_content,
  )
  let item_vnodes = group.items.map(fn(item) {
    render_sidebar_item(item, current_path)
  })
  let items_list = h("ul", [attr("class", "sidebar-items-inner")], item_vnodes)
  // Wrapper for grid animation
  let items_container = h("div", [attr("class", "sidebar-items")], [items_list])

  // Use details element for collapsible behavior
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    attr("class", "sidebar-collapse"),
  ]
  if is_open {
    attrs.push(("open", @luna.attr_static("")))
  }
  h("details", attrs, [summary, items_container])
}

///|
/// Render sidebar item
fn render_sidebar_item(
  item : @astra.SidebarItem,
  current_path : String,
) -> @luna.Node[Unit] {
  match item {
    @astra.SidebarItem::Link(text~, link~) => {
      let is_active = link == current_path ||
        (link.has_suffix("/") && current_path.has_prefix(link))
      let class_name = if is_active {
        "sidebar-link active"
      } else {
        "sidebar-link"
      }
      let link_el = h("a", [attr("href", link), attr("class", class_name)], [
        @luna.text(text),
      ])
      h("li", [], [link_el])
    }
    @astra.SidebarItem::Group(nested) =>
      // Wrap nested groups in <li> for valid HTML
      h("li", [attr("class", "sidebar-nested-group")], [
        render_sidebar_group(nested, current_path),
      ])
  }
}
