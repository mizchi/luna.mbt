// File-based Router for SSG
// Scans docs/ directory and generates routes

// =============================================================================
// String Slice Helpers (safe wrappers)
// =============================================================================

///|
/// Safely slice string from start index
fn slice_from(s : String, start : Int) -> String {
  if start >= s.length() || start < 0 {
    ""
  } else {
    s[start:].to_string() catch {
      _ => ""
    }
  }
}

///|
/// Safely slice string to end index
fn slice_to(s : String, end : Int) -> String {
  if end <= 0 || end > s.length() {
    s
  } else {
    s[:end].to_string() catch {
      _ => s
    }
  }
}

///|
/// Safely slice StringView from start index
fn slice_view_from(s : StringView, start : Int) -> String {
  if start >= s.length() || start < 0 {
    ""
  } else {
    s[start:].to_string() catch {
      _ => ""
    }
  }
}

///|
/// Safely slice StringView to end index
fn _slice_view_to(s : StringView, end : Int) -> String {
  if end <= 0 || end > s.length() {
    s.to_string()
  } else {
    s[:end].to_string() catch {
      _ => s.to_string()
    }
  }
}

// =============================================================================
// Numeric Prefix Handling
// =============================================================================

///|
/// Parse numeric prefix from a path segment (e.g., "00_guide" -> (0, "guide"))
/// Returns (sort_order, stripped_name). If no prefix, returns (max_int, original)
pub fn parse_numeric_prefix(name : String) -> (Int, String) {
  // Look for pattern: digits followed by underscore
  let chars = name.to_array()
  let mut i = 0
  while i < chars.length() && chars[i] >= '0' && chars[i] <= '9' {
    i = i + 1
  }
  // Check if we found digits followed by underscore
  if i > 0 && i < chars.length() && chars[i] == '_' {
    let num_str = slice_to(name, i)
    let stripped = slice_from(name, i + 1)
    let num = parse_int_simple(num_str)
    (num, stripped)
  } else {
    // No valid prefix, use max int so unprefixed items sort last
    (2147483647, name)
  }
}

///|
/// Simple integer parser (positive only)
fn parse_int_simple(s : String) -> Int {
  let mut result = 0
  for c in s {
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - '0'.to_int())
    }
  }
  result
}

///|
/// Strip numeric prefixes from all segments of a path
/// e.g., "00_guide/01_intro.md" -> "guide/intro.md"
pub fn strip_numeric_prefixes(path : String) -> String {
  let segments = path.split("/")
  let stripped : Array[String] = []
  for seg in segments {
    let (_, name) = parse_numeric_prefix(seg.to_string())
    stripped.push(name)
  }
  stripped.join("/")
}

///|
/// Build sort key from path (preserves structure for proper sorting)
/// e.g., "00_guide/01_intro.md" -> "00000000_guide/00000001_intro.md"
pub fn build_sort_key(path : String) -> String {
  let segments = path.split("/")
  let keyed : Array[String] = []
  for seg in segments {
    let (order, name) = parse_numeric_prefix(seg.to_string())
    // Pad to 8 digits for proper string sorting
    let padded = pad_number(order, 8)
    keyed.push(padded + "_" + name)
  }
  keyed.join("/")
}

///|
/// Pad number with leading zeros
pub fn pad_number(n : Int, width : Int) -> String {
  let s = n.to_string()
  if s.length() >= width {
    s
  } else {
    let zeros = width - s.length()
    let mut result = ""
    for i = 0; i < zeros; i = i + 1 {
      result = result + "0"
    }
    result + s
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
  let pages : Array[@astra.PageMeta] = []
  let full_path = @path.join2(cwd, docs_dir)
  if not(@fs.existsSync(full_path)) {
    return pages
  }
  scan_recursive(
    full_path, "", docs_dir, cwd, i18n, exclude, pages, trailing_slash,
  )
  pages
}

///|
/// Recursively scan directory
fn scan_recursive(
  dir_path : String,
  relative_path : String,
  docs_dir : String,
  cwd : String,
  i18n : @astra.I18nConfig,
  exclude : Array[String],
  pages : Array[@astra.PageMeta],
  trailing_slash : Bool,
) -> Unit {
  let entries : Array[String] = @fs.readdirSync(dir_path) catch { _ => return }
  for entry in entries {
    let entry_path = @path.join2(dir_path, entry)
    let entry_relative = if relative_path.is_empty() {
      entry
    } else {
      relative_path + "/" + entry
    }
    if is_directory(entry_path) {
      // Skip excluded directories
      if is_excluded(entry, entry_relative, exclude) {
        continue
      }
      // Recurse into subdirectory
      scan_recursive(
        entry_path,
        entry_relative,
        docs_dir,
        cwd,
        i18n,
        exclude,
        pages,
        trailing_slash,
      )
    } else if entry.has_suffix(".md") {
      // Process markdown file
      let source_path = entry_relative

      // Detect locale from path
      let (locale, canonical_path) = detect_locale_from_path(
        source_path, i18n, trailing_slash~,
      )
      let url_path = build_localized_url(canonical_path, locale, i18n)

      // Build sort key for ordering (preserves numeric prefixes)
      let sort_key = build_sort_key(source_path)

      // Parse frontmatter to get title
      let content : String = @fs.readFileSync(entry_path).to_string() catch {
        _ => continue
      }
      let (frontmatter, _) = @markdown.parse_markdown(content)
      let page = @astra.PageMeta::{
        source_path,
        url_path,
        frontmatter,
        last_modified: get_file_mtime(entry_path),
        locale,
        canonical_path,
        sort_key,
      }
      pages.push(page)
    }
  }
}

///|
/// Detect locale from file path
/// e.g., "ja/guide/intro.md" -> ("ja", "guide/intro.md")
///       "guide/intro.md" -> ("en", "guide/intro.md")
fn detect_locale_from_path(
  path : String,
  i18n : @astra.I18nConfig,
  trailing_slash~ : Bool = true,
) -> (String, String) {
  // Check if path starts with a locale directory
  for locale in i18n.locales {
    if locale.path.is_empty() {
      continue
    }
    let prefix = locale.path + "/"
    if path.has_prefix(prefix) {
      let canonical = slice_from(path, prefix.length())
      return (locale.code, file_to_url_path(canonical, trailing_slash~))
    }
  }
  // No locale prefix found, use default locale
  (i18n.default_locale, file_to_url_path(path, trailing_slash~))
}

///|
/// Build localized URL path
/// e.g., ("/guide/intro", "ja", config) -> "/ja/guide/intro"
///       ("/guide/intro", "en", config) -> "/guide/intro"
fn build_localized_url(
  canonical_path : String,
  locale : String,
  i18n : @astra.I18nConfig,
) -> String {
  // Find locale config
  for loc in i18n.locales {
    if loc.code == locale {
      if loc.path.is_empty() {
        return canonical_path
      } else if canonical_path == "/" {
        return "/" + loc.path + "/"
      } else {
        return "/" + loc.path + canonical_path
      }
    }
  }
  // Fallback to canonical path
  canonical_path
}

///|
/// Check if path is a directory
fn is_directory(path : String) -> Bool {
  @fs.statSync(path).isDirectory() catch {
    _ => false
  }
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

///|
/// Convert timestamp to ISO string
extern "js" fn ffi_ms_to_iso(ms : Float) -> String =
  #| (ms) => new Date(ms).toISOString()

///|
/// Get file modification time as ISO string
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

///|
/// Convert file path to URL path (strips numeric prefixes)
/// 00_guide/01_getting-started.md -> /guide/getting-started/ (with trailing slash)
/// 00_guide/01_getting-started.md -> /guide/getting-started (without trailing slash)
/// docs/index.md -> /
pub fn file_to_url_path(
  file_path : String,
  trailing_slash? : Bool = true,
) -> String {
  // First strip numeric prefixes, then remove .md and handle Windows paths
  let stripped = strip_numeric_prefixes(file_path)
  let path = stripped.replace(old=".md", new="").replace(old="\\", new="/")
  if path.has_suffix("/index") {
    let trimmed = slice_to(path, path.length() - 6)
    if trimmed.is_empty() {
      "/"
    } else if trailing_slash {
      "/" + trimmed + "/"
    } else {
      "/" + trimmed
    }
  } else if path == "index" {
    "/"
  } else if trailing_slash {
    "/" + path + "/"
  } else {
    "/" + path
  }
}

///|
/// Convert URL path to output file path
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

///|
/// Compare two strings with proper lexicographic ordering
/// (Workaround for MoonBit String.compare bug with different length strings)
fn compare_strings_lex(a : String, b : String) -> Int {
  let a_chars = a.to_array()
  let b_chars = b.to_array()
  let min_len = if a_chars.length() < b_chars.length() {
    a_chars.length()
  } else {
    b_chars.length()
  }
  // Compare character by character
  for i = 0; i < min_len; i = i + 1 {
    if a_chars[i] < b_chars[i] {
      return -1
    }
    if a_chars[i] > b_chars[i] {
      return 1
    }
  }
  // If all compared chars equal, shorter string is "less"
  if a_chars.length() < b_chars.length() {
    -1
  } else if a_chars.length() > b_chars.length() {
    1
  } else {
    0
  }
}

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
      if compare_strings_lex(key, existing_key) < 0 {
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

///|
/// Capitalize first letter (local helper)
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
