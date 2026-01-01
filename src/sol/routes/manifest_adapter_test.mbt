// Tests for Manifest Adapter (routes module)
// Converts between PageMeta and RouteManifest

// =============================================================================
// Helper Functions
// =============================================================================

///|
fn make_test_page_meta(
  source_path : String,
  url_path : String,
) -> @ssg.PageMeta {
  @ssg.PageMeta::new(source_path, url_path)
}

///|
fn make_test_config() -> @ssg.SsgConfig {
  @ssg.SsgConfig::default()
}

// =============================================================================
// page_meta_to_static_route Tests
// =============================================================================

///|
test "page_meta_to_static_route - basic conversion" {
  let page = make_test_page_meta("docs/intro.md", "/intro/")
  let route = page_meta_to_static_route(page)
  inspect(route.path, content="/intro/")
  inspect(route.source, content="docs/intro.md")
  inspect(route.output, content="intro/index.html")
}

///|
test "page_meta_to_static_route - with frontmatter" {
  let frontmatter = @ssg.Frontmatter::{
    ..@ssg.Frontmatter::default(),
    title: Some("Introduction"),
    description: Some("Getting started guide"),
    layout: Some("docs"),
    islands: ["counter"],
  }
  let page = @ssg.PageMeta::{
    source_path: "guide/intro.md",
    url_path: "/guide/intro/",
    content_type: @ssg.ContentType::Markdown,
    renderer_type: @ssg.RendererType::MarkdownRenderer,
    frontmatter,
    last_modified: None,
    locale: "en",
    canonical_path: "/guide/intro/",
    sort_key: "guide/intro.md",
  }
  let route = page_meta_to_static_route(page)
  inspect(route.title, content="Some(\"Introduction\")")
  inspect(route.description, content="Some(\"Getting started guide\")")
  inspect(route.layout, content="Some(\"docs\")")
  inspect(route.islands.length(), content="1")
  inspect(route.islands[0], content="counter")
}

///|
test "page_meta_to_static_route - preserves locale" {
  let page = @ssg.PageMeta::{
    source_path: "ja/intro.md",
    url_path: "/ja/intro/",
    content_type: @ssg.ContentType::Markdown,
    renderer_type: @ssg.RendererType::MarkdownRenderer,
    frontmatter: @ssg.Frontmatter::default(),
    last_modified: None,
    locale: "ja",
    canonical_path: "/intro/",
    sort_key: "ja/intro.md",
  }
  let route = page_meta_to_static_route(page)
  inspect(route.locale, content="ja")
}

// =============================================================================
// static_route_to_page_meta Tests
// =============================================================================

///|
test "static_route_to_page_meta - basic conversion" {
  let route = StaticRouteEntry::new(
    path="/about/",
    source="about.md",
    output="about/index.html",
  )
  let page = static_route_to_page_meta(route)
  inspect(page.url_path, content="/about/")
  inspect(page.source_path, content="about.md")
  inspect(page.content_type, content="Markdown")
}

///|
test "static_route_to_page_meta - preserves metadata" {
  let route = StaticRouteEntry::{
    path: "/guide/",
    source: "guide.md",
    output: "guide/index.html",
    layout: Some("docs"),
    title: Some("Guide"),
    description: Some("User guide"),
    islands: ["toc"],
    locale: "en",
    generated_params: [],
  }
  let page = static_route_to_page_meta(route)
  inspect(page.frontmatter.title, content="Some(\"Guide\")")
  inspect(page.frontmatter.description, content="Some(\"User guide\")")
  inspect(page.frontmatter.layout, content="Some(\"docs\")")
  inspect(page.frontmatter.islands.length(), content="1")
}

///|
test "static_route_to_page_meta - roundtrip" {
  let original_route = StaticRouteEntry::{
    path: "/test/",
    source: "test.md",
    output: "test/index.html",
    layout: Some("default"),
    title: Some("Test Page"),
    description: None,
    islands: [],
    locale: "en",
    generated_params: [],
  }
  let page = static_route_to_page_meta(original_route)
  let roundtrip_route = page_meta_to_static_route(page)
  inspect(roundtrip_route.path, content="/test/")
  inspect(roundtrip_route.source, content="test.md")
  inspect(roundtrip_route.title, content="Some(\"Test Page\")")
  inspect(roundtrip_route.layout, content="Some(\"default\")")
}

// =============================================================================
// page_metas_to_manifest Tests
// =============================================================================

///|
test "page_metas_to_manifest - empty pages" {
  let pages : Array[@ssg.PageMeta] = []
  let config = make_test_config()
  let manifest = page_metas_to_manifest(pages, config)
  inspect(manifest.routes.length(), content="0")
}

///|
test "page_metas_to_manifest - single page" {
  let pages = [make_test_page_meta("index.md", "/")]
  let config = make_test_config()
  let manifest = page_metas_to_manifest(pages, config)
  inspect(manifest.routes.length(), content="1")
  guard manifest.routes[0] is Static(entry) else { fail("Expected Static") }
  inspect(entry.path, content="/")
}

///|
test "page_metas_to_manifest - multiple pages" {
  let pages = [
    make_test_page_meta("index.md", "/"),
    make_test_page_meta("about.md", "/about/"),
    make_test_page_meta("guide/intro.md", "/guide/intro/"),
  ]
  let config = make_test_config()
  let manifest = page_metas_to_manifest(pages, config)
  inspect(manifest.routes.length(), content="3")
}

///|
test "page_metas_to_manifest - default fallback" {
  let pages : Array[@ssg.PageMeta] = []
  let config = make_test_config()
  let manifest = page_metas_to_manifest(pages, config)
  inspect(manifest.fallback.is_spa(), content="false")
}

///|
test "page_metas_to_manifest - SPA fallback when config.navigation.spa" {
  let config = @ssg.SsgConfig::{
    ..@ssg.SsgConfig::default(),
    navigation: @ssg.NavigationConfig::{
      ..@ssg.NavigationConfig::default(),
      spa: true,
    },
  }
  let pages : Array[@ssg.PageMeta] = []
  let manifest = page_metas_to_manifest(pages, config)
  inspect(manifest.fallback.is_spa(), content="true")
  inspect(manifest.fallback.spa_entry(), content="Some(\"/index.html\")")
}

// =============================================================================
// manifest_to_page_metas Tests
// =============================================================================

///|
test "manifest_to_page_metas - empty manifest" {
  let manifest = RouteManifest::empty()
  let pages = manifest_to_page_metas(manifest)
  inspect(pages.length(), content="0")
}

///|
test "manifest_to_page_metas - static routes only" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(
          path="/about/",
          source="about.md",
          output="about/index.html",
        ),
      ),
      Static(
        StaticRouteEntry::new(
          path="/guide/",
          source="guide.md",
          output="guide/index.html",
        ),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let pages = manifest_to_page_metas(manifest)
  inspect(pages.length(), content="2")
  inspect(pages[0].url_path, content="/about/")
  inspect(pages[1].url_path, content="/guide/")
}

///|
test "manifest_to_page_metas - ignores dynamic routes" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(
          path="/about/",
          source="about.md",
          output="about/index.html",
        ),
      ),
      Dynamic(
        DynamicRouteEntry::new(
          path="/blog/:slug",
          pattern="^/blog/([^/]+)$",
          param_names=["slug"],
          source="blog/[slug].md",
          mode=RenderMode::Ssr,
        ),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let pages = manifest_to_page_metas(manifest)
  inspect(pages.length(), content="1") // Only static route converted
}

///|
test "manifest_to_page_metas - ignores API routes" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(
          path="/about/",
          source="about.md",
          output="about/index.html",
        ),
      ),
      Api(
        ApiRouteEntry::new(
          path="/api/posts",
          pattern="^/api/posts$",
          http_method=HttpMethod::Get,
          source="api/posts.mbt",
        ),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let pages = manifest_to_page_metas(manifest)
  inspect(pages.length(), content="1")
}

///|
test "manifest_to_page_metas - preserves metadata" {
  let manifest = RouteManifest::{
    routes: [
      Static(StaticRouteEntry::{
        path: "/guide/",
        source: "guide.md",
        output: "guide/index.html",
        layout: Some("docs"),
        title: Some("Guide"),
        description: Some("User guide"),
        islands: ["toc", "search"],
        locale: "en",
        generated_params: [],
      }),
    ],
    fallback: FallbackConfig::default(),
  }
  let pages = manifest_to_page_metas(manifest)
  inspect(pages.length(), content="1")
  let page = pages[0]
  inspect(page.frontmatter.title, content="Some(\"Guide\")")
  inspect(page.frontmatter.description, content="Some(\"User guide\")")
  inspect(page.frontmatter.layout, content="Some(\"docs\")")
  inspect(page.frontmatter.islands.length(), content="2")
}
