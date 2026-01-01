// Tests for sol_routes pure functions

// =============================================================================
// CacheStrategy Tests
// =============================================================================

///|
test "CacheStrategy::default - returns AlwaysFetch" {
  let strategy = @router.CacheStrategy::default()
  inspect(strategy == @router.CacheStrategy::AlwaysFetch, content="true")
}

///|
test "CacheStrategy - equality" {
  let a = @router.CacheStrategy::AlwaysFetch
  let b = @router.CacheStrategy::AlwaysFetch
  let c = @router.CacheStrategy::StaleWhileRevalidate
  inspect(a == b, content="true")
  inspect(a == c, content="false")
}

// =============================================================================
// CatchAllInfo Tests
// =============================================================================

///|
test "CatchAllInfo - required catch-all" {
  let info = @router.CatchAllInfo::{ name: "slug", optional: false }
  inspect(info.name, content="slug")
  inspect(info.optional, content="false")
}

///|
test "CatchAllInfo - optional catch-all" {
  let info = @router.CatchAllInfo::{ name: "path", optional: true }
  inspect(info.name, content="path")
  inspect(info.optional, content="true")
}

// =============================================================================
// StaticDirConfig Tests
// =============================================================================

///|
test "StaticDirConfig::default - has expected values" {
  let config = @router.StaticDirConfig::default()
  inspect(config.trailing_slash, content="true")
  inspect(config.exclude.length(), content="0")
}

// =============================================================================
// StaticDir Tests
// =============================================================================

///|
test "StaticDir - construction" {
  let dir = @router.StaticDir::{
    path_prefix: "/docs",
    source_dir: "docs",
    title: "Documentation",
    config: @router.StaticDirConfig::default(),
  }
  inspect(dir.path_prefix, content="/docs")
  inspect(dir.source_dir, content="docs")
  inspect(dir.title, content="Documentation")
}
