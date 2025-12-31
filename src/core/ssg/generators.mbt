// SSG Generators
//
// Pure functions to generate sitemap.xml, RSS feed, and llms.txt from DocumentTree.
// These generators are shared between Sol SSG and Sol (SSR).

// =============================================================================
// Sitemap Generator
// =============================================================================

///|
/// Generate sitemap.xml from DocumentTree
pub fn generate_sitemap(tree : DocumentTree) -> String {
  let mut urls = ""
  for page in tree.pages {
    urls = urls + generate_sitemap_url(page, tree.site.base_url)
  }
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n" +
  urls +
  "</urlset>\n"
}

///|
fn generate_sitemap_url(page : PageInfo, base_url : String) -> String {
  let url = page.canonical_url(base_url)
  let lastmod = iso_to_date(page.updated_at)
  "  <url>\n    <loc>" +
  escape_xml(url) +
  "</loc>\n" +
  (if lastmod != "" { "    <lastmod>" + lastmod + "</lastmod>\n" } else { "" }) +
  "  </url>\n"
}

///|
/// Convert ISO 8601 datetime to date only
/// "2024-12-22T12:00:00.000Z" -> "2024-12-22"
fn iso_to_date(iso_date : String) -> String {
  if iso_date.length() >= 10 {
    iso_date[:10].to_string() catch {
      _ => iso_date
    }
  } else {
    iso_date
  }
}

// =============================================================================
// RSS Feed Generator
// =============================================================================

///|
/// Generate RSS 2.0 feed from DocumentTree
pub fn generate_rss(tree : DocumentTree, limit? : Int = 20) -> String {
  let pages = tree.get_pages_sorted_by_date(limit~)
  let mut items = ""
  for page in pages {
    items = items + generate_rss_item(page, tree.site.base_url)
  }
  let rfc822_date = iso_to_rfc822(tree.site.updated_at)
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\">\n  <channel>\n    <title>" +
  escape_xml(tree.site.title) +
  "</title>\n    <link>" +
  escape_xml(tree.site.base_url) +
  "</link>\n    <description>" +
  escape_xml(tree.site.description) +
  "</description>\n    <language>" +
  tree.site.language +
  "</language>\n    <lastBuildDate>" +
  rfc822_date +
  "</lastBuildDate>\n    <atom:link href=\"" +
  escape_xml(tree.site.base_url) +
  "/feed.xml\" rel=\"self\" type=\"application/rss+xml\"/>\n" +
  items +
  "  </channel>\n</rss>\n"
}

///|
fn generate_rss_item(page : PageInfo, base_url : String) -> String {
  let url = page.canonical_url(base_url)
  let rfc822_date = iso_to_rfc822(page.updated_at)
  "    <item>\n      <title>" +
  escape_xml(page.title) +
  "</title>\n      <link>" +
  escape_xml(url) +
  "</link>\n      <description>" +
  escape_xml(page.description) +
  "</description>\n      <pubDate>" +
  rfc822_date +
  "</pubDate>\n      <guid isPermaLink=\"true\">" +
  escape_xml(url) +
  "</guid>\n    </item>\n"
}

///|
/// Convert ISO 8601 datetime to RFC 822 format
/// "2024-12-22T12:00:00.000Z" -> "Sun, 22 Dec 2024 12:00:00 GMT"
fn iso_to_rfc822(iso_date : String) -> String {
  if iso_date == "" {
    return ""
  }
  // Simple conversion (not a complete implementation)
  // Format: YYYY-MM-DDTHH:MM:SS
  if iso_date.length() < 10 {
    return iso_date
  }
  let year = iso_date[:4].to_string() catch { _ => return iso_date }
  let month = iso_date[5:7].to_string() catch { _ => return iso_date }
  let day = iso_date[8:10].to_string() catch { _ => return iso_date }
  let time = if iso_date.length() >= 19 {
    iso_date[11:19].to_string() catch {
      _ => "00:00:00"
    }
  } else {
    "00:00:00"
  }
  let month_name = month_to_name(month)
  // RFC 822: "22 Dec 2024 12:00:00 GMT"
  day + " " + month_name + " " + year + " " + time + " GMT"
}

///|
fn month_to_name(month : String) -> String {
  match month {
    "01" => "Jan"
    "02" => "Feb"
    "03" => "Mar"
    "04" => "Apr"
    "05" => "May"
    "06" => "Jun"
    "07" => "Jul"
    "08" => "Aug"
    "09" => "Sep"
    "10" => "Oct"
    "11" => "Nov"
    "12" => "Dec"
    _ => "Jan"
  }
}

// =============================================================================
// llms.txt Generator
// =============================================================================

///|
/// Generate llms.txt from DocumentTree
/// Reference: https://llmstxt.org/
pub fn generate_llms_txt(tree : DocumentTree) -> String {
  let mut result = ""
  // Header
  result = result + "# " + tree.site.title + "\n\n"
  if tree.site.description != "" {
    result = result + "> " + tree.site.description + "\n\n"
  }
  // Table of contents
  result = result + "## Table of Contents\n\n"
  result = result + generate_toc(tree)
  result = result + "\n---\n\n"
  // Content for each page
  for page in tree.pages {
    if page.locale == tree.site.language {
      result = result + generate_page_content(page)
    }
  }
  result
}

///|
/// Generate table of contents
fn generate_toc(tree : DocumentTree) -> String {
  let mut result = ""
  result = result + generate_toc_node(tree.root, tree, 0)
  result
}

///|
fn generate_toc_node(
  node : TreeNode,
  tree : DocumentTree,
  depth : Int,
) -> String {
  let indent = "  ".repeat(depth)
  match node {
    TreeNode::Page(page_id~, ..) =>
      match tree.get_page(page_id) {
        Some(page) => indent + "- [" + page.title + "](" + page.url_path + ")\n"
        None => ""
      }
    TreeNode::Section(name~, children~, ..) => {
      let mut result = ""
      if name != "" {
        result = result + indent + "- " + name + "\n"
      }
      for child in children {
        result = result + generate_toc_node(child, tree, depth + 1)
      }
      result
    }
  }
}

///|
/// Generate page content
fn generate_page_content(page : PageInfo) -> String {
  let mut result = ""
  // Page title
  result = result + "# " + page.title + "\n\n"
  // URL
  result = result + "URL: " + page.url_path + "\n\n"
  // Description
  if page.description != "" {
    result = result + "> " + page.description + "\n\n"
  }
  // Heading structure
  if page.headings.length() > 0 {
    result = result + "## Outline\n\n"
    for heading in page.headings {
      let indent = "  ".repeat(heading.level - 1)
      result = result + indent + "- " + heading.text + "\n"
    }
    result = result + "\n"
  }
  // Markdown content (strip frontmatter)
  let content = strip_frontmatter(page.content_md)
  if content != "" {
    result = result + "## Content\n\n"
    result = result + content + "\n"
  }
  result = result + "\n---\n\n"
  result
}

///|
/// Strip frontmatter
fn strip_frontmatter(content : String) -> String {
  if not(content.has_prefix("---")) {
    return content
  }
  // Find the second "---"
  let after_first = content[3:].to_string() catch { _ => return content }
  match find_substring(after_first, "---") {
    Some(idx) =>
      after_first[idx + 3:].trim(chars=" \t\n\r").to_string() catch {
        _ => content
      }
    None => content
  }
}

///|
/// Find substring
fn find_substring(haystack : String, needle : String) -> Int? {
  let needle_chars = needle.to_array()
  let haystack_chars = haystack.to_array()
  let needle_len = needle_chars.length()
  let haystack_len = haystack_chars.length()
  if needle_len > haystack_len {
    return None
  }
  for i = 0; i <= haystack_len - needle_len; i = i + 1 {
    let mut found = true
    for j = 0; j < needle_len; j = j + 1 {
      if haystack_chars[i + j] != needle_chars[j] {
        found = false
        break
      }
    }
    if found {
      return Some(i)
    }
  }
  None
}

// =============================================================================
// Utility Functions
// =============================================================================

///|
/// Escape XML special characters
fn escape_xml(s : String) -> String {
  let mut result = ""
  for c in s {
    match c {
      '&' => result = result + "&amp;"
      '<' => result = result + "&lt;"
      '>' => result = result + "&gt;"
      '"' => result = result + "&quot;"
      '\'' => result = result + "&#39;"
      _ => result = result + c.to_string()
    }
  }
  result
}
