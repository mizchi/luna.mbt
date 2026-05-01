// Tests for Route Conflict Detection

// =============================================================================
// ConflictType Tests
// =============================================================================

///|
test "ConflictType::to_string - DuplicatePath" {
  let conflict = ConflictType::DuplicatePath(path="/about", sources=[
    "about.mbt", "about/index.mbt",
  ])
  let result = conflict.to_string()
  inspect(result.contains("Duplicate path '/about'"), content="true")
  inspect(result.contains("about.mbt"), content="true")
  inspect(result.contains("about/index.mbt"), content="true")
}

///|
test "ConflictType::to_string - StaticShadowsDynamic" {
  let conflict = ConflictType::StaticShadowsDynamic(
    static_path="/blog/about",
    dynamic_pattern="/blog/:slug",
  )
  let result = conflict.to_string()
  inspect(result.contains("Static path '/blog/about'"), content="true")
  inspect(result.contains("/blog/:slug"), content="true")
}

///|
test "ConflictType::to_string - MultipleCatchAll" {
  let conflict = ConflictType::MultipleCatchAll(paths=[
    "/docs/:...path", "/docs/:...all",
  ])
  let result = conflict.to_string()
  inspect(result.contains("Multiple catch-all"), content="true")
}

///|
test "ConflictType::to_string - AmbiguousDynamic" {
  let conflict = ConflictType::AmbiguousDynamic(
    pattern1="/blog/:id",
    pattern2="/blog/:slug",
  )
  let result = conflict.to_string()
  inspect(result.contains("Ambiguous dynamic patterns"), content="true")
  inspect(result.contains("/blog/:id"), content="true")
  inspect(result.contains("/blog/:slug"), content="true")
}

///|
test "ConflictType::is_error - DuplicatePath is error" {
  let conflict = ConflictType::DuplicatePath(path="/about", sources=[
    "a.mbt", "b.mbt",
  ])
  inspect(conflict.is_error(), content="true")
}

///|
test "ConflictType::is_error - MultipleCatchAll is error" {
  let conflict = ConflictType::MultipleCatchAll(paths=["/a", "/b"])
  inspect(conflict.is_error(), content="true")
}

///|
test "ConflictType::is_error - StaticShadowsDynamic is warning" {
  let conflict = ConflictType::StaticShadowsDynamic(
    static_path="/blog/about",
    dynamic_pattern="/blog/:slug",
  )
  inspect(conflict.is_error(), content="false")
}

///|
test "ConflictType::is_error - AmbiguousDynamic is warning" {
  let conflict = ConflictType::AmbiguousDynamic(
    pattern1="/blog/:id",
    pattern2="/blog/:slug",
  )
  inspect(conflict.is_error(), content="false")
}

// =============================================================================
// detect_conflicts Tests
// =============================================================================

///|
test "detect_conflicts - no conflicts" {
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
          path="/blog",
          source="blog/index.mbt",
          output="blog/index.html",
        ),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  let conflicts = detect_conflicts(manifest)
  inspect(conflicts.length(), content="0")
}

///|
test "detect_conflicts - duplicate static paths" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(
          path="/about",
          source="about.mbt",
          output="about.html",
        ),
      ),
      Static(
        StaticRouteEntry::new(
          path="/about",
          source="about/index.mbt",
          output="about/index.html",
        ),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  let conflicts = detect_conflicts(manifest)
  inspect(conflicts.length(), content="1")
  guard conflicts[0] is DuplicatePath(path~, sources~) else {
    fail("Expected DuplicatePath")
  }
  inspect(path, content="/about")
  inspect(sources.length(), content="2")
}

///|
test "detect_conflicts - multiple catch-all at same level" {
  let manifest = RouteManifest::{
    routes: [
      Dynamic(DynamicRouteEntry::{
        path: "/docs/:...path",
        pattern: "^/docs/(.+)$",
        param_names: ["path"],
        source: "docs/_path_.mbt",
        mode: RenderMode::Ssr,
        layout: None,
        catch_all: Some(CatchAllInfo::{ name: "path", optional: false }),
        title: None,
        islands: [],
      }),
      Dynamic(DynamicRouteEntry::{
        path: "/docs/:...all",
        pattern: "^/docs/(.+)$",
        param_names: ["all"],
        source: "docs/_all_.mbt",
        mode: RenderMode::Ssr,
        layout: None,
        catch_all: Some(CatchAllInfo::{ name: "all", optional: false }),
        title: None,
        islands: [],
      }),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  let conflicts = detect_conflicts(manifest)
  // Should detect MultipleCatchAll
  let mut found_catch_all = false
  for conflict in conflicts {
    if conflict is MultipleCatchAll(..) {
      found_catch_all = true
    }
  }
  inspect(found_catch_all, content="true")
}

///|
test "detect_conflicts - ambiguous dynamic patterns" {
  let manifest = RouteManifest::{
    routes: [
      Dynamic(
        DynamicRouteEntry::new(
          path="/blog/:id",
          pattern="^/blog/([^/]+)$",
          param_names=["id"],
          source="blog/_id_.mbt",
          mode=RenderMode::Ssr,
        ),
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
  let conflicts = detect_conflicts(manifest)
  // Should detect AmbiguousDynamic (same parent path)
  let mut found_ambiguous = false
  for conflict in conflicts {
    if conflict is AmbiguousDynamic(..) {
      found_ambiguous = true
    }
  }
  inspect(found_ambiguous, content="true")
}

///|
test "detect_conflicts - component routes also checked" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(
          path="/counter",
          source="counter.mbt",
          output="counter.html",
        ),
      ),
      Component(
        ComponentRouteEntry::new(
          path="/counter",
          source="counter/",
          component_type=ComponentType::SsrComponent,
          mode=RenderMode::Ssr,
        ),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  let conflicts = detect_conflicts(manifest)
  // Should detect duplicate path between Static and Component
  inspect(conflicts.length(), content="1")
  inspect(conflicts[0] is DuplicatePath(..), content="true")
}

///|
test "detect_conflicts - API routes don't conflict with page routes" {
  let manifest = RouteManifest::{
    routes: [
      Static(
        StaticRouteEntry::new(
          path="/about",
          source="about.mbt",
          output="about.html",
        ),
      ),
      Api(
        ApiRouteEntry::new(
          path="/about",
          pattern="^/about$",
          http_method=HttpMethod::Get,
          source="api/about.mbt",
        ),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  let conflicts = detect_conflicts(manifest)
  // API and page routes can coexist at same path
  inspect(conflicts.length(), content="0")
}

///|
test "detect_conflicts - dynamic patterns at different levels don't conflict" {
  let manifest = RouteManifest::{
    routes: [
      Dynamic(
        DynamicRouteEntry::new(
          path="/blog/:id",
          pattern="^/blog/([^/]+)$",
          param_names=["id"],
          source="blog/_id_.mbt",
          mode=RenderMode::Ssr,
        ),
      ),
      Dynamic(
        DynamicRouteEntry::new(
          path="/posts/:slug",
          pattern="^/posts/([^/]+)$",
          param_names=["slug"],
          source="posts/_slug_.mbt",
          mode=RenderMode::Ssr,
        ),
      ),
    ],
    fallback: FallbackConfig::NotFound(path="/404.html"),
  }
  let conflicts = detect_conflicts(manifest)
  // Different parent paths should not conflict
  inspect(conflicts.length(), content="0")
}
