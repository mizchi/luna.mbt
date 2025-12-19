// Sidebar Generator for SSG
// Auto-generates sidebar from page structure

// Note: slice_from, slice_to, slice_view_from, slice_view_to helpers
// are defined in file_router.mbt (same package)

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
pub fn generate_auto_sidebar(
  pages : Array[@astra.PageMeta],
  locale? : String = "en",
) -> Array[@astra.SidebarGroup] {
  let groups : Array[@astra.SidebarGroup] = []

  // Filter pages by locale first
  let locale_pages = pages.filter(p => p.locale == locale)

  // Group pages by top-level directory (using canonical_path for grouping)
  let page_groups = group_pages_by_canonical_dir(locale_pages)

  // Get directories with their sort keys
  let dir_entries : Array[(String, String)] = [] // (dir, min_sort_key)
  for dir in page_groups.keys() {
    if page_groups.get(dir) is Some(dir_pages) {
      // Get minimum sort key from pages in this directory for ordering
      let min_sort_key = get_dir_sort_key(dir_pages)
      dir_entries.push((dir, min_sort_key))
    }
  }

  // Sort directories by their sort keys
  let sorted_dirs = sort_dir_entries(dir_entries)

  for entry in sorted_dirs {
    let (dir, _) = entry
    if page_groups.get(dir) is Some(dir_pages) {
      let group = create_sidebar_group(dir, dir_pages)
      groups.push(group)
    }
  }
  groups
}

///|
/// Get sort key for a directory from its pages
/// Uses the directory portion of the first page's sort key
fn get_dir_sort_key(pages : Array[@astra.PageMeta]) -> String {
  if pages.is_empty() {
    return "zzzzzzzz" // Sort empty dirs last
  }
  // Get the minimum sort key and extract directory portion
  let mut min_key = pages[0].sort_key
  for page in pages {
    if compare_strings_lex(page.sort_key, min_key) < 0 {
      min_key = page.sort_key
    }
  }
  // Extract directory portion (first segment)
  match min_key.find("/") {
    Some(idx) => slice_to(min_key, idx)
    None => min_key
  }
}

///|
/// Sort directory entries by their sort keys
fn sort_dir_entries(
  entries : Array[(String, String)],
) -> Array[(String, String)] {
  let result : Array[(String, String)] = []
  for entry in entries {
    let (_, key) = entry
    let mut pos = result.length()
    for i = 0; i < result.length(); i = i + 1 {
      let (_, existing_key) = result[i]
      if compare_strings_lex(key, existing_key) < 0 {
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
/// Group pages by canonical directory (locale-independent path)
fn group_pages_by_canonical_dir(
  pages : Array[@astra.PageMeta],
) -> Map[String, Array[@astra.PageMeta]] {
  let groups : Map[String, Array[@astra.PageMeta]] = {}
  for page in pages {
    let dir = get_canonical_dir(page.canonical_path)
    match groups.get(dir) {
      Some(arr) => arr.push(page)
      None => groups[dir] = [page]
    }
  }
  groups
}

///|
/// Get directory from canonical path
fn get_canonical_dir(canonical_path : String) -> String {
  // Remove leading slash
  let trimmed = if canonical_path.has_prefix("/") {
    slice_from(canonical_path, 1)
  } else {
    canonical_path
  }
  // Remove trailing slash
  let trimmed2 = if trimmed.has_suffix("/") {
    slice_to(trimmed, trimmed.length() - 1)
  } else {
    trimmed
  }
  // Find last slash to get directory
  match trimmed2.rev_find("/") {
    Some(idx) => "/" + slice_to(trimmed2, idx)
    None => "/"
  }
}

///|
/// Create sidebar group from pages
fn create_sidebar_group(
  dir : String,
  pages : Array[@astra.PageMeta],
) -> @astra.SidebarGroup {
  // Sort pages within group by sort_key (numeric prefix ordering)
  let sorted = sort_pages(pages)

  // Create items
  let items : Array[@astra.SidebarItem] = []
  for page in sorted {
    let text = page.frontmatter.title.unwrap_or(get_page_name(page.url_path))
    items.push(@astra.SidebarItem::Link(text~, link=page.url_path))
  }

  // Get group title from directory name
  let text = if dir == "/" {
    "Getting Started"
  } else {
    let name = dir.trim_start(chars="/").trim_end(chars="/").to_string()
    capitalize(name.replace(old="-", new=" "))
  }
  @astra.SidebarGroup::{ text, collapsed: false, items }
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
    slice_from(url_path, 1)
  } else {
    url_path
  }
  match trimmed.find("/") {
    Some(idx) => "/" + slice_to(trimmed, idx)
    None => "/"
  }
}

///|
/// Get page name from URL path
fn get_page_name(url_path : String) -> String {
  let trimmed = url_path.trim_end(chars="/")
  match trimmed.rev_find("/") {
    Some(idx) => {
      let name = slice_view_from(trimmed, idx + 1)
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
/// Get flat list of page URLs in sidebar order
pub fn get_sidebar_page_order(
  groups : Array[@astra.SidebarGroup],
) -> Array[String] {
  let urls : Array[String] = []
  for group in groups {
    for item in group.items {
      match item {
        @astra.SidebarItem::Link(link~, ..) => urls.push(link)
        @astra.SidebarItem::Group(nested) =>
          // Recursively get URLs from nested groups
          for nested_item in nested.items {
            match nested_item {
              @astra.SidebarItem::Link(link~, ..) => urls.push(link)
              _ => ()
            }
          }
      }
    }
  }
  urls
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
/// Find current page title from sidebar groups
fn find_current_page_title(
  groups : Array[@astra.SidebarGroup],
  current_path : String,
) -> String {
  for group in groups {
    for item in group.items {
      match item {
        @astra.SidebarItem::Link(text~, link~) =>
          if link == current_path ||
            (link.has_suffix("/") && current_path.has_prefix(link)) {
            return text
          }
        _ => ()
      }
    }
  }
  "Menu"
}

///|
/// Render sidebar group (collapsible with details/summary)
fn render_sidebar_group(
  group : @astra.SidebarGroup,
  current_path : String,
) -> @luna.Node[Unit] {
  // Check if any item in this group is active
  let has_active = group.items
    .iter()
    .any(fn(item) {
      match item {
        @astra.SidebarItem::Link(link~, ..) =>
          link == current_path ||
          (link.has_suffix("/") && current_path.has_prefix(link))
        @astra.SidebarItem::Group(_) => false
      }
    })

  // Open by default if has active item or not collapsed in config
  let is_open = has_active || not(group.collapsed)
  let summary = h("summary", [], [@luna.text(group.text)])
  let item_vnodes = group.items.map(fn(item) {
    render_sidebar_item(item, current_path)
  })
  let items_container = h("ul", [attr("class", "sidebar-items")], item_vnodes)

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
      render_sidebar_group(nested, current_path)
  }
}
