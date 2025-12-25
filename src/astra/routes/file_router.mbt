// File-based Router for SSG
// Scans docs/ directory and generates routes
//
// Uses @ssg for common path operations

// =============================================================================
// Renderer Type Determination
// =============================================================================

///|
/// Determine renderer type from content type and frontmatter
pub fn determine_renderer_type(
  content_type : @astra.ContentType,
  frontmatter : @astra.Frontmatter,
) -> @ssg.RendererType {
  match content_type {
    @astra.Markdown => @ssg.MarkdownRenderer
    @astra.Html => @ssg.HtmlRenderer
    @astra.Component =>
      if frontmatter.ssr {
        @ssg.LunaRenderer
      } else {
        @ssg.ClientOnlyRenderer
      }
    @astra.TsxComponent =>
      if frontmatter.ssr && frontmatter.renderer == Some("react") {
        @ssg.ReactRenderer
      } else {
        @ssg.ClientOnlyRenderer
      }
  }
}

// =============================================================================
// Directory Scanning
// =============================================================================

///|
/// Scan docs directory and generate page metadata with i18n support
pub fn scan_docs_dir(
  docs_dir : String,
  cwd : String,
  i18n? : @astra.I18nConfig = @astra.I18nConfig::default(),
  exclude? : Array[String] = [],
  trailing_slash? : Bool = true,
) -> Array[@astra.PageMeta] {
  let fs = @fs_adapter.NodeFsAdapter::new()
  scan_docs_dir_with_fs(fs, docs_dir, cwd, i18n~, exclude~, trailing_slash~)
}

///|
/// Detect locale from file path - delegates to @ssg
/// e.g., "ja/guide/intro.md" -> ("ja", "guide/intro.md")
///       "guide/intro.md" -> ("en", "guide/intro.md")
fn detect_locale_from_path(
  path : String,
  i18n : @astra.I18nConfig,
  trailing_slash? : Bool = true,
) -> (String, String) {
  @ssg.detect_locale_from_path(path, i18n, trailing_slash~)
}

///|
/// Build localized URL path - delegates to @ssg
/// e.g., ("/guide/intro", "ja", config) -> "/ja/guide/intro"
///       ("/guide/intro", "en", config) -> "/guide/intro"
fn build_localized_url(
  canonical_path : String,
  locale : String,
  i18n : @astra.I18nConfig,
) -> String {
  @ssg.build_localized_url(canonical_path, locale, i18n)
}

///|
/// Check if directory should be excluded
/// Matches against directory name or relative path
fn is_excluded(
  name : String,
  relative_path : String,
  exclude : Array[String],
) -> Bool {
  for pattern in exclude {
    // Match by directory name (e.g., "internal" matches "docs/internal")
    if name == pattern {
      return true
    }
    // Match by relative path (e.g., "internal/drafts" matches exactly)
    if relative_path == pattern {
      return true
    }
    // Match by path prefix (e.g., "internal" matches "internal/foo")
    if relative_path.has_prefix(pattern + "/") {
      return true
    }
  }
  false
}

// =============================================================================
// Path Conversion (re-exports from @ssg)
// =============================================================================

///|
/// Convert file path to URL path (strips numeric prefixes)
/// Delegates to @ssg.file_to_url_path
pub fn file_to_url_path(
  file_path : String,
  trailing_slash? : Bool = true,
) -> String {
  @ssg.file_to_url_path(file_path, trailing_slash~)
}

///|
/// Convert URL path to output file path
/// Delegates to @ssg.url_to_output_path
pub fn url_to_output_path(url_path : String) -> String {
  @ssg.url_to_output_path(url_path)
}

// =============================================================================
// Page Sorting and Organization
// =============================================================================

///|
/// Sort pages by sort_key (numeric prefix ordering)
/// Files with numeric prefixes (e.g., 00_intro) come before those without
pub fn sort_pages(pages : Array[@astra.PageMeta]) -> Array[@astra.PageMeta] {
  // Create new array using insertion sort with custom comparison
  let result : Array[@astra.PageMeta] = []
  for page in pages {
    let key = page.sort_key
    // Find insertion position using custom comparison
    let mut pos = result.length()
    for i = 0; i < result.length(); i = i + 1 {
      let existing_key = result[i].sort_key
      if @ssg.compare_strings_lex(key, existing_key) < 0 {
        pos = i
        break
      }
    }
    // Insert at position
    if pos == result.length() {
      result.push(page)
    } else {
      // Shift elements and insert
      result.push(result[result.length() - 1]) // Make room
      for j = result.length() - 2; j > pos; j = j - 1 {
        result[j] = result[j - 1]
      }
      result[pos] = page
    }
  }
  result
}

///|
/// Group pages by directory
pub fn group_pages_by_dir(
  pages : Array[@astra.PageMeta],
) -> Map[String, Array[@astra.PageMeta]] {
  let groups : Map[String, Array[@astra.PageMeta]] = {}
  for page in pages {
    let dir = get_url_dir(page.url_path)
    match groups.get(dir) {
      Some(arr) => arr.push(page)
      None => groups[dir] = [page]
    }
  }
  groups
}

///|
/// Get directory part of URL path (local helper)
fn get_url_dir(url_path : String) -> String {
  @ssg.get_url_dir(url_path)
}

// =============================================================================
// FileSystem Trait Compatible Scanning
// =============================================================================

///|
/// Scan docs directory using FileSystem trait (for testing with memfs)
pub fn[FS : @env.FileSystem] scan_docs_dir_with_fs(
  filesystem : FS,
  docs_dir : String,
  cwd : String,
  i18n? : @astra.I18nConfig = @astra.I18nConfig::default(),
  exclude? : Array[String] = [],
  trailing_slash? : Bool = true,
) -> Array[@astra.PageMeta] {
  let pages : Array[@astra.PageMeta] = []
  let full_path = join_path_simple(cwd, docs_dir)
  if not(@env.FileSystem::exists_sync(filesystem, full_path)) {
    return pages
  }
  scan_recursive_with_fs(
    filesystem, full_path, "", docs_dir, cwd, i18n, exclude, pages, trailing_slash,
  )
  pages
}

///|
/// Extract parameter name from directory name (for dynamic routes)
/// _slug_ -> Some("slug")
/// _id_ -> Some("id")
/// regular -> None
fn extract_param_name(dir_name : String) -> String? {
  let len = dir_name.length()
  if dir_name.has_prefix("_") && dir_name.has_suffix("_") && len > 2 {
    Some(@ssg.extract_substring(dir_name, 1, len - 1))
  } else {
    None
  }
}

///|
/// Recursively scan directory with FileSystem trait
fn[FS : @env.FileSystem] scan_recursive_with_fs(
  filesystem : FS,
  dir_path : String,
  relative_path : String,
  docs_dir : String,
  cwd : String,
  i18n : @astra.I18nConfig,
  exclude : Array[String],
  pages : Array[@astra.PageMeta],
  trailing_slash : Bool,
) -> Unit {
  let entries : Array[String] = @env.FileSystem::readdir_sync(
    filesystem, dir_path,
  ) catch {
    _ => return
  }
  for entry in entries {
    let entry_path = join_path_simple(dir_path, entry)
    let entry_relative = if relative_path.is_empty() {
      entry
    } else {
      relative_path + "/" + entry
    }
    if is_directory_with_fs(filesystem, entry_path) {
      // Skip excluded directories
      if is_excluded(entry, entry_relative, exclude) {
        continue
      }

      // Check if this is a dynamic parameter directory (_slug_, _id_, etc.)
      match extract_param_name(entry) {
        Some(param_name) => {
          // This is a dynamic route directory
          scan_dynamic_dir_with_fs(
            filesystem, entry_path, entry_relative, param_name, i18n, pages, trailing_slash,
          )
          continue
        }
        None => ()
      }

      // Check if this is a component directory (contains moon.pkg.json)
      let moon_pkg_path = join_path_simple(entry_path, "moon.pkg.json")
      if @env.FileSystem::exists_sync(filesystem, moon_pkg_path) {
        // This is a component directory - treat as a single page
        let page = scan_component_dir_with_fs(
          filesystem, entry_path, entry_relative, i18n, trailing_slash,
        )
        pages.push(page)
        // Don't recurse into component directories
        continue
      }

      // Check if this is a TSX component directory (contains <dirname>.tsx or index.tsx)
      let dir_name = get_basename(entry)
      let tsx_file_path = join_path_simple(entry_path, dir_name + ".tsx")
      let tsx_index_path = join_path_simple(entry_path, "index.tsx")
      if @env.FileSystem::exists_sync(filesystem, tsx_file_path) ||
        @env.FileSystem::exists_sync(filesystem, tsx_index_path) {
        // This is a TSX component directory
        let page = scan_tsx_component_dir_with_fs(
          filesystem, entry_path, entry_relative, i18n, trailing_slash,
        )
        pages.push(page)
        // Don't recurse into TSX component directories
        continue
      }

      // Recurse into subdirectory
      scan_recursive_with_fs(
        filesystem, entry_path, entry_relative, docs_dir, cwd, i18n, exclude, pages,
        trailing_slash,
      )
    } else if entry.has_suffix(".md") || entry.has_suffix(".html") {
      // Process markdown or HTML file
      let source_path = entry_relative
      let content_type : @astra.ContentType = if entry.has_suffix(".html") {
        @astra.Html
      } else {
        @astra.Markdown
      }

      // Detect locale from path
      let (locale, canonical_path) = detect_locale_from_path(
        source_path,
        i18n,
        trailing_slash~,
      )
      let url_path = build_localized_url(canonical_path, locale, i18n)

      // Build sort key for ordering (preserves numeric prefixes)
      let sort_key = @ssg.build_sort_key(source_path)

      // Parse frontmatter for markdown, use default for HTML
      let frontmatter = match content_type {
        @astra.Markdown => {
          let content : String = @env.FileSystem::read_file_sync(
            filesystem, entry_path,
          ) catch {
            _ => continue
          }
          let (fm, _) = @markdown.parse_markdown(content)
          fm
        }
        @astra.Html | @astra.Component | @astra.TsxComponent =>
          @astra.Frontmatter::default()
      }
      let renderer_type = determine_renderer_type(content_type, frontmatter)
      let page = @astra.PageMeta::{
        source_path,
        url_path,
        content_type,
        renderer_type,
        frontmatter,
        last_modified: None, // memfs doesn't provide consistent mtime
        locale,
        canonical_path,
        sort_key,
      }
      pages.push(page)
    }
  }
}

///|
/// Scan a dynamic parameter directory (_slug_, _id_, etc.)
/// Reads page.json for staticParams and generates pages for each param value
fn[FS : @env.FileSystem] scan_dynamic_dir_with_fs(
  filesystem : FS,
  dir_path : String,
  relative_path : String,
  param_name : String,
  i18n : @astra.I18nConfig,
  pages : Array[@astra.PageMeta],
  trailing_slash : Bool,
) -> Unit {
  // Read page.json for static params configuration
  let page_json_path = join_path_simple(dir_path, "page.json")
  let page_config = if @env.FileSystem::exists_sync(filesystem, page_json_path) {
    let content : String = @env.FileSystem::read_file_sync(
      filesystem, page_json_path,
    ) catch {
      _ => ""
    }
    parse_page_json(content)
  } else {
    None
  }

  // Get static params from page.json
  let static_params = match page_config {
    Some(config) => config.static_params
    None => []
  }

  // Find index.md as template
  let index_md_path = join_path_simple(dir_path, "index.md")
  if not(@env.FileSystem::exists_sync(filesystem, index_md_path)) {
    return // No template file
  }

  // Read the template markdown
  let template_content : String = @env.FileSystem::read_file_sync(
    filesystem, index_md_path,
  ) catch {
    _ => return
  }

  // Parse frontmatter from template
  let (base_frontmatter, _) = @markdown.parse_markdown(template_content)

  // Get parent path (without the _slug_ part)
  let parent_path = get_parent_dir(relative_path)

  // Generate a page for each static param
  for param_set in static_params {
    // Get the param value (e.g., {"slug": "hello-world"} -> "hello-world")
    let param_value = match param_set.get(param_name) {
      Some(v) => v
      None => continue // Skip if param not found
    }

    // Build the output path: parent/value/
    let page_relative = if parent_path.is_empty() {
      param_value
    } else {
      parent_path + "/" + param_value
    }

    // Detect locale and build URL
    let (locale, canonical_path) = detect_locale_from_path(
      page_relative,
      i18n,
      trailing_slash~,
    )
    let url_path = build_localized_url(canonical_path, locale, i18n)

    // Ensure trailing slash
    let url_path_normalized = if trailing_slash && not(url_path.has_suffix("/")) {
      url_path + "/"
    } else {
      url_path
    }

    // Create frontmatter with param value available
    // Title can use the param value if not specified
    let title = match base_frontmatter.title {
      Some(t) => Some(t)
      None => Some(@ssg.capitalize_first(param_value.replace(old="-", new=" ")))
    }
    let frontmatter = @astra.Frontmatter::{ ..base_frontmatter, title, }
    let content_type = @astra.ContentType::Markdown
    let renderer_type = determine_renderer_type(content_type, frontmatter)

    // Store param info in source_path for later template processing
    // Format: _slug_/index.md?slug=value
    let source_with_param = relative_path +
      "/index.md?" +
      param_name +
      "=" +
      param_value
    let page = @astra.PageMeta::{
      source_path: source_with_param,
      url_path: url_path_normalized,
      content_type,
      renderer_type,
      frontmatter,
      last_modified: None,
      locale,
      canonical_path,
      sort_key: page_relative,
    }
    pages.push(page)
  }
}

///|
/// Parse page.json and extract configuration
fn parse_page_json(content : String) -> DynamicPageConfig? {
  if content.is_empty() {
    return None
  }
  let json : Json = @json.parse(content.view()) catch { _ => return None }
  guard json is Object(obj) else { return None }

  // Extract staticParams array
  let static_params : Array[Map[String, String]] = match
    obj.get("staticParams") {
    Some(Array(arr)) => {
      let result : Array[Map[String, String]] = []
      for item in arr {
        match item {
          Object(param_obj) => {
            let params : Map[String, String] = {}
            for key in param_obj.keys() {
              match param_obj.get(key) {
                Some(String(v)) => params[key] = v
                _ => ()
              }
            }
            result.push(params)
          }
          _ => ()
        }
      }
      result
    }
    _ => []
  }
  Some(DynamicPageConfig::{ static_params, })
}

///|
/// Configuration for dynamic page generation
priv struct DynamicPageConfig {
  static_params : Array[Map[String, String]]
}

///|
/// Get parent directory path
fn get_parent_dir(path : String) -> String {
  let chars = path.to_array()
  let mut last_slash = -1
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '/' {
      last_slash = i
    }
  }
  if last_slash > 0 {
    String::from_array(chars[0:last_slash])
  } else {
    ""
  }
}

///|
/// Scan a component directory and create PageMeta
fn[FS : @env.FileSystem] scan_component_dir_with_fs(
  filesystem : FS,
  dir_path : String,
  relative_path : String,
  i18n : @astra.I18nConfig,
  trailing_slash : Bool,
) -> @astra.PageMeta {
  // Try to read page.json for metadata
  let page_json_path = join_path_simple(dir_path, "page.json")
  let frontmatter = if @env.FileSystem::exists_sync(filesystem, page_json_path) {
    let content : String = @env.FileSystem::read_file_sync(
      filesystem, page_json_path,
    ) catch {
      _ => ""
    }
    parse_page_json_to_frontmatter(content)
  } else {
    @astra.Frontmatter::default()
  }

  // Build URL path from directory name
  let (locale, canonical_path) = detect_locale_from_path(
    relative_path,
    i18n,
    trailing_slash~,
  )
  let url_path = build_localized_url(canonical_path, locale, i18n)

  // Ensure trailing slash for component directories
  let url_path_normalized = if trailing_slash && not(url_path.has_suffix("/")) {
    url_path + "/"
  } else {
    url_path
  }
  let content_type = @astra.ContentType::Component
  let renderer_type = determine_renderer_type(content_type, frontmatter)
  @astra.PageMeta::{
    source_path: relative_path,
    url_path: url_path_normalized,
    content_type,
    renderer_type,
    frontmatter,
    last_modified: None,
    locale,
    canonical_path,
    sort_key: relative_path,
  }
}

///|
/// Get the basename (last segment) of a path
fn get_basename(path : String) -> String {
  let chars = path.to_array()
  let mut last_slash = -1
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '/' {
      last_slash = i
    }
  }
  if last_slash >= 0 && last_slash < chars.length() - 1 {
    let result : Array[Char] = []
    for i = last_slash + 1; i < chars.length(); i = i + 1 {
      result.push(chars[i])
    }
    String::from_array(result)
  } else {
    path
  }
}

///|
/// Scan a TSX component directory and return PageMeta
fn[FS : @env.FileSystem] scan_tsx_component_dir_with_fs(
  filesystem : FS,
  dir_path : String,
  relative_path : String,
  i18n : @astra.I18nConfig,
  trailing_slash : Bool,
) -> @astra.PageMeta {
  // Try to read page.json for metadata
  let page_json_path = join_path_simple(dir_path, "page.json")
  let frontmatter = if @env.FileSystem::exists_sync(filesystem, page_json_path) {
    let content : String = @env.FileSystem::read_file_sync(
      filesystem, page_json_path,
    ) catch {
      _ => ""
    }
    parse_page_json_to_frontmatter(content)
  } else {
    @astra.Frontmatter::default()
  }

  // Build URL path from directory name
  let (locale, canonical_path) = detect_locale_from_path(
    relative_path,
    i18n,
    trailing_slash~,
  )
  let url_path = build_localized_url(canonical_path, locale, i18n)

  // Ensure trailing slash for component directories
  let url_path_normalized = if trailing_slash && not(url_path.has_suffix("/")) {
    url_path + "/"
  } else {
    url_path
  }
  let content_type = @astra.ContentType::TsxComponent
  let renderer_type = determine_renderer_type(content_type, frontmatter)
  @astra.PageMeta::{
    source_path: relative_path,
    url_path: url_path_normalized,
    content_type,
    renderer_type,
    frontmatter,
    last_modified: None,
    locale,
    canonical_path,
    sort_key: relative_path,
  }
}

///|
/// Parse page.json content to Frontmatter
fn parse_page_json_to_frontmatter(content : String) -> @astra.Frontmatter {
  if content.is_empty() {
    return @astra.Frontmatter::default()
  }
  // Parse JSON and extract relevant fields
  let json : Json = @json.parse(content.view()) catch {
    _ => return @astra.Frontmatter::default()
  }
  guard json is Object(obj) else { return @astra.Frontmatter::default() }
  let title = @json_utils.extract_string_opt(obj, "title")
  let description = @json_utils.extract_string_opt(obj, "description")
  let layout = @json_utils.extract_string_opt(obj, "layout")

  // Parse islands array
  let islands : Array[String] = match obj.get("islands") {
    Some(Array(arr)) => {
      let result : Array[String] = []
      for item in arr {
        match item {
          String(s) => result.push(s)
          _ => ()
        }
      }
      result
    }
    _ => []
  }

  // Parse ssr flag
  let ssr = @json_utils.extract_bool(obj, "ssr", false)

  // Parse renderer option ("luna" or "react")
  let renderer = @json_utils.extract_string_opt(obj, "renderer")
  @astra.Frontmatter::{
    title,
    description,
    layout,
    sidebar: true,
    outline: None,
    islands,
    prev: None,
    next: None,
    image: None,
    og_type: None,
    twitter_card: None,
    ssr,
    renderer,
  }
}

///|
/// Check if path is a directory using FileSystem trait
fn[FS : @env.FileSystem] is_directory_with_fs(
  filesystem : FS,
  path : String,
) -> Bool {
  @env.FileSystem::is_directory_sync(filesystem, path) catch {
    _ => false
  }
}

///|
/// Simple path join (without using @path which requires Node.js)
fn join_path_simple(base : String, name : String) -> String {
  if base.is_empty() {
    name
  } else if base.has_suffix("/") {
    base + name
  } else {
    base + "/" + name
  }
}

// =============================================================================
// Duplicate Detection
// =============================================================================

///|
/// Duplicate page entry for error reporting
pub(all) struct DuplicatePage {
  /// The URL path that has duplicates
  url_path : String
  /// List of source files that map to the same URL
  sources : Array[String]
}

///|
/// Check for duplicate pages (e.g., index.md and index.html in same directory)
/// Returns list of conflicts where multiple source files map to the same URL path
pub fn check_duplicate_pages(
  pages : Array[@astra.PageMeta],
) -> Array[DuplicatePage] {
  let duplicates : Array[DuplicatePage] = []
  let url_to_sources : Map[String, Array[String]] = {}

  // Group pages by URL path
  for page in pages {
    match url_to_sources.get(page.url_path) {
      Some(sources) => sources.push(page.source_path)
      None => url_to_sources[page.url_path] = [page.source_path]
    }
  }

  // Find URLs with multiple sources
  for url in url_to_sources.keys() {
    let sources = url_to_sources.get(url).unwrap()
    if sources.length() > 1 {
      duplicates.push(DuplicatePage::{ url_path: url, sources })
    }
  }
  duplicates
}

///|
/// Format duplicate page error message
pub fn format_duplicate_error(dup : DuplicatePage) -> String {
  let sources = dup.sources.join(", ")
  "Duplicate content for URL '\{dup.url_path}': [\{sources}]"
}

///|
/// Check if a source path is from a dynamic route (contains ? for params)
fn is_dynamic_source(source_path : String) -> Bool {
  source_path.find("?") is Some(_)
}

///|
/// Resolve duplicate pages by giving priority to static paths over dynamic ones
/// Returns the deduplicated array and any unresolvable conflicts
pub fn resolve_duplicate_pages(
  pages : Array[@astra.PageMeta],
) -> (Array[@astra.PageMeta], Array[DuplicatePage]) {
  let url_to_pages : Map[String, Array[@astra.PageMeta]] = {}

  // Group pages by URL path
  for page in pages {
    match url_to_pages.get(page.url_path) {
      Some(arr) => arr.push(page)
      None => url_to_pages[page.url_path] = [page]
    }
  }
  let result : Array[@astra.PageMeta] = []
  let unresolved : Array[DuplicatePage] = []

  // Resolve each URL
  for url in url_to_pages.keys() {
    let page_list = url_to_pages.get(url).unwrap()
    if page_list.length() == 1 {
      // No conflict
      result.push(page_list[0])
    } else {
      // Conflict - try to resolve by priority
      // Static paths (no ?) take priority over dynamic paths (with ?)
      let static_pages : Array[@astra.PageMeta] = []
      let dynamic_pages : Array[@astra.PageMeta] = []
      for p in page_list {
        if is_dynamic_source(p.source_path) {
          dynamic_pages.push(p)
        } else {
          static_pages.push(p)
        }
      }
      if static_pages.length() == 1 {
        // Exactly one static page - use it (priority over dynamic)
        result.push(static_pages[0])
      } else if static_pages.length() == 0 && dynamic_pages.length() > 0 {
        // Only dynamic pages - this shouldn't happen normally, use first
        result.push(dynamic_pages[0])
        if dynamic_pages.length() > 1 {
          let sources = dynamic_pages.map(fn(p) { p.source_path })
          unresolved.push(DuplicatePage::{ url_path: url, sources })
        }
      } else {
        // Multiple static pages or other conflict - can't auto-resolve
        let sources = page_list.map(fn(p) { p.source_path })
        unresolved.push(DuplicatePage::{ url_path: url, sources })
        // Use first static page as fallback
        if static_pages.length() > 0 {
          result.push(static_pages[0])
        } else {
          result.push(page_list[0])
        }
      }
    }
  }
  (result, unresolved)
}

// =============================================================================
// Navigation Generation
// =============================================================================

///|
/// Find previous page in sorted pages
pub fn find_prev_page(
  pages : Array[@astra.PageMeta],
  current_url : String,
) -> @astra.NavLink? {
  let sorted = sort_pages(pages)
  for i, page in sorted {
    if page.url_path == current_url && i > 0 {
      let prev = sorted[i - 1]
      let text = prev.frontmatter.title.unwrap_or(url_to_name(prev.url_path))
      return Some(@astra.NavLink::{ text, link: prev.url_path })
    }
  }
  None
}

///|
/// Find next page in sorted pages
pub fn find_next_page(
  pages : Array[@astra.PageMeta],
  current_url : String,
) -> @astra.NavLink? {
  let sorted = sort_pages(pages)
  for i, page in sorted {
    if page.url_path == current_url && i < sorted.length() - 1 {
      let next = sorted[i + 1]
      let text = next.frontmatter.title.unwrap_or(url_to_name(next.url_path))
      return Some(@astra.NavLink::{ text, link: next.url_path })
    }
  }
  None
}

///|
/// Get page name from URL path (local helper for navigation)
fn url_to_name(url_path : String) -> String {
  let trimmed = url_path.trim_end(chars="/")
  match trimmed.rev_find("/") {
    Some(idx) => {
      let name = @ssg.slice_view_from(trimmed, idx + 1)
      if name.is_empty() {
        "Home"
      } else {
        @ssg.capitalize_first(name.replace(old="-", new=" "))
      }
    }
    None =>
      if trimmed == "/" || trimmed.is_empty() {
        "Home"
      } else {
        @ssg.capitalize_first(trimmed.to_string().replace(old="-", new=" "))
      }
  }
}

// =============================================================================
// I18n Helpers
// =============================================================================

///|
/// Get all pages for a specific locale
pub fn get_pages_for_locale(
  pages : Array[@astra.PageMeta],
  locale : String,
) -> Array[@astra.PageMeta] {
  pages.filter(p => p.locale == locale)
}

///|
/// Find translation of a page in another locale
/// Returns the translated page or None if not found
pub fn find_translation(
  pages : Array[@astra.PageMeta],
  canonical_path : String,
  target_locale : String,
) -> @astra.PageMeta? {
  for page in pages {
    if page.locale == target_locale && page.canonical_path == canonical_path {
      return Some(page)
    }
  }
  None
}

///|
/// Get available translations for a page
pub fn get_available_translations(
  pages : Array[@astra.PageMeta],
  canonical_path : String,
  i18n : @astra.I18nConfig,
) -> Array[(@astra.LocaleConfig, @astra.PageMeta?)] {
  let result : Array[(@astra.LocaleConfig, @astra.PageMeta?)] = []
  for locale in i18n.locales {
    let translation = find_translation(pages, canonical_path, locale.code)
    result.push((locale, translation))
  }
  result
}

///|
/// Find fallback page in default locale
pub fn find_fallback_page(
  pages : Array[@astra.PageMeta],
  canonical_path : String,
  i18n : @astra.I18nConfig,
) -> @astra.PageMeta? {
  find_translation(pages, canonical_path, i18n.default_locale)
}
