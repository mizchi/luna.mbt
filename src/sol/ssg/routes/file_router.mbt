///| File-based Router for SSG
///| Scans docs/ directory and generates routes

// =============================================================================
// String Slice Helpers (safe wrappers)
// =============================================================================

///| Safely slice string from start index
fn slice_from(s : String, start : Int) -> String {
  if start >= s.length() || start < 0 {
    ""
  } else {
    try {
      s[start:].to_string()
    } catch {
      _ => ""
    }
  }
}

///| Safely slice string to end index
fn slice_to(s : String, end : Int) -> String {
  if end <= 0 || end > s.length() {
    s
  } else {
    try {
      s[:end].to_string()
    } catch {
      _ => s
    }
  }
}

///| Safely slice StringView from start index
fn slice_view_from(s : StringView, start : Int) -> String {
  if start >= s.length() || start < 0 {
    ""
  } else {
    try {
      s[start:].to_string()
    } catch {
      _ => ""
    }
  }
}

///| Safely slice StringView to end index
fn slice_view_to(s : StringView, end : Int) -> String {
  if end <= 0 || end > s.length() {
    s.to_string()
  } else {
    try {
      s[:end].to_string()
    } catch {
      _ => s.to_string()
    }
  }
}

// =============================================================================
// Directory Scanning
// =============================================================================

///| Scan docs directory and generate page metadata with i18n support
pub fn scan_docs_dir(
  docs_dir : String,
  cwd : String,
  i18n~ : @ssg.I18nConfig = @ssg.I18nConfig::default()
) -> Array[@ssg.PageMeta] {
  let pages : Array[@ssg.PageMeta] = []
  let full_path = @path.join2(cwd, docs_dir)

  if not(@fs.existsSync(full_path)) {
    return pages
  }

  scan_recursive(full_path, "", docs_dir, cwd, i18n, pages)
  pages
}

///| Recursively scan directory
fn scan_recursive(
  dir_path : String,
  relative_path : String,
  docs_dir : String,
  cwd : String,
  i18n : @ssg.I18nConfig,
  pages : Array[@ssg.PageMeta]
) -> Unit {
  let entries : Array[String] = try {
    @fs.readdirSync(dir_path)
  } catch {
    _ => return
  }

  for entry in entries {
    let entry_path = @path.join2(dir_path, entry)
    let entry_relative = if relative_path.is_empty() {
      entry
    } else {
      relative_path + "/" + entry
    }

    if is_directory(entry_path) {
      // Recurse into subdirectory
      scan_recursive(entry_path, entry_relative, docs_dir, cwd, i18n, pages)
    } else if entry.has_suffix(".md") {
      // Process markdown file
      let source_path = entry_relative

      // Detect locale from path
      let (locale, canonical_path) = detect_locale_from_path(source_path, i18n)
      let url_path = build_localized_url(canonical_path, locale, i18n)

      // Parse frontmatter to get title
      let content : String = try {
        @fs.readFileSync(entry_path).to_string()
      } catch {
        _ => continue
      }

      let (frontmatter, _) = @markdown.parse_markdown(content)

      let page = @ssg.PageMeta::{
        source_path,
        url_path,
        frontmatter,
        last_modified: get_file_mtime(entry_path),
        locale,
        canonical_path,
      }
      pages.push(page)
    }
  }
}

///| Detect locale from file path
/// e.g., "ja/guide/intro.md" -> ("ja", "guide/intro.md")
///       "guide/intro.md" -> ("en", "guide/intro.md")
fn detect_locale_from_path(
  path : String,
  i18n : @ssg.I18nConfig
) -> (String, String) {
  // Check if path starts with a locale directory
  for locale in i18n.locales {
    if locale.path.is_empty() {
      continue
    }
    let prefix = locale.path + "/"
    if path.has_prefix(prefix) {
      let canonical = slice_from(path, prefix.length())
      return (locale.code, file_to_url_path(canonical))
    }
  }
  // No locale prefix found, use default locale
  (i18n.default_locale, file_to_url_path(path))
}

///| Build localized URL path
/// e.g., ("/guide/intro", "ja", config) -> "/ja/guide/intro"
///       ("/guide/intro", "en", config) -> "/guide/intro"
fn build_localized_url(
  canonical_path : String,
  locale : String,
  i18n : @ssg.I18nConfig
) -> String {
  // Find locale config
  for loc in i18n.locales {
    if loc.code == locale {
      if loc.path.is_empty() {
        return canonical_path
      } else {
        if canonical_path == "/" {
          return "/" + loc.path + "/"
        } else {
          return "/" + loc.path + canonical_path
        }
      }
    }
  }
  // Fallback to canonical path
  canonical_path
}

///| Check if path is a directory
fn is_directory(path : String) -> Bool {
  try {
    @fs.statSync(path).isDirectory()
  } catch {
    _ => false
  }
}

///| Convert timestamp to ISO string
extern "js" fn ffi_ms_to_iso(ms : Float) -> String =
  #| (ms) => new Date(ms).toISOString()

///| Get file modification time as ISO string
fn get_file_mtime(path : String) -> String? {
  try {
    let stats = @fs.statSync(path)
    let mtime_ms = stats.mtime_ms()
    Some(ffi_ms_to_iso(mtime_ms))
  } catch {
    _ => None
  }
}

// =============================================================================
// Path Conversion
// =============================================================================

///| Convert file path to URL path
/// docs/guide/getting-started.md -> /guide/getting-started
/// docs/index.md -> /
pub fn file_to_url_path(file_path : String) -> String {
  let path = file_path
    .replace(old=".md", new="")
    .replace(old="\\", new="/") // Windows compatibility

  if path.has_suffix("/index") {
    let trimmed = slice_to(path, path.length() - 6)
    if trimmed.is_empty() {
      "/"
    } else {
      "/" + trimmed + "/"
    }
  } else if path == "index" {
    "/"
  } else {
    "/" + path
  }
}

///| Convert URL path to output file path
/// / -> index.html
/// /guide/intro -> guide/intro/index.html
pub fn url_to_output_path(url_path : String) -> String {
  if url_path == "/" {
    "index.html"
  } else {
    let trimmed = if url_path.has_prefix("/") {
      slice_from(url_path, 1)
    } else {
      url_path
    }
    if trimmed.has_suffix("/") {
      trimmed + "index.html"
    } else {
      trimmed + "/index.html"
    }
  }
}

// =============================================================================
// Page Sorting and Organization
// =============================================================================

///| Sort pages by URL path for consistent ordering
pub fn sort_pages(pages : Array[@ssg.PageMeta]) -> Array[@ssg.PageMeta] {
  // Simple bubble sort for now (pages array is usually small)
  let result = pages.copy()
  let n = result.length()

  for i = 0; i < n - 1; i = i + 1 {
    for j = 0; j < n - i - 1; j = j + 1 {
      if result[j].url_path > result[j + 1].url_path {
        let temp = result[j]
        result[j] = result[j + 1]
        result[j + 1] = temp
      }
    }
  }

  result
}

///| Group pages by directory
pub fn group_pages_by_dir(
  pages : Array[@ssg.PageMeta]
) -> Map[String, Array[@ssg.PageMeta]] {
  let groups : Map[String, Array[@ssg.PageMeta]] = {}

  for page in pages {
    let dir = get_url_dir(page.url_path)
    match groups.get(dir) {
      Some(arr) => arr.push(page)
      None => groups[dir] = [page]
    }
  }

  groups
}

///| Get directory part of URL path (local helper)
fn get_url_dir(url_path : String) -> String {
  let trimmed = if url_path.has_prefix("/") {
    slice_from(url_path, 1)
  } else {
    url_path
  }

  match trimmed.rev_find("/") {
    Some(idx) => "/" + slice_to(trimmed, idx)
    None => "/"
  }
}

// =============================================================================
// Navigation Generation
// =============================================================================

///| Find previous page in sorted pages
pub fn find_prev_page(
  pages : Array[@ssg.PageMeta],
  current_url : String
) -> @ssg.NavLink? {
  let sorted = sort_pages(pages)
  for i, page in sorted {
    if page.url_path == current_url && i > 0 {
      let prev = sorted[i - 1]
      let text = prev.frontmatter.title.unwrap_or(url_to_name(prev.url_path))
      return Some(@ssg.NavLink::{ text, link: prev.url_path })
    }
  }
  None
}

///| Find next page in sorted pages
pub fn find_next_page(
  pages : Array[@ssg.PageMeta],
  current_url : String
) -> @ssg.NavLink? {
  let sorted = sort_pages(pages)
  for i, page in sorted {
    if page.url_path == current_url && i < sorted.length() - 1 {
      let next = sorted[i + 1]
      let text = next.frontmatter.title.unwrap_or(url_to_name(next.url_path))
      return Some(@ssg.NavLink::{ text, link: next.url_path })
    }
  }
  None
}

///| Get page name from URL path (local helper for navigation)
fn url_to_name(url_path : String) -> String {
  let trimmed = url_path.trim_end(chars="/")
  match trimmed.rev_find("/") {
    Some(idx) => {
      let name = slice_view_from(trimmed, idx + 1)
      if name.is_empty() {
        "Home"
      } else {
        capitalize_first(name.replace(old="-", new=" "))
      }
    }
    None =>
      if trimmed == "/" || trimmed.is_empty() {
        "Home"
      } else {
        capitalize_first(trimmed.to_string().replace(old="-", new=" "))
      }
  }
}

///| Capitalize first letter (local helper)
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

// =============================================================================
// I18n Helpers
// =============================================================================

///| Get all pages for a specific locale
pub fn get_pages_for_locale(
  pages : Array[@ssg.PageMeta],
  locale : String
) -> Array[@ssg.PageMeta] {
  pages.filter(fn(p) { p.locale == locale })
}

///| Find translation of a page in another locale
/// Returns the translated page or None if not found
pub fn find_translation(
  pages : Array[@ssg.PageMeta],
  canonical_path : String,
  target_locale : String
) -> @ssg.PageMeta? {
  for page in pages {
    if page.locale == target_locale && page.canonical_path == canonical_path {
      return Some(page)
    }
  }
  None
}

///| Get available translations for a page
pub fn get_available_translations(
  pages : Array[@ssg.PageMeta],
  canonical_path : String,
  i18n : @ssg.I18nConfig
) -> Array[(@ssg.LocaleConfig, @ssg.PageMeta?)] {
  let result : Array[(@ssg.LocaleConfig, @ssg.PageMeta?)] = []
  for locale in i18n.locales {
    let translation = find_translation(pages, canonical_path, locale.code)
    result.push((locale, translation))
  }
  result
}

///| Find fallback page in default locale
pub fn find_fallback_page(
  pages : Array[@ssg.PageMeta],
  canonical_path : String,
  i18n : @ssg.I18nConfig
) -> @ssg.PageMeta? {
  find_translation(pages, canonical_path, i18n.default_locale)
}
