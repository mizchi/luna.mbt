// Tests for scan_docs_dir_with_fs using MemFSAdapter

///|
test "scan_docs_dir_with_fs - empty directory" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project")
  inspect(pages.length(), content="0")
}

///|
test "scan_docs_dir_with_fs - single markdown file" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  let content =
    #|---
    #|title: Introduction
    #|---
    #|# Hello World
    #|
  fs.memfs().writeFileSync("/project/docs/intro.md", content)
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project")
  inspect(pages.length(), content="1")
  inspect(pages[0].url_path, content="/intro/")
  inspect(pages[0].frontmatter.title, content="Some(\"Introduction\")")
}

///|
test "scan_docs_dir_with_fs - nested directories" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs/guide", recursive=true)
  let index_content =
    #|---
    #|title: Home
    #|---
    #|Welcome
    #|
  let guide_content =
    #|---
    #|title: Guide Intro
    #|---
    #|Guide content
    #|
  fs.memfs().writeFileSync("/project/docs/index.md", index_content)
  fs.memfs().writeFileSync("/project/docs/guide/intro.md", guide_content)
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project")
  inspect(pages.length(), content="2")
}

///|
test "scan_docs_dir_with_fs - i18n with filename suffix" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  // English (default locale)
  let en_content =
    #|---
    #|title: Introduction
    #|---
    #|English content
    #|
  // Japanese translation (filename suffix based)
  let ja_content =
    #|---
    #|title: はじめに
    #|---
    #|日本語コンテンツ
    #|
  fs.memfs().writeFileSync("/project/docs/intro.md", en_content)
  fs.memfs().writeFileSync("/project/docs/intro.ja.md", ja_content)
  // I18n config with en as default and ja as additional locale
  let i18n = @astra.I18nConfig::{
    default_locale: "en",
    locales: [
      @astra.LocaleConfig::{ code: "en", label: "English", path: "" },
      @astra.LocaleConfig::{ code: "ja", label: "日本語", path: "ja" },
    ],
  }
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project", i18n~)
  inspect(pages.length(), content="2")
  // Find pages by locale
  let en_page = pages.iter().find_first(fn(p) { p.locale == "en" })
  let ja_page = pages.iter().find_first(fn(p) { p.locale == "ja" })
  inspect(en_page.unwrap().url_path, content="/intro/")
  inspect(ja_page.unwrap().url_path, content="/ja/intro/")
}

///|
test "scan_docs_dir_with_fs - exclude directories" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  fs.memfs().mkdirSync("/project/docs/internal", recursive=true)
  let public_content =
    #|---
    #|title: Public
    #|---
    #|Public content
    #|
  let secret_content =
    #|---
    #|title: Secret
    #|---
    #|Secret content
    #|
  fs.memfs().writeFileSync("/project/docs/public.md", public_content)
  fs.memfs().writeFileSync("/project/docs/internal/secret.md", secret_content)
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project", exclude=["internal"])
  inspect(pages.length(), content="1")
  inspect(pages[0].frontmatter.title, content="Some(\"Public\")")
}

///|
test "scan_docs_dir_with_fs - numeric prefix sorting" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  let second_content =
    #|---
    #|title: Second
    #|---
    #|Second
    #|
  let first_content =
    #|---
    #|title: First
    #|---
    #|First
    #|
  let tenth_content =
    #|---
    #|title: Tenth
    #|---
    #|Tenth
    #|
  fs.memfs().writeFileSync("/project/docs/02_second.md", second_content)
  fs.memfs().writeFileSync("/project/docs/01_first.md", first_content)
  fs.memfs().writeFileSync("/project/docs/10_tenth.md", tenth_content)
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project")
  let sorted = sort_pages(pages)
  inspect(sorted.length(), content="3")
  // Numeric prefixes should be stripped from URL but preserved for sorting
  inspect(sorted[0].url_path, content="/first/")
  inspect(sorted[1].url_path, content="/second/")
  inspect(sorted[2].url_path, content="/tenth/")
}

///|
test "scan_docs_dir_with_fs - html file" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  let html_content = "<h1>Hello World</h1><p>This is raw HTML</p>"
  fs.memfs().writeFileSync("/project/docs/custom.html", html_content)
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project")
  inspect(pages.length(), content="1")
  inspect(pages[0].url_path, content="/custom/")
  inspect(pages[0].content_type, content="Html")
}

///|
test "scan_docs_dir_with_fs - mixed md and html files" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  let md_content =
    #|---
    #|title: Markdown Page
    #|---
    #|# Hello
    #|
  let html_content = "<h1>HTML Page</h1>"
  fs.memfs().writeFileSync("/project/docs/page1.md", md_content)
  fs.memfs().writeFileSync("/project/docs/page2.html", html_content)
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project")
  inspect(pages.length(), content="2")
  let md_page = pages
    .iter()
    .find_first(fn(p) { p.content_type == @astra.Markdown })
  let html_page = pages
    .iter()
    .find_first(fn(p) { p.content_type == @astra.Html })
  inspect(md_page.unwrap().url_path, content="/page1/")
  inspect(html_page.unwrap().url_path, content="/page2/")
}

///|
test "check_duplicate_pages - no duplicates" {
  let pages : Array[@astra.PageMeta] = [
    @astra.PageMeta::new("intro.md", "/intro/", sort_key="intro.md"),
    @astra.PageMeta::new("guide.md", "/guide/", sort_key="guide.md"),
  ]
  let duplicates = check_duplicate_pages(pages)
  inspect(duplicates.length(), content="0")
}

///|
test "check_duplicate_pages - detects duplicates" {
  let pages : Array[@astra.PageMeta] = [
    @astra.PageMeta::new("index.md", "/", sort_key="index.md"),
    @astra.PageMeta::new("index.html", "/", sort_key="index.html"),
  ]
  let duplicates = check_duplicate_pages(pages)
  inspect(duplicates.length(), content="1")
  inspect(duplicates[0].url_path, content="/")
  inspect(duplicates[0].sources.length(), content="2")
}

///|
test "check_duplicate_pages - multiple duplicates in subdirs" {
  let pages : Array[@astra.PageMeta] = [
    @astra.PageMeta::new("guide/index.md", "/guide/", sort_key="guide/index.md"),
    @astra.PageMeta::new(
      "guide/index.html",
      "/guide/",
      sort_key="guide/index.html",
    ),
    @astra.PageMeta::new("about/index.md", "/about/", sort_key="about/index.md"),
    @astra.PageMeta::new(
      "about/index.html",
      "/about/",
      sort_key="about/index.html",
    ),
    @astra.PageMeta::new("unique.md", "/unique/", sort_key="unique.md"),
  ]
  let duplicates = check_duplicate_pages(pages)
  inspect(duplicates.length(), content="2")
}

///|
test "format_duplicate_error" {
  let dup = DuplicatePage::{
    url_path: "/guide/",
    sources: ["guide/index.md", "guide/index.html"],
  }
  let msg = format_duplicate_error(dup)
  inspect(
    msg,
    content="Duplicate content for URL '/guide/': [guide/index.md, guide/index.html]",
  )
}

// =============================================================================
// Dynamic File Route Tests
// =============================================================================

///|
test "scan_docs_dir_with_fs - dynamic file with staticParams" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs/posts", recursive=true)

  // Create dynamic file template
  let template_content =
    #|---
    #|title: Post Template
    #|---
    #|# Post content
    #|
  fs.memfs().writeFileSync("/project/docs/posts/_id_.md", template_content)

  // Create page.json with staticParams
  let page_json =
    #|{
    #|  "staticParams": [
    #|    { "id": "hello-world" },
    #|    { "id": "getting-started" },
    #|    { "id": "advanced" }
    #|  ]
    #|}
  fs.memfs().writeFileSync("/project/docs/posts/page.json", page_json)
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project")
  inspect(pages.length(), content="3")

  // Check URLs are generated correctly
  let urls = pages.map(fn(p) { p.url_path })
  assert_true(urls.contains("/posts/hello-world/"))
  assert_true(urls.contains("/posts/getting-started/"))
  assert_true(urls.contains("/posts/advanced/"))
}

///|
test "scan_docs_dir_with_fs - dynamic file without page.json" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs/posts", recursive=true)

  // Create dynamic file template without page.json
  let template_content =
    #|---
    #|title: Post Template
    #|---
    #|# Post content
    #|
  fs.memfs().writeFileSync("/project/docs/posts/_id_.md", template_content)

  // No page.json - should skip this file
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project")
  inspect(pages.length(), content="0")
}

///|
test "scan_docs_dir_with_fs - catch-all dynamic file" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)

  // Create catch-all dynamic file template
  let template_content =
    #|---
    #|title: Catch All
    #|---
    #|# Content
    #|
  fs.memfs().writeFileSync("/project/docs/___path___.md", template_content)

  // Create page.json with staticParams
  let page_json =
    #|{
    #|  "staticParams": [
    #|    { "path": "guide/intro" },
    #|    { "path": "api/reference" }
    #|  ]
    #|}
  fs.memfs().writeFileSync("/project/docs/page.json", page_json)
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project")
  inspect(pages.length(), content="2")
  let urls = pages.map(fn(p) { p.url_path })
  assert_true(urls.contains("/guide/intro/"))
  assert_true(urls.contains("/api/reference/"))
}

///|
test "scan_docs_dir_with_fs - mixed static and dynamic files" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs/posts", recursive=true)

  // Create static index file
  let index_content =
    #|---
    #|title: Posts Index
    #|---
    #|# All Posts
    #|
  fs.memfs().writeFileSync("/project/docs/posts/index.md", index_content)

  // Create dynamic file template
  let template_content =
    #|---
    #|title: Post Template
    #|---
    #|# Post content
    #|
  fs.memfs().writeFileSync("/project/docs/posts/_slug_.md", template_content)

  // Create page.json with staticParams
  let page_json =
    #|{
    #|  "staticParams": [
    #|    { "slug": "first-post" },
    #|    { "slug": "second-post" }
    #|  ]
    #|}
  fs.memfs().writeFileSync("/project/docs/posts/page.json", page_json)
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project")
  inspect(pages.length(), content="3")

  // Check both static and dynamic pages exist
  let urls = pages.map(fn(p) { p.url_path })
  assert_true(urls.contains("/posts/"))
  assert_true(urls.contains("/posts/first-post/"))
  assert_true(urls.contains("/posts/second-post/"))
}

///|
test "scan_docs_dir_with_fs - noindex frontmatter" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  // Page with noindex: true
  let noindex_content =
    #|---
    #|title: Hidden Page
    #|noindex: true
    #|---
    #|This page should not be indexed
    #|
  // Page without noindex (default: false)
  let indexed_content =
    #|---
    #|title: Public Page
    #|---
    #|This page should be indexed
    #|
  fs.memfs().writeFileSync("/project/docs/hidden.md", noindex_content)
  fs.memfs().writeFileSync("/project/docs/public.md", indexed_content)
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project")
  inspect(pages.length(), content="2")

  // Find pages
  let hidden_page = pages.iter().find_first(fn(p) { p.url_path == "/hidden/" })
  let public_page = pages.iter().find_first(fn(p) { p.url_path == "/public/" })

  // noindex should be parsed correctly
  inspect(hidden_page.unwrap().frontmatter.noindex, content="true")
  inspect(public_page.unwrap().frontmatter.noindex, content="false")
}
