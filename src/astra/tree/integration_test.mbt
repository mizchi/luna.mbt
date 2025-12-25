// Integration tests for DocumentTree with MemFS

///|
/// Helper to create a minimal SsgConfig for testing
fn create_test_config() -> @astra.SsgConfig {
  @astra.SsgConfig::{
    title: "Test Documentation",
    base_url: "https://example.com/",
    docs_dir: "docs",
    output_dir: "dist",
    trailing_slash: true,
    i18n: @astra.I18nConfig::{
      default_locale: "en",
      locales: [@astra.LocaleConfig::{ code: "en", label: "English", path: "" }],
    },
    nav: [],
    sidebar: @astra.SidebarConfig::Auto,
    theme: @astra.ThemeConfig::default(),
    ogp: @astra.OgpConfig::default(),
    exclude: [],
    navigation: @astra.NavigationConfig::default(),
    islands: None,
    ogp_text: None,
    head_snippets: [],
    body_snippets: [],
    sanitize_html: false,
    deploy_target: @astra.DeployTarget::default(),
  }
}

///|
/// Helper to create PageMeta for testing
fn create_page_meta(
  source_path : String,
  url_path : String,
  title : String,
  last_modified : String,
) -> @astra.PageMeta {
  @astra.PageMeta::{
    source_path,
    url_path,
    content_type: @astra.Markdown,
    canonical_path: url_path,
    locale: "en",
    sort_key: source_path,
    last_modified: Some(last_modified),
    frontmatter: @astra.Frontmatter::{
      title: Some(title),
      description: None,
      layout: None,
      sidebar: true,
      outline: None,
      islands: [],
      prev: None,
      next: None,
      image: None,
      og_type: None,
      twitter_card: None,
      ssr: false,
    },
  }
}

///|
test "build_document_tree_with_fs - builds tree from PageMeta" {
  let fs = @fs_adapter.MemFSAdapter::new()
  // Create PageMeta array (file content is not read due to async issues)
  let pages = [
    create_page_meta("index.md", "/", "Home", "2024-12-22T12:00:00.000Z"),
    create_page_meta(
      "guide/intro.md", "/guide/intro/", "Getting Started", "2024-12-21T10:00:00.000Z",
    ),
  ]
  // Build DocumentTree
  let config = create_test_config()
  let tree = build_document_tree_with_fs(fs, config, pages, "/project")
  // Verify tree structure
  inspect(tree.site.title, content="Test Documentation")
  inspect(tree.pages.length(), content="2")
  // Verify pages are created from metadata (headings are empty since files are not read)
  let home_page = tree.get_page("index")
  inspect(home_page is Some(_), content="true")
  inspect(home_page.unwrap().title, content="Home")
  inspect(home_page.unwrap().headings.length(), content="0")
  let guide_page = tree.get_page("guide-intro")
  inspect(guide_page is Some(_), content="true")
  inspect(guide_page.unwrap().title, content="Getting Started")
  inspect(guide_page.unwrap().headings.length(), content="0")
}

///|
test "build_document_tree_with_fs - generates valid sitemap" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  let content =
    #|# Test Page
    #|
    #|Content here.
  fs.memfs().writeFileSync("/project/docs/index.md", content)
  let pages = [
    create_page_meta("index.md", "/", "Home", "2024-12-22T12:00:00.000Z"),
  ]
  let config = create_test_config()
  let tree = build_document_tree_with_fs(fs, config, pages, "/project")
  // Generate sitemap
  let sitemap = generate_sitemap(tree)
  // Verify sitemap content
  inspect(sitemap.contains("<?xml version=\"1.0\""), content="true")
  inspect(sitemap.contains("<urlset"), content="true")
  inspect(sitemap.contains("<loc>https://example.com/</loc>"), content="true")
  inspect(sitemap.contains("<lastmod>2024-12-22</lastmod>"), content="true")
}

///|
test "build_document_tree_with_fs - generates valid rss" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  let content =
    #|# Test Page
    #|
    #|Content here.
  fs.memfs().writeFileSync("/project/docs/index.md", content)
  let pages = [
    create_page_meta("index.md", "/", "Home", "2024-12-22T12:00:00.000Z"),
  ]
  let config = create_test_config()
  let tree = build_document_tree_with_fs(fs, config, pages, "/project")
  // Generate RSS
  let rss = generate_rss(tree)
  // Verify RSS content
  inspect(rss.contains("<?xml version=\"1.0\""), content="true")
  inspect(rss.contains("<rss version=\"2.0\""), content="true")
  inspect(rss.contains("<title>Test Documentation</title>"), content="true")
  inspect(rss.contains("<link>https://example.com/</link>"), content="true")
  inspect(rss.contains("<title>Home</title>"), content="true")
}

///|
test "build_document_tree_with_fs - generates valid llms.txt" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let pages = [
    create_page_meta("index.md", "/", "Home", "2024-12-22T12:00:00.000Z"),
  ]
  let config = create_test_config()
  let tree = build_document_tree_with_fs(fs, config, pages, "/project")
  // Generate llms.txt
  let llms = generate_llms_txt(tree)
  // Verify llms.txt content (content_md is empty since files are not read)
  inspect(llms.has_prefix("# Test Documentation"), content="true")
  inspect(llms.contains("## Table of Contents"), content="true")
  inspect(llms.contains("- [Home](/)"), content="true")
}

///|
test "build_document_tree_with_fs - handles missing files gracefully" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  // Don't create the actual file - test graceful handling
  let pages = [
    create_page_meta(
      "missing.md", "/missing/", "Missing", "2024-12-22T12:00:00.000Z",
    ),
  ]
  let config = create_test_config()
  let tree = build_document_tree_with_fs(fs, config, pages, "/project")
  // Should still build tree with empty content
  inspect(tree.pages.length(), content="1")
  let page = tree.get_page("missing")
  inspect(page is Some(_), content="true")
  inspect(page.unwrap().content_md, content="") // Empty content for missing file
  inspect(page.unwrap().headings.length(), content="0")
}

///|
test "build_document_tree_with_fs - multiple pages with nested structure" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs/guide", recursive=true)
  let index_content =
    #|# Home
  let intro_content =
    #|# Introduction
  let advanced_content =
    #|# Advanced Topics
    #|
    #|## Deep Dive
  fs.memfs().writeFileSync("/project/docs/index.md", index_content)
  fs.memfs().writeFileSync("/project/docs/guide/intro.md", intro_content)
  fs.memfs().writeFileSync("/project/docs/guide/advanced.md", advanced_content)
  let pages = [
    create_page_meta("index.md", "/", "Home", "2024-12-22T12:00:00.000Z"),
    create_page_meta(
      "guide/intro.md", "/guide/intro/", "Introduction", "2024-12-21T10:00:00.000Z",
    ),
    create_page_meta(
      "guide/advanced.md", "/guide/advanced/", "Advanced Topics", "2024-12-20T08:00:00.000Z",
    ),
  ]
  let config = create_test_config()
  let tree = build_document_tree_with_fs(fs, config, pages, "/project")
  // Verify all pages
  inspect(tree.pages.length(), content="3")
  // Verify tree structure
  let page_ids = tree.root.flatten()
  inspect(page_ids.length(), content="3")
  inspect(page_ids.contains("index"), content="true")
  inspect(page_ids.contains("guide-intro"), content="true")
  inspect(page_ids.contains("guide-advanced"), content="true")
  // Generate outputs and verify they include all pages
  let sitemap = generate_sitemap(tree)
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
