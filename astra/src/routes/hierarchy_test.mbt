// Tests for Hierarchical Manifest Generation

// =============================================================================
// extract_first_segment Tests
// =============================================================================

///|
test "extract_first_segment - root path" {
  inspect(extract_first_segment("/"), content="")
}

///|
test "extract_first_segment - empty path" {
  inspect(extract_first_segment(""), content="")
}

///|
test "extract_first_segment - single segment" {
  inspect(extract_first_segment("/about"), content="about")
}

///|
test "extract_first_segment - single segment with trailing slash" {
  inspect(extract_first_segment("/about/"), content="about")
}

///|
test "extract_first_segment - nested path" {
  inspect(extract_first_segment("/docs/guide/intro"), content="docs")
}

///|
test "extract_first_segment - two levels" {
  inspect(extract_first_segment("/blog/post"), content="blog")
}

// =============================================================================
// path_matches_segment Tests
// =============================================================================

///|
test "path_matches_segment - exact match" {
  inspect(path_matches_segment("/docs", "docs"), content="true")
}

///|
test "path_matches_segment - nested path" {
  inspect(path_matches_segment("/docs/guide", "docs"), content="true")
}

///|
test "path_matches_segment - no match" {
  inspect(path_matches_segment("/blog/post", "docs"), content="false")
}

///|
test "path_matches_segment - root path" {
  inspect(path_matches_segment("/", "docs"), content="false")
}

///|
test "path_matches_segment - partial name no match" {
  // /documentation should not match "docs"
  inspect(path_matches_segment("/documentation", "docs"), content="false")
}

// =============================================================================
// get_all_segments Tests
// =============================================================================

///|
test "get_all_segments - mixed routes" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(path="/", source="index.mbt", output="index.html"),
      ),
      Static(
        StaticRouteEntry::new(
          path="/about",
          source="about.mbt",
          output="about/index.html",
        ),
      ),
      Static(
        StaticRouteEntry::new(
          path="/docs/intro",
          source="docs/intro.mbt",
          output="docs/intro/index.html",
        ),
      ),
      Static(
        StaticRouteEntry::new(
          path="/docs/guide",
          source="docs/guide.mbt",
          output="docs/guide/index.html",
        ),
      ),
      Static(
        StaticRouteEntry::new(
          path="/blog/post1",
          source="blog/post1.mbt",
          output="blog/post1/index.html",
        ),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  let segments = get_all_segments(manifest)
  // Should have: about, docs, blog (root "/" has no segment)
  inspect(segments.length(), content="3")
  inspect(segments.contains("docs"), content="true")
  inspect(segments.contains("blog"), content="true")
  inspect(segments.contains("about"), content="true")
}

///|
test "get_all_segments - only root routes" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(path="/", source="index.mbt", output="index.html"),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  let segments = get_all_segments(manifest)
  inspect(segments.length(), content="0")
}

// =============================================================================
// resolve_chunks_inline Tests
// =============================================================================

///|
test "resolve_chunks_inline - exact match" {
  let manifest = HierarchicalManifest::{
    version: 2,
    base: "/_luna/",
    segments: {},
    chunks: {},
    routes: { "/": ["boot"], "/about": ["boot", "about"] },
  }
  inspect(resolve_chunks_inline(manifest, "/"), content="Some([\"boot\"])")
  inspect(
    resolve_chunks_inline(manifest, "/about"),
    content="Some([\"boot\", \"about\"])",
  )
}

///|
test "resolve_chunks_inline - with trailing slash" {
  let manifest = HierarchicalManifest::{
    version: 2,
    base: "/_luna/",
    segments: {},
    chunks: {},
    routes: { "/about/": ["boot"] },
  }
  // Should match with or without trailing slash
  inspect(
    resolve_chunks_inline(manifest, "/about/"),
    content="Some([\"boot\"])",
  )
  inspect(resolve_chunks_inline(manifest, "/about"), content="Some([\"boot\"])")
}

///|
test "resolve_chunks_inline - no match returns None" {
  let manifest = HierarchicalManifest::{
    version: 2,
    base: "/_luna/",
    segments: {},
    chunks: {},
    routes: { "/": ["boot"] },
  }
  inspect(resolve_chunks_inline(manifest, "/docs/guide"), content="None")
}

// =============================================================================
// find_segment_ref Tests
// =============================================================================

///|
test "find_segment_ref - found" {
  let docs_ref = SegmentRef::{
    path: "routes/docs.json",
    pattern: "/docs/*",
    spa: false,
    preload: false,
  }
  let manifest = HierarchicalManifest::{
    version: 2,
    base: "/_luna/",
    segments: { "docs": docs_ref },
    chunks: {},
    routes: {},
  }
  let result = find_segment_ref(manifest, "/docs/guide")
  guard result is Some((name, seg_ref)) else { fail("Expected Some") }
  inspect(name, content="docs")
  inspect(seg_ref.path, content="routes/docs.json")
}

///|
test "find_segment_ref - not found" {
  let manifest = HierarchicalManifest::{
    version: 2,
    base: "/_luna/",
    segments: {},
    chunks: {},
    routes: {},
  }
  inspect(find_segment_ref(manifest, "/docs/guide") is None, content="true")
}

///|
test "find_segment_ref - root path returns None" {
  let docs_ref = SegmentRef::{
    path: "routes/docs.json",
    pattern: "/docs/*",
    spa: false,
    preload: false,
  }
  let manifest = HierarchicalManifest::{
    version: 2,
    base: "/_luna/",
    segments: { "docs": docs_ref },
    chunks: {},
    routes: {},
  }
  inspect(find_segment_ref(manifest, "/") is None, content="true")
}

// =============================================================================
// split_manifest Tests
// =============================================================================

///|
test "split_manifest - separates root and segment routes" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(path="/", source="index.mbt", output="index.html"),
      ),
      Static(
        StaticRouteEntry::new(
          path="/about",
          source="about.mbt",
          output="about/index.html",
        ),
      ),
      Static(
        StaticRouteEntry::new(
          path="/docs/intro",
          source="docs/intro.mbt",
          output="docs/intro/index.html",
        ),
      ),
      Static(
        StaticRouteEntry::new(
          path="/docs/guide",
          source="docs/guide.mbt",
          output="docs/guide/index.html",
        ),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  let configs : Map[String, PageConfig] = {}
  let (hierarchical, segment_manifests) = split_manifest(manifest, configs)

  // Root routes should be inline
  inspect(hierarchical.routes.get("/"), content="Some([\"boot\"])")

  // Segment routes should be in segment manifests
  inspect(segment_manifests.contains("docs"), content="true")
  inspect(segment_manifests.contains("about"), content="true")

  // Check docs segment manifest
  guard segment_manifests.get("docs") is Some(docs_manifest) else {
    fail("Expected docs manifest")
  }
  inspect(docs_manifest.base, content="/docs")
  inspect(docs_manifest.routes.get("/intro"), content="Some([\"boot\"])")
  inspect(docs_manifest.routes.get("/guide"), content="Some([\"boot\"])")
}

///|
test "split_manifest - spa config applied" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(path="/", source="index.mbt", output="index.html"),
      ),
      Static(
        StaticRouteEntry::new(
          path="/wiki/page1",
          source="wiki/page1.mbt",
          output="wiki/page1/index.html",
        ),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  let wiki_config = PageConfig::default()
  let wiki_config_with_spa = PageConfig::{
    ..wiki_config,
    spa: true,
    fallback_behavior: Some("spa"),
  }
  let configs : Map[String, PageConfig] = { "wiki": wiki_config_with_spa }
  let (hierarchical, segment_manifests) = split_manifest(manifest, configs)

  // Check segment ref has spa flag
  guard hierarchical.segments.get("wiki") is Some(wiki_ref) else {
    fail("Expected wiki segment ref")
  }
  inspect(wiki_ref.spa, content="true")

  // Check segment manifest has spa fallback
  guard segment_manifests.get("wiki") is Some(wiki_manifest) else {
    fail("Expected wiki manifest")
  }
  inspect(wiki_manifest.fallback, content="spa")
}

///|
test "split_manifest - dynamic routes included in segment" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(path="/", source="index.mbt", output="index.html"),
      ),
      Dynamic(
        DynamicRouteEntry::new(
          path="/blog/:slug",
          pattern="^/blog/([^/]+)$",
          param_names=["slug"],
          source="blog/_slug_.mbt",
          mode=RenderMode::Ssr,
        ),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  let configs : Map[String, PageConfig] = {}
  let (_, segment_manifests) = split_manifest(manifest, configs)
  guard segment_manifests.get("blog") is Some(blog_manifest) else {
    fail("Expected blog manifest")
  }

  // Should have dynamic pattern
  inspect(blog_manifest.dynamic.length(), content="1")
  inspect(blog_manifest.dynamic[0].pattern, content="/:slug")
  inspect(blog_manifest.dynamic[0].params[0], content="slug")
  inspect(blog_manifest.dynamic[0].catch_all, content="false")
}

// =============================================================================
// match_dynamic_pattern Tests
// =============================================================================

///|
test "match_dynamic_pattern - simple param" {
  let manifest = SegmentManifest::{
    base: "/blog",
    routes: {},
    dynamic: [
      DynamicPattern::{
        pattern: "/:slug",
        regex: "^/([^/]+)$",
        params: ["slug"],
        catch_all: false,
      },
    ],
    fallback: "404",
  }
  let result = match_dynamic_pattern(manifest, "/blog/hello-world")
  guard result is Some((pattern, params)) else { fail("Expected match") }
  inspect(pattern.pattern, content="/:slug")
  inspect(params.get("slug"), content="Some(\"hello-world\")")
}

///|
test "match_dynamic_pattern - no match" {
  let manifest = SegmentManifest::{
    base: "/blog",
    routes: {},
    dynamic: [
      DynamicPattern::{
        pattern: "/:slug",
        regex: "^/([^/]+)$",
        params: ["slug"],
        catch_all: false,
      },
    ],
    fallback: "404",
  }
  // Path with extra segment should not match single param pattern
  let result = match_dynamic_pattern(manifest, "/blog/category/post")
  inspect(result is None, content="true")
}

///|
test "match_dynamic_pattern - catch-all" {
  let manifest = SegmentManifest::{
    base: "/docs",
    routes: {},
    dynamic: [
      DynamicPattern::{
        pattern: "/:...path",
        regex: "^/(.+)$",
        params: ["path"],
        catch_all: true,
      },
    ],
    fallback: "404",
  }
  let result = match_dynamic_pattern(manifest, "/docs/guide/getting-started")
  guard result is Some((pattern, params)) else { fail("Expected match") }
  inspect(pattern.catch_all, content="true")
  inspect(params.get("path"), content="Some(\"guide/getting-started\")")
}
