// Tests for DocumentTree generators

///|
/// Helper to create a minimal DocumentTree for testing
fn create_test_tree() -> @ssg_core.DocumentTree {
  let site = @ssg_core.SiteInfo::new(
    title="Test Site",
    description="A test documentation site",
    base_url="https://example.com",
    language="en",
    updated_at="2024-12-22T12:00:00.000Z",
  )
  let pages : Array[@ssg_core.PageInfo] = [
    @ssg_core.PageInfo::new(
      id="index",
      url_path="/",
      source_path="index.md",
      title="Home",
      description="Welcome to the test site",
      locale="en",
      updated_at="2024-12-22T12:00:00.000Z",
      content_md="# Welcome\n\nThis is the home page.",
      headings=[@ssg_core.Heading::new(level=1, text="Welcome", id="welcome")],
      sort_key="000_index",
    ),
    @ssg_core.PageInfo::new(
      id="guide-intro",
      url_path="/guide/intro/",
      source_path="guide/intro.md",
      title="Introduction",
      description="Getting started guide",
      locale="en",
      updated_at="2024-12-21T10:00:00.000Z",
      content_md="# Introduction\n\n## Overview\n\nThis is the intro.",
      headings=[
        @ssg_core.Heading::new(level=1, text="Introduction", id="introduction"),
        @ssg_core.Heading::new(level=2, text="Overview", id="overview"),
      ],
      sort_key="001_guide/001_intro",
    ),
    @ssg_core.PageInfo::new(
      id="guide-advanced",
      url_path="/guide/advanced/",
      source_path="guide/advanced.md",
      title="Advanced Topics",
      description="Advanced usage patterns",
      locale="en",
      updated_at="2024-12-20T08:00:00.000Z",
      content_md="# Advanced Topics\n\nAdvanced content here.",
      headings=[
        @ssg_core.Heading::new(level=1, text="Advanced Topics", id="advanced-topics"),
      ],
      sort_key="001_guide/002_advanced",
    ),
  ]
  let root = @ssg_core.TreeNode::Section(name="", path="/", children=[
    @ssg_core.TreeNode::Page(page_id="index", renderer=@ssg.RendererType::MarkdownRenderer),
    @ssg_core.TreeNode::Section(name="guide", path="/guide/", children=[
      @ssg_core.TreeNode::Page(page_id="guide-intro", renderer=@ssg.RendererType::MarkdownRenderer),
      @ssg_core.TreeNode::Page(
        page_id="guide-advanced",
        renderer=@ssg.RendererType::MarkdownRenderer,
      ),
    ]),
  ])
  @ssg_core.DocumentTree::new(site~, pages~, root~)
}

// =============================================================================
// Sitemap Tests
// =============================================================================

///|
test "generate_sitemap - basic structure" {
  let tree = create_test_tree()
  let sitemap = @ssg_core.generate_sitemap(tree)
  // Check XML declaration
  inspect(sitemap.contains("<?xml version=\"1.0\""), content="true")
  // Check urlset element
  inspect(
    sitemap.contains(
      "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">",
    ),
    content="true",
  )
  inspect(sitemap.contains("</urlset>"), content="true")
}

///|
test "generate_sitemap - contains all pages" {
  let tree = create_test_tree()
  let sitemap = @ssg_core.generate_sitemap(tree)
  // Check all URLs are present
  inspect(sitemap.contains("<loc>https://example.com/</loc>"), content="true")
  inspect(
    sitemap.contains("<loc>https://example.com/guide/intro/</loc>"),
    content="true",
  )
  inspect(
    sitemap.contains("<loc>https://example.com/guide/advanced/</loc>"),
    content="true",
  )
}

///|
test "generate_sitemap - includes lastmod" {
  let tree = create_test_tree()
  let sitemap = @ssg_core.generate_sitemap(tree)
  // Check lastmod dates (ISO date only, not full timestamp)
  inspect(sitemap.contains("<lastmod>2024-12-22</lastmod>"), content="true")
  inspect(sitemap.contains("<lastmod>2024-12-21</lastmod>"), content="true")
}

// =============================================================================
// RSS Tests
// =============================================================================

///|
test "generate_rss - basic structure" {
  let tree = create_test_tree()
  let rss = @ssg_core.generate_rss(tree)
  // Check XML declaration
  inspect(rss.contains("<?xml version=\"1.0\""), content="true")
  // Check RSS root element
  inspect(rss.contains("<rss version=\"2.0\""), content="true")
  inspect(rss.contains("</rss>"), content="true")
  // Check channel element
  inspect(rss.contains("<channel>"), content="true")
  inspect(rss.contains("</channel>"), content="true")
}

///|
test "generate_rss - channel metadata" {
  let tree = create_test_tree()
  let rss = @ssg_core.generate_rss(tree)
  // Check channel metadata
  inspect(rss.contains("<title>Test Site</title>"), content="true")
  inspect(rss.contains("<link>https://example.com</link>"), content="true")
  inspect(
    rss.contains("<description>A test documentation site</description>"),
    content="true",
  )
  inspect(rss.contains("<language>en</language>"), content="true")
}

///|
test "generate_rss - contains items" {
  let tree = create_test_tree()
  let rss = @ssg_core.generate_rss(tree)
  // Check items are present
  inspect(rss.contains("<item>"), content="true")
  inspect(rss.contains("</item>"), content="true")
  // Check item content
  inspect(rss.contains("<title>Home</title>"), content="true")
  inspect(rss.contains("<title>Introduction</title>"), content="true")
}

///|
test "generate_rss - items sorted by date" {
  let tree = create_test_tree()
  let rss = @ssg_core.generate_rss(tree)
  // Home (2024-12-22) should appear before Introduction (2024-12-21)
  let home_pos = find_position(rss, "<title>Home</title>")
  let intro_pos = find_position(rss, "<title>Introduction</title>")
  inspect(home_pos < intro_pos, content="true")
}

///|
test "generate_rss - respects limit" {
  let tree = create_test_tree()
  let rss = @ssg_core.generate_rss(tree, limit=1)
  // Should only have 1 item (the most recent one)
  let item_count = count_occurrences(rss, "<item>")
  inspect(item_count, content="1")
}

// =============================================================================
// llms.txt Tests
// =============================================================================

///|
test "generate_llms_txt - header" {
  let tree = create_test_tree()
  let llms = @ssg_core.generate_llms_txt(tree)
  // Check site title as header
  inspect(llms.has_prefix("# Test Site"), content="true")
  // Check description as blockquote
  inspect(llms.contains("> A test documentation site"), content="true")
}

///|
test "generate_llms_txt - table of contents" {
  let tree = create_test_tree()
  let llms = @ssg_core.generate_llms_txt(tree)
  // Check TOC header
  inspect(llms.contains("## Table of Contents"), content="true")
  // Check TOC links
  inspect(llms.contains("- [Home](/)"), content="true")
  inspect(llms.contains("- [Introduction](/guide/intro/)"), content="true")
}

///|
test "generate_llms_txt - page content" {
  let tree = create_test_tree()
  let llms = @ssg_core.generate_llms_txt(tree)
  // Check page sections
  inspect(llms.contains("# Home"), content="true")
  inspect(llms.contains("URL: /"), content="true")
  // Check content is included
  inspect(llms.contains("# Welcome"), content="true")
  inspect(llms.contains("This is the home page."), content="true")
}

///|
test "generate_llms_txt - page outline" {
  let tree = create_test_tree()
  let llms = @ssg_core.generate_llms_txt(tree)
  // Check outline section for pages with headings
  inspect(llms.contains("## Outline"), content="true")
  // Check heading is listed
  inspect(llms.contains("- Introduction"), content="true")
  inspect(llms.contains("- Overview"), content="true")
}

// =============================================================================
// DocumentTree Helper Tests
// =============================================================================

///|
test "DocumentTree::get_page - existing page" {
  let tree = create_test_tree()
  let page = tree.get_page("guide-intro")
  inspect(page is Some(_), content="true")
  inspect(page.unwrap().title, content="Introduction")
}

///|
test "DocumentTree::get_page - non-existing page" {
  let tree = create_test_tree()
  let page = tree.get_page("non-existent")
  inspect(page is None, content="true")
}

///|
test "DocumentTree::get_page_by_url - existing page" {
  let tree = create_test_tree()
  let page = tree.get_page_by_url("/guide/intro/")
  inspect(page is Some(_), content="true")
  inspect(page.unwrap().id, content="guide-intro")
}

///|
test "DocumentTree::get_pages_sorted_by_date - sorted order" {
  let tree = create_test_tree()
  let pages = tree.get_pages_sorted_by_date()
  // Should be sorted newest first
  inspect(pages.length(), content="3")
  inspect(pages[0].id, content="index") // 2024-12-22
  inspect(pages[1].id, content="guide-intro") // 2024-12-21
  inspect(pages[2].id, content="guide-advanced") // 2024-12-20
}

///|
test "DocumentTree::get_pages_sorted_by_date - with limit" {
  let tree = create_test_tree()
  let pages = tree.get_pages_sorted_by_date(limit=2)
  inspect(pages.length(), content="2")
  inspect(pages[0].id, content="index")
  inspect(pages[1].id, content="guide-intro")
}

///|
test "PageInfo::canonical_url" {
  let page = @ssg_core.PageInfo::new(
    id="test",
    url_path="/guide/intro/",
    title="Test",
  )
  inspect(
    page.canonical_url("https://example.com"),
    content="https://example.com/guide/intro/",
  )
  // Should handle trailing slash in base_url
  inspect(
    page.canonical_url("https://example.com/"),
    content="https://example.com/guide/intro/",
  )
}

///|
test "TreeNode::flatten" {
  let tree = create_test_tree()
  let page_ids = tree.root.flatten()
  inspect(page_ids.length(), content="3")
  inspect(page_ids.contains("index"), content="true")
  inspect(page_ids.contains("guide-intro"), content="true")
  inspect(page_ids.contains("guide-advanced"), content="true")
}

// =============================================================================
// Helper Functions for Tests
// =============================================================================

///|
/// Find position of substring in string (for ordering tests)
fn find_position(haystack : String, needle : String) -> Int {
  let needle_chars = needle.to_array()
  let haystack_chars = haystack.to_array()
  let needle_len = needle_chars.length()
  let haystack_len = haystack_chars.length()
  if needle_len > haystack_len {
    return -1
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
      return i
    }
  }
  -1
}

///|
/// Count occurrences of substring
fn count_occurrences(haystack : String, needle : String) -> Int {
  let mut count = 0
  let mut pos = 0
  let needle_chars = needle.to_array()
  let haystack_chars = haystack.to_array()
  let needle_len = needle_chars.length()
  let haystack_len = haystack_chars.length()
  while pos <= haystack_len - needle_len {
    let found = find_position_from_arr(haystack_chars, needle_chars, pos)
    if found >= 0 {
      count = count + 1
      pos = found + 1
    } else {
      break
    }
  }
  count
}

///|
/// Find position starting from offset (array version)
fn find_position_from_arr(
  haystack : Array[Char],
  needle : Array[Char],
  start : Int,
) -> Int {
  let needle_len = needle.length()
  let haystack_len = haystack.length()
  if needle_len > haystack_len - start {
    return -1
  }
  for i = start; i <= haystack_len - needle_len; i = i + 1 {
    let mut found = true
    for j = 0; j < needle_len; j = j + 1 {
      if haystack[i + j] != needle[j] {
        found = false
        break
      }
    }
    if found {
      return i
    }
  }
  -1
}
