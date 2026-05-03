// Whitebox tests for link_validator.mbt

// =============================================================================
// extract_internal_links tests
// =============================================================================

///|
test "extract_internal_links: markdown link to internal page" {
  let links = extract_internal_links("[About](/about/)")
  assert_eq!(links, ["/about/"])
}

///|
test "extract_internal_links: markdown link to external URL ignored" {
  let links = extract_internal_links("[Google](https://google.com)")
  assert_eq!(links.length(), 0)
}

///|
test "extract_internal_links: http external URL ignored" {
  let links = extract_internal_links("[Site](http://example.com)")
  assert_eq!(links.length(), 0)
}

///|
test "extract_internal_links: fragment-only link ignored" {
  let links = extract_internal_links("[Jump](#section)")
  assert_eq!(links.length(), 0)
}

///|
test "extract_internal_links: internal link with anchor strips anchor" {
  let links = extract_internal_links("[Guide](/guide/#getting-started)")
  assert_eq!(links, ["/guide/"])
}

///|
test "extract_internal_links: internal link with query string strips query" {
  let links = extract_internal_links("[Search](/search/?q=foo)")
  assert_eq!(links, ["/search/"])
}

///|
test "extract_internal_links: internal link with both anchor and query" {
  let links = extract_internal_links("[Page](/page/?q=1#section)")
  assert_eq!(links, ["/page/"])
}

///|
test "extract_internal_links: multiple links in content" {
  let content = "See [Guide](/guide/) and [API](/api/) for more."
  let links = extract_internal_links(content)
  assert_eq!(links.length(), 2)
  assert_true!(links.iter().any(fn(l) { l == "/guide/" }))
  assert_true!(links.iter().any(fn(l) { l == "/api/" }))
}

///|
test "extract_internal_links: mixed internal and external links" {
  let content = "Visit [internal](/docs/) or [external](https://example.com)."
  let links = extract_internal_links(content)
  assert_eq!(links.length(), 1)
  assert_eq!(links[0], "/docs/")
}

///|
test "extract_internal_links: HTML href attribute double-quoted" {
  let links = extract_internal_links("<a href=\"/about/\">About</a>")
  assert_eq!(links, ["/about/"])
}

///|
test "extract_internal_links: HTML href attribute single-quoted" {
  let links = extract_internal_links("<a href='/contact/'>Contact</a>")
  assert_eq!(links, ["/contact/"])
}

///|
test "extract_internal_links: HTML href external ignored" {
  let links = extract_internal_links("<a href=\"https://example.com\">Ext</a>")
  assert_eq!(links.length(), 0)
}

///|
test "extract_internal_links: HTML href fragment-only ignored" {
  let links = extract_internal_links("<a href=\"#top\">Top</a>")
  assert_eq!(links.length(), 0)
}

///|
test "extract_internal_links: HTML href with anchor strips anchor" {
  let links = extract_internal_links("<a href=\"/page/#heading\">Page</a>")
  assert_eq!(links, ["/page/"])
}

///|
test "extract_internal_links: empty content returns empty" {
  let links = extract_internal_links("")
  assert_eq!(links.length(), 0)
}

///|
test "extract_internal_links: no links in plain text" {
  let links = extract_internal_links("Just some text without any links here.")
  assert_eq!(links.length(), 0)
}

///|
test "extract_internal_links: mailto link ignored" {
  let links = extract_internal_links("[Email](mailto:test@example.com)")
  assert_eq!(links.length(), 0)
}

///|
test "extract_internal_links: protocol-relative URL ignored" {
  let links = extract_internal_links("[CDN](//cdn.example.com/lib.js)")
  assert_eq!(links.length(), 0)
}

// =============================================================================
// validate_internal_links tests
// =============================================================================

///|
test "validate_internal_links: no broken links returns empty diagnostics" {
  let pages : Array[(String, String)] = [
    ("/index.md", "See [Guide](/guide/) for details."),
  ]
  let known_urls = build_url_set(["/", "/guide/"])
  let diags = validate_internal_links(pages, known_urls)
  assert_eq!(diags.length(), 0)
}

///|
test "validate_internal_links: broken internal link detected" {
  let pages : Array[(String, String)] = [
    ("/index.md", "See [Missing](/missing-page/) for details."),
  ]
  let known_urls = build_url_set(["/"])
  let diags = validate_internal_links(pages, known_urls)
  assert_eq!(diags.length(), 1)
  assert_eq!(diags[0].source_page, "/index.md")
  assert_eq!(diags[0].target_link, "/missing-page/")
  assert_true!(diags[0].message.contains("/missing-page/"))
}

///|
test "validate_internal_links: external links ignored" {
  let pages : Array[(String, String)] = [
    ("/index.md", "[Google](https://google.com) and [GitHub](http://github.com)"),
  ]
  let known_urls = build_url_set(["/"])
  let diags = validate_internal_links(pages, known_urls)
  assert_eq!(diags.length(), 0)
}

///|
test "validate_internal_links: anchor-only links ignored" {
  let pages : Array[(String, String)] = [
    ("/index.md", "Jump to [Section](#intro) and [Top](#top)"),
  ]
  let known_urls = build_url_set(["/"])
  let diags = validate_internal_links(pages, known_urls)
  assert_eq!(diags.length(), 0)
}

///|
test "validate_internal_links: multiple broken links in one page" {
  let pages : Array[(String, String)] = [
    (
      "/index.md",
      "See [A](/broken-a/) and [B](/broken-b/) and [C](/broken-c/)",
    ),
  ]
  let known_urls = build_url_set(["/"])
  let diags = validate_internal_links(pages, known_urls)
  assert_eq!(diags.length(), 3)
  let targets = diags.map(fn(d) { d.target_link })
  assert_true!(targets.iter().any(fn(t) { t == "/broken-a/" }))
  assert_true!(targets.iter().any(fn(t) { t == "/broken-b/" }))
  assert_true!(targets.iter().any(fn(t) { t == "/broken-c/" }))
}

///|
test "validate_internal_links: links with query strings are validated by base path" {
  let pages : Array[(String, String)] = [
    ("/index.md", "See [Search](/search/?q=foo) for details."),
  ]
  // /search/ exists in known URLs
  let known_urls = build_url_set(["/", "/search/"])
  let diags = validate_internal_links(pages, known_urls)
  assert_eq!(diags.length(), 0)
}

///|
test "validate_internal_links: links with query strings fail if base path missing" {
  let pages : Array[(String, String)] = [
    ("/index.md", "See [Search](/search/?q=foo) for details."),
  ]
  // /search/ is NOT in known URLs
  let known_urls = build_url_set(["/"])
  let diags = validate_internal_links(pages, known_urls)
  assert_eq!(diags.length(), 1)
  assert_eq!(diags[0].target_link, "/search/")
}

///|
test "validate_internal_links: links with anchor stripped before check" {
  let pages : Array[(String, String)] = [
    ("/docs.md", "See [Intro](/guide/#intro) for details."),
  ]
  // /guide/ exists but /guide/#intro does not need to
  let known_urls = build_url_set(["/", "/guide/"])
  let diags = validate_internal_links(pages, known_urls)
  assert_eq!(diags.length(), 0)
}

///|
test "validate_internal_links: valid links across multiple pages" {
  let pages : Array[(String, String)] = [
    ("/index.md", "See [Guide](/guide/) for details."),
    ("/guide/index.md", "Back to [Home](/) or read [API](/api/)"),
    ("/api/index.md", "See [Guide](/guide/) too."),
  ]
  let known_urls = build_url_set(["/", "/guide/", "/api/"])
  let diags = validate_internal_links(pages, known_urls)
  assert_eq!(diags.length(), 0)
}

///|
test "validate_internal_links: broken link in second page detected" {
  let pages : Array[(String, String)] = [
    ("/index.md", "See [Guide](/guide/)."),
    ("/guide/index.md", "See [Missing](/does-not-exist/)."),
  ]
  let known_urls = build_url_set(["/", "/guide/"])
  let diags = validate_internal_links(pages, known_urls)
  assert_eq!(diags.length(), 1)
  assert_eq!(diags[0].source_page, "/guide/index.md")
  assert_eq!(diags[0].target_link, "/does-not-exist/")
}

///|
test "validate_internal_links: HTML href broken link detected" {
  let pages : Array[(String, String)] = [
    ("/index.md", "<a href=\"/missing/\">Missing</a>"),
  ]
  let known_urls = build_url_set(["/"])
  let diags = validate_internal_links(pages, known_urls)
  assert_eq!(diags.length(), 1)
  assert_eq!(diags[0].target_link, "/missing/")
}

///|
test "validate_internal_links: empty pages array returns empty diagnostics" {
  let pages : Array[(String, String)] = []
  let known_urls = build_url_set(["/"])
  let diags = validate_internal_links(pages, known_urls)
  assert_eq!(diags.length(), 0)
}

// =============================================================================
// build_url_set helper tests
// =============================================================================

///|
test "build_url_set: contains added URLs" {
  let set = build_url_set(["/", "/guide/", "/api/"])
  assert_true!(set.contains("/"))
  assert_true!(set.contains("/guide/"))
  assert_true!(set.contains("/api/"))
}

///|
test "build_url_set: does not contain absent URLs" {
  let set = build_url_set(["/guide/"])
  assert_false!(set.contains("/missing/"))
}

///|
test "build_url_set: empty array produces empty set" {
  let set = build_url_set([])
  assert_false!(set.contains("/"))
}
