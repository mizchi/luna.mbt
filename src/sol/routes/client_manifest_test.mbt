// Tests for Client Manifest (ChunkManifest)

// =============================================================================
// ChunkManifest Construction Tests
// =============================================================================

///|
test "ChunkManifest::empty - default values" {
  let manifest = ChunkManifest::empty()
  inspect(manifest.routes.length(), content="0")
  inspect(manifest.chunks.length(), content="0")
  inspect(manifest.base, content="/_luna/")
}

///|
test "ChunkManifest::new - default base" {
  let manifest = ChunkManifest::new()
  inspect(manifest.base, content="/_luna/")
}

///|
test "ChunkManifest::new - custom base" {
  let manifest = ChunkManifest::new(base="/assets/")
  inspect(manifest.base, content="/assets/")
}

// =============================================================================
// route_manifest_to_chunk_manifest Tests
// =============================================================================

///|
test "route_manifest_to_chunk_manifest - empty manifest" {
  let route_manifest = RouteManifest::empty()
  let chunk_manifest = route_manifest_to_chunk_manifest(route_manifest)
  // Should have default wildcard route
  inspect(chunk_manifest.routes.contains("*"), content="true")
}

///|
test "route_manifest_to_chunk_manifest - static route without islands" {
  let route_manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(
          path="/about",
          source="about.md",
          output="about.html",
        ),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let chunk_manifest = route_manifest_to_chunk_manifest(route_manifest)
  guard chunk_manifest.routes.get("/about") is Some(chunks) else {
    fail("Expected route entry")
  }
  inspect(chunks.contains("boot"), content="true")
}

///|
test "route_manifest_to_chunk_manifest - static route with islands" {
  let route_manifest = RouteManifest::{
    routes: [
      Static(StaticRouteEntry::{
        path: "/about",
        source: "about.md",
        output: "about.html",
        layout: None,
        title: None,
        description: None,
        islands: ["counter", "toggle"],
        locale: "en",
        generated_params: [],
      }),
    ],
    fallback: FallbackConfig::default(),
  }
  let chunk_manifest = route_manifest_to_chunk_manifest(route_manifest)
  guard chunk_manifest.routes.get("/about") is Some(chunks) else {
    fail("Expected route entry")
  }
  inspect(chunks.contains("boot"), content="true")
  inspect(chunks.contains("hydrate"), content="true")
  inspect(chunks.contains("signal"), content="true")
  inspect(chunks.contains("island-counter"), content="true")
  inspect(chunks.contains("island-toggle"), content="true")
}

///|
test "route_manifest_to_chunk_manifest - dynamic route" {
  let route_manifest = RouteManifest::{
    routes: [
      Dynamic(DynamicRouteEntry::{
        path: "/blog/:slug",
        pattern: "^/blog/([^/]+)$",
        param_names: ["slug"],
        source: "blog/[slug].md",
        mode: RenderMode::Ssr,
        layout: None,
        catch_all: None,
        title: None,
        islands: [],
      }),
    ],
    fallback: FallbackConfig::default(),
  }
  let chunk_manifest = route_manifest_to_chunk_manifest(route_manifest)
  guard chunk_manifest.routes.get("/blog/:slug") is Some(chunks) else {
    fail("Expected route entry")
  }
  inspect(chunks.contains("boot"), content="true")
}

///|
test "route_manifest_to_chunk_manifest - API route ignored" {
  let route_manifest = RouteManifest::{
    routes: [
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
  let chunk_manifest = route_manifest_to_chunk_manifest(route_manifest)
  // API routes don't need client chunks, so path should be empty string (filtered out)
  inspect(chunk_manifest.routes.contains("/api/posts"), content="false")
}

///|
test "route_manifest_to_chunk_manifest - component route" {
  let route_manifest = RouteManifest::{
    routes: [
      Component(
        ComponentRouteEntry::new(
          path="/counter",
          source="counter/",
          component_type=ComponentType::SsrComponent,
          mode=RenderMode::Ssr,
        ),
      ),
    ],
    fallback: FallbackConfig::default(),
  }
  let chunk_manifest = route_manifest_to_chunk_manifest(route_manifest)
  guard chunk_manifest.routes.get("/counter") is Some(chunks) else {
    fail("Expected route entry")
  }
  inspect(chunks.contains("boot"), content="true")
  inspect(chunks.contains("hydrate"), content="true")
  inspect(chunks.contains("island-counter"), content="true")
}

///|
test "route_manifest_to_chunk_manifest - with chunk hashes" {
  let route_manifest = RouteManifest::empty()
  let chunk_hashes : Map[String, String] = {}
  chunk_hashes["boot"] = "boot.abc123.js"
  chunk_hashes["hydrate"] = "hydrate.def456.js"
  let chunk_manifest = route_manifest_to_chunk_manifest(
    route_manifest,
    chunk_hashes~,
  )
  inspect(chunk_manifest.chunks.get("boot"), content="Some(\"boot.abc123.js\")")
  inspect(
    chunk_manifest.chunks.get("hydrate"),
    content="Some(\"hydrate.def456.js\")",
  )
}

// =============================================================================
// ChunkManifest::to_json Tests
// =============================================================================

///|
test "ChunkManifest::to_json - empty manifest" {
  let manifest = ChunkManifest::empty()
  let json = manifest.to_json()
  // Should contain valid JSON structure
  inspect(json.contains("\"routes\""), content="true")
  inspect(json.contains("\"chunks\""), content="true")
  inspect(json.contains("\"base\""), content="true")
  inspect(json.contains("\"/_luna/\""), content="true")
}

///|
test "ChunkManifest::to_json - with routes" {
  let manifest = ChunkManifest::{ routes: {}, chunks: {}, base: "/_luna/" }
  manifest.routes["/about"] = ["boot", "hydrate"]
  let json = manifest.to_json()
  inspect(json.contains("\"/about\""), content="true")
  inspect(json.contains("\"boot\""), content="true")
  inspect(json.contains("\"hydrate\""), content="true")
}

///|
test "ChunkManifest::to_json - escapes special characters" {
  let manifest = ChunkManifest::{ routes: {}, chunks: {}, base: "/_luna/" }
  manifest.routes["/path/with\"quote"] = ["boot"]
  let json = manifest.to_json()
  // Should escape the quote
  inspect(json.contains("\\\""), content="true")
}

// =============================================================================
// build_chunk_manifest Tests
// =============================================================================

///|
test "build_chunk_manifest - with chunk files" {
  let route_manifest = RouteManifest::empty()
  let chunk_files : Array[(String, String)] = [
    ("boot", "boot.a1b2c3.js"),
    ("hydrate", "hydrate.d4e5f6.js"),
  ]
  let manifest = build_chunk_manifest(route_manifest, chunk_files~)
  inspect(manifest.chunks.get("boot"), content="Some(\"boot.a1b2c3.js\")")
  inspect(manifest.chunks.get("hydrate"), content="Some(\"hydrate.d4e5f6.js\")")
}

///|
test "build_chunk_manifest - custom base" {
  let route_manifest = RouteManifest::empty()
  let manifest = build_chunk_manifest(route_manifest, base="/static/")
  inspect(manifest.base, content="/static/")
}

// =============================================================================
// SegmentRef::to_json Tests
// =============================================================================

///|
test "SegmentRef::to_json - basic" {
  let seg_ref = SegmentRef::{
    path: "/docs",
    pattern: "^/docs",
    spa: false,
    preload: false,
  }
  let json = seg_ref.to_json()
  inspect(json.contains("\"path\""), content="true")
  inspect(json.contains("\"/docs\""), content="true")
  inspect(json.contains("\"pattern\""), content="true")
}

///|
test "SegmentRef::to_json - with spa and preload" {
  let seg_ref = SegmentRef::{
    path: "/app",
    pattern: "^/app",
    spa: true,
    preload: true,
  }
  let json = seg_ref.to_json()
  inspect(json.contains("\"spa\": true"), content="true")
  inspect(json.contains("\"preload\": true"), content="true")
}

// =============================================================================
// DynamicPattern::to_json Tests
// =============================================================================

///|
test "DynamicPattern::to_json - basic" {
  let pattern = DynamicPattern::{
    pattern: "/blog/:slug",
    regex: "^/blog/([^/]+)$",
    params: ["slug"],
    catch_all: false,
  }
  let json = pattern.to_json()
  inspect(json.contains("\"pattern\""), content="true")
  inspect(json.contains("\"regex\""), content="true")
  inspect(json.contains("\"params\""), content="true")
  inspect(json.contains("\"slug\""), content="true")
}

///|
test "DynamicPattern::to_json - with catch_all" {
  let pattern = DynamicPattern::{
    pattern: "/docs/[...path]",
    regex: "^/docs/(.*)$",
    params: ["path"],
    catch_all: true,
  }
  let json = pattern.to_json()
  inspect(json.contains("\"catchAll\": true"), content="true")
}

// =============================================================================
// SegmentManifest::to_json Tests
// =============================================================================

///|
test "SegmentManifest::to_json - basic structure" {
  let manifest = SegmentManifest::{
    base: "/docs",
    routes: {},
    dynamic: [],
    fallback: "/404.html",
  }
  let json = manifest.to_json()
  inspect(json.contains("\"base\""), content="true")
  inspect(json.contains("\"/docs\""), content="true")
  inspect(json.contains("\"routes\""), content="true")
  inspect(json.contains("\"dynamic\""), content="true")
  inspect(json.contains("\"fallback\""), content="true")
}

// =============================================================================
// HierarchicalManifest::to_json Tests
// =============================================================================

///|
test "HierarchicalManifest::to_json - basic structure" {
  let manifest = HierarchicalManifest::{
    version: 2,
    base: "/_luna/",
    segments: {},
    chunks: {},
    routes: {},
  }
  let json = manifest.to_json()
  inspect(json.contains("\"version\": 2"), content="true")
  inspect(json.contains("\"base\""), content="true")
  inspect(json.contains("\"segments\""), content="true")
  inspect(json.contains("\"chunks\""), content="true")
  inspect(json.contains("\"routes\""), content="true")
}
