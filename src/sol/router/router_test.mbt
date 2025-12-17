///|
/// Unit tests for sol/router pure functions

// =============================================================================
// RouteParams Tests
// =============================================================================

test "RouteParams::empty: creates empty params" {
  let params = RouteParams::empty()
  assert_eq(params.params.length(), 0)
  assert_eq(params.query.length(), 0)
  assert_eq(params.path, "")
}

///|
test "RouteParams::get_param: empty params returns None" {
  let params = RouteParams::empty()
  assert_eq(params.get_param("any"), None)
}

///|
test "RouteParams::get_query: empty params returns None" {
  let params = RouteParams::empty()
  assert_eq(params.get_query("any"), None)
}

// =============================================================================
// ChunkManifest Tests
// =============================================================================

///|
test "ChunkManifest::empty: creates empty manifest" {
  let manifest = @router.ChunkManifest::empty()
  assert_eq(manifest.base_url, "/static/")
  assert_eq(manifest.entries.length(), 0)
}

///|
test "ChunkManifest::new: creates manifest with custom base_url" {
  let manifest = @router.ChunkManifest::new("/assets/")
  assert_eq(manifest.base_url, "/assets/")
}

///|
test "ChunkManifest::add: adds entry to manifest" {
  let manifest = @router.ChunkManifest::new("/static/")
  manifest.add(
    "counter.js",
    @router.ChunkManifestEntry::new("counter.js", ["_shared/lib.js"]),
  )
  assert_eq(manifest.entries.length(), 1)
}

///|
test "ChunkManifest::get_chunks: returns empty for unknown entry" {
  let manifest = @router.ChunkManifest::new("/static/")
  let chunks = manifest.get_chunks("/static/unknown.js")
  assert_eq(chunks.length(), 0)
}

///|
test "ChunkManifest::get_chunks: returns chunk dependencies" {
  let manifest = @router.ChunkManifest::new("/static/")
  manifest.add(
    "counter.js",
    @router.ChunkManifestEntry::new("counter.js", ["_shared/client-abc123.js"]),
  )
  let chunks = manifest.get_chunks("/static/counter.js")
  assert_eq(chunks.length(), 1)
  assert_eq(chunks[0], "/static/_shared/client-abc123.js")
}

///|
test "ChunkManifest::get_chunks: handles multiple imports" {
  let manifest = @router.ChunkManifest::new("/static/")
  manifest.add(
    "counter.js",
    @router.ChunkManifestEntry::new(
      "counter.js",
      ["_shared/client-abc.js", "_shared/utils-xyz.js"],
    ),
  )
  let chunks = manifest.get_chunks("/static/counter.js")
  assert_eq(chunks.length(), 2)
  assert_true(chunks.contains("/static/_shared/client-abc.js"))
  assert_true(chunks.contains("/static/_shared/utils-xyz.js"))
}

///|
test "ChunkManifest::get_chunks: extracts entry name from url without base_url" {
  let manifest = @router.ChunkManifest::new("/static/")
  manifest.add(
    "counter.js",
    @router.ChunkManifestEntry::new("counter.js", ["_shared/lib.js"]),
  )
  // URL without matching base_url - should extract filename
  let chunks = manifest.get_chunks("/other/path/counter.js")
  assert_eq(chunks.length(), 1)
  assert_eq(chunks[0], "/static/_shared/lib.js")
}

///|
test "ChunkManifest::parse: parses valid manifest" {
  let json =
    #|{
    #|  "counter.js": {
    #|    "file": "counter.js",
    #|    "imports": ["_shared/client-abc.js"]
    #|  },
    #|  "form.js": {
    #|    "file": "form.js",
    #|    "imports": ["_shared/client-abc.js", "_shared/validation.js"]
    #|  }
    #|}
  let manifest = @router.ChunkManifest::parse(json, "/static/")
  assert_true(manifest is Some(_))
  let m = manifest.unwrap()
  assert_eq(m.entries.length(), 2)
  assert_eq(m.get_chunks("/static/counter.js").length(), 1)
  assert_eq(m.get_chunks("/static/form.js").length(), 2)
}

///|
test "ChunkManifest::parse: returns None for invalid json" {
  let manifest = @router.ChunkManifest::parse("not json", "/static/")
  assert_true(manifest is None)
}

///|
test "ChunkManifest::parse: returns None for non-object json" {
  let manifest = @router.ChunkManifest::parse("[1, 2, 3]", "/static/")
  assert_true(manifest is None)
}

///|
test "ChunkManifest::parse: handles entries without imports" {
  let json =
    #|{
    #|  "counter.js": {
    #|    "file": "counter.js"
    #|  }
    #|}
  let manifest = @router.ChunkManifest::parse(json, "/static/")
  assert_true(manifest is Some(_))
  let m = manifest.unwrap()
  assert_eq(m.get_chunks("/static/counter.js").length(), 0)
}

///|
test "ChunkManifest::parse: skips entries without file field" {
  let json =
    #|{
    #|  "counter.js": {
    #|    "imports": ["_shared/lib.js"]
    #|  }
    #|}
  let manifest = @router.ChunkManifest::parse(json, "/static/")
  assert_true(manifest is Some(_))
  let m = manifest.unwrap()
  assert_eq(m.entries.length(), 0)
}

// =============================================================================
// RouterConfig Tests
// =============================================================================

///|
test "RouterConfig::default: has expected defaults" {
  let config = @router.RouterConfig::default()
  assert_eq(config.title_prefix, "")
  assert_eq(config.default_title, "App")
  assert_eq(config.loader_url, "/static/loader.js")
  assert_eq(config.enable_preload, true)
  assert_eq(config.preload_libs.length(), 0)
  assert_true(config.chunk_manifest is None)
}

///|
test "RouterConfig::with_preload_libs: sets preload libs" {
  let config = @router.RouterConfig::default().with_preload_libs([
    "/static/lib.js",
  ])
  assert_eq(config.preload_libs.length(), 1)
  assert_eq(config.preload_libs[0], "/static/lib.js")
}

///|
test "RouterConfig::with_chunk_manifest: sets manifest" {
  let manifest = @router.ChunkManifest::new("/static/")
  manifest.add(
    "counter.js",
    @router.ChunkManifestEntry::new("counter.js", []),
  )
  let config = @router.RouterConfig::default().with_chunk_manifest(manifest)
  assert_true(config.chunk_manifest is Some(_))
}
