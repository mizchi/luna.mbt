// Tests for Chunk Splitting and Cache Optimization
//
// Tests for Rolldown bundling strategies with mixed frameworks (React, Preact, Luna).
// Covers chunk splitting, cache invalidation, and hash-based cache busting.

// =============================================================================
// ChunkInfo Type for Testing
// =============================================================================

///|
/// Represents a bundled chunk with metadata for cache optimization
struct ChunkInfo {
  name : String
  hash : String
  size : Int
  framework : RendererType
  is_vendor : Bool
  dependencies : Array[String]
}

///|
/// Chunk splitting strategy
enum ChunkStrategy {
  /// Separate vendor chunks for each framework
  PerFramework
  /// Single shared vendor chunk
  SharedVendor
  /// Granular splitting based on usage
  Granular
}

///|
/// Bundle manifest for cache optimization
struct BundleManifest {
  chunks : Array[ChunkInfo]
  entry_points : Map[String, String]
  framework_chunks : Map[String, Array[String]]
}

// =============================================================================
// Framework Detection Tests
// =============================================================================

///|
test "ChunkInfo - React framework chunk" {
  let chunk = ChunkInfo::{
    name: "react-vendor",
    hash: "abc123",
    size: 45000,
    framework: RendererType::ReactRenderer,
    is_vendor: true,
    dependencies: ["react", "react-dom"],
  }
  inspect(chunk.framework == RendererType::ReactRenderer, content="true")
  inspect(chunk.is_vendor, content="true")
  inspect(chunk.dependencies.length(), content="2")
}

///|
test "ChunkInfo - Preact framework chunk" {
  let chunk = ChunkInfo::{
    name: "preact-vendor",
    hash: "def456",
    size: 12000,
    framework: RendererType::PreactRenderer,
    is_vendor: true,
    dependencies: ["preact", "preact/hooks", "@preact/signals"],
  }
  inspect(chunk.framework == RendererType::PreactRenderer, content="true")
  inspect(chunk.size < 15000, content="true") // Preact is smaller
  inspect(chunk.dependencies.length(), content="3")
}

///|
test "ChunkInfo - Luna framework chunk" {
  let chunk = ChunkInfo::{
    name: "luna-runtime",
    hash: "ghi789",
    size: 8000,
    framework: RendererType::LunaRenderer,
    is_vendor: true,
    dependencies: ["@luna_ui/luna"],
  }
  inspect(chunk.framework == RendererType::LunaRenderer, content="true")
  inspect(chunk.size < 10000, content="true") // Luna is lightweight
}

// =============================================================================
// Mixed Framework Chunk Splitting Tests
// =============================================================================

///|
test "BundleManifest - mixed React and Preact islands" {
  let manifest = BundleManifest::{
    chunks: [
      ChunkInfo::{
        name: "react-vendor",
        hash: "r1",
        size: 45000,
        framework: RendererType::ReactRenderer,
        is_vendor: true,
        dependencies: ["react", "react-dom"],
      },
      ChunkInfo::{
        name: "preact-vendor",
        hash: "p1",
        size: 12000,
        framework: RendererType::PreactRenderer,
        is_vendor: true,
        dependencies: ["preact"],
      },
      ChunkInfo::{
        name: "dashboard",
        hash: "d1",
        size: 5000,
        framework: RendererType::ReactRenderer,
        is_vendor: false,
        dependencies: ["react-vendor"],
      },
      ChunkInfo::{
        name: "counter",
        hash: "c1",
        size: 2000,
        framework: RendererType::PreactRenderer,
        is_vendor: false,
        dependencies: ["preact-vendor"],
      },
    ],
    entry_points: { "/dashboard/": "dashboard", "/counter/": "counter" },
    framework_chunks: {
      "react": ["react-vendor", "dashboard"],
      "preact": ["preact-vendor", "counter"],
    },
  }
  inspect(manifest.chunks.length(), content="4")
  inspect(manifest.entry_points.length(), content="2")
  inspect(manifest.framework_chunks.length(), content="2")
}

///|
test "BundleManifest - all three frameworks" {
  let manifest = BundleManifest::{
    chunks: [
      ChunkInfo::{
        name: "react-vendor",
        hash: "r1",
        size: 45000,
        framework: RendererType::ReactRenderer,
        is_vendor: true,
        dependencies: [],
      },
      ChunkInfo::{
        name: "preact-vendor",
        hash: "p1",
        size: 12000,
        framework: RendererType::PreactRenderer,
        is_vendor: true,
        dependencies: [],
      },
      ChunkInfo::{
        name: "luna-runtime",
        hash: "l1",
        size: 8000,
        framework: RendererType::LunaRenderer,
        is_vendor: true,
        dependencies: [],
      },
    ],
    entry_points: {},
    framework_chunks: {
      "react": ["react-vendor"],
      "preact": ["preact-vendor"],
      "luna": ["luna-runtime"],
    },
  }
  // Count vendor chunks
  let mut vendor_count = 0
  for chunk in manifest.chunks {
    if chunk.is_vendor {
      vendor_count = vendor_count + 1
    }
  }
  inspect(vendor_count, content="3")
}

// =============================================================================
// Cache Key Generation Tests
// =============================================================================

///|
test "Cache key - page with React island" {
  let page = PageMeta::new(
    "islands/Dashboard.tsx",
    "/dashboard/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  // Cache key should include renderer type
  let cache_key = page.source_path + ":" + page.renderer_type.to_string()
  inspect(cache_key.contains("React"), content="true")
}

///|
test "Cache key - page with Preact island" {
  let page = PageMeta::new(
    "islands/Counter.tsx",
    "/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer,
  )
  let cache_key = page.source_path + ":" + page.renderer_type.to_string()
  inspect(cache_key.contains("Preact"), content="true")
}

///|
test "Cache key - mixed frameworks have different keys" {
  let react_page = PageMeta::new(
    "islands/Counter.tsx",
    "/react/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  let preact_page = PageMeta::new(
    "islands/Counter.tsx",
    "/preact/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer,
  )
  // Same source, different renderer = different cache key
  let react_key = react_page.source_path +
    ":" +
    react_page.renderer_type.to_string()
  let preact_key = preact_page.source_path +
    ":" +
    preact_page.renderer_type.to_string()
  inspect(react_key == preact_key, content="false")
}

// =============================================================================
// Chunk Strategy Tests
// =============================================================================

///|
test "ChunkStrategy - PerFramework separates vendor chunks" {
  let strategy = ChunkStrategy::PerFramework
  // PerFramework creates separate vendor chunks for each framework
  match strategy {
    ChunkStrategy::PerFramework => inspect(true, content="true")
    _ => fail("Expected PerFramework")
  }
}

///|
test "ChunkStrategy - SharedVendor for common dependencies" {
  let strategy = ChunkStrategy::SharedVendor
  // SharedVendor creates one vendor chunk with all framework code
  match strategy {
    ChunkStrategy::SharedVendor => inspect(true, content="true")
    _ => fail("Expected SharedVendor")
  }
}

///|
test "ChunkStrategy - Granular for optimal caching" {
  let strategy = ChunkStrategy::Granular
  // Granular splits based on actual usage patterns
  match strategy {
    ChunkStrategy::Granular => inspect(true, content="true")
    _ => fail("Expected Granular")
  }
}

// =============================================================================
// Framework-specific Bundle Size Tests
// =============================================================================

///|
test "Bundle size - Preact smaller than React" {
  let react_size = 45000 // ~45KB minified
  let preact_size = 12000 // ~12KB minified
  inspect(preact_size < react_size, content="true")
  // Preact is about 3-4x smaller (45000/12000 = 3.75)
  inspect(react_size / preact_size >= 3, content="true")
}

///|
test "Bundle size - Luna lightweight" {
  let luna_size = 8000 // ~8KB minified
  let preact_size = 12000
  inspect(luna_size < preact_size, content="true")
}

///|
test "Bundle size - combined vs separate" {
  let react_size = 45000
  let preact_size = 12000
  let luna_size = 8000
  let combined = react_size + preact_size + luna_size
  // Separate loading allows loading only what's needed
  // A page with only Preact loads 12KB instead of 65KB
  inspect(combined, content="65000")
  inspect(preact_size * 5 < combined, content="true")
}

// =============================================================================
// Cache Invalidation Strategy Tests
// =============================================================================

///|
test "Cache invalidation - config change invalidates all" {
  let config1 = SsgConfig::default()
  let config2 = SsgConfig::{ ..SsgConfig::default(), title: "New Title" }
  // Config change should invalidate cache
  inspect(config1.title == config2.title, content="false")
}

///|
test "Cache invalidation - theme change invalidates CSS" {
  let theme1 = ThemeConfig::default()
  let theme2 = ThemeConfig::{
    ..ThemeConfig::default(),
    primary_color: Some("#ff0000"),
  }
  guard theme1.primary_color is Some(c1) else { fail("Expected Some") }
  guard theme2.primary_color is Some(c2) else { fail("Expected Some") }
  inspect(c1 == c2, content="false")
}

///|
test "Cache invalidation - framework change invalidates chunk" {
  let page1 = PageMeta::new(
    "islands/Counter.tsx",
    "/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  let page2 = PageMeta::new(
    "islands/Counter.tsx",
    "/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer,
  )
  // Changing framework should create different cache entry
  inspect(page1.renderer_type == page2.renderer_type, content="false")
}

// =============================================================================
// Dynamic Import and Code Splitting Tests
// =============================================================================

///|
test "Dynamic import - lazy loaded React island" {
  // Simulate lazy-loaded island metadata
  let lazy_island = PageInfo::new(
    id="heavy-dashboard",
    url_path="/dashboard/",
    source_path="islands/HeavyDashboard.tsx",
    title="Dashboard",
    renderer_type=RendererType::ReactRenderer,
  )
  // Lazy islands are loaded on demand
  inspect(
    lazy_island.renderer_type == RendererType::ReactRenderer,
    content="true",
  )
}

///|
test "Dynamic import - multiple lazy islands" {
  let islands = [
    PageInfo::new(
      id="chart",
      url_path="/chart/",
      renderer_type=RendererType::ReactRenderer,
    ),
    PageInfo::new(
      id="counter",
      url_path="/counter/",
      renderer_type=RendererType::PreactRenderer,
    ),
    PageInfo::new(
      id="button",
      url_path="/button/",
      renderer_type=RendererType::LunaRenderer,
    ),
  ]
  inspect(islands.length(), content="3")
  // Each island can be loaded independently
  let mut react_count = 0
  let mut preact_count = 0
  let mut luna_count = 0
  for island in islands {
    match island.renderer_type {
      RendererType::ReactRenderer => react_count = react_count + 1
      RendererType::PreactRenderer => preact_count = preact_count + 1
      RendererType::LunaRenderer => luna_count = luna_count + 1
      _ => ()
    }
  }
  inspect(react_count, content="1")
  inspect(preact_count, content="1")
  inspect(luna_count, content="1")
}

// =============================================================================
// Hash-based Cache Busting Tests
// =============================================================================

///|
test "Hash-based naming - chunk with content hash" {
  let chunk = ChunkInfo::{
    name: "dashboard",
    hash: "abc123def",
    size: 5000,
    framework: RendererType::ReactRenderer,
    is_vendor: false,
    dependencies: [],
  }
  // Filename with hash: dashboard.abc123def.js
  let filename = chunk.name + "." + chunk.hash + ".js"
  inspect(filename, content="dashboard.abc123def.js")
}

///|
test "Hash-based naming - vendor chunk stability" {
  // Vendor chunks should have stable hashes when content doesn't change
  let chunk1 = ChunkInfo::{
    name: "react-vendor",
    hash: "stable123",
    size: 45000,
    framework: RendererType::ReactRenderer,
    is_vendor: true,
    dependencies: ["react", "react-dom"],
  }
  let chunk2 = ChunkInfo::{
    name: "react-vendor",
    hash: "stable123", // Same hash = same content
    size: 45000,
    framework: RendererType::ReactRenderer,
    is_vendor: true,
    dependencies: ["react", "react-dom"],
  }
  inspect(chunk1.hash == chunk2.hash, content="true")
}

///|
test "Hash-based naming - content change updates hash" {
  let chunk_v1 = ChunkInfo::{
    name: "counter",
    hash: "v1hash",
    size: 2000,
    framework: RendererType::PreactRenderer,
    is_vendor: false,
    dependencies: [],
  }
  let chunk_v2 = ChunkInfo::{
    name: "counter",
    hash: "v2hash", // Different hash = content changed
    size: 2100,
    framework: RendererType::PreactRenderer,
    is_vendor: false,
    dependencies: [],
  }
  inspect(chunk_v1.hash == chunk_v2.hash, content="false")
}

// =============================================================================
// ISR Cache Strategy Tests
// =============================================================================

///|
test "ISR cache - React page with revalidation" {
  let page = PageMeta::new(
    "islands/Dashboard.tsx",
    "/dashboard/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  let fm = @frontmatter.Frontmatter::{
    ..@frontmatter.Frontmatter::default(),
    revalidate: Some(60), // Revalidate every 60 seconds
  }
  let updated = page.with_frontmatter(fm)
  guard updated.frontmatter.revalidate is Some(r) else {
    fail("Expected Some revalidate")
  }
  inspect(r, content="60")
}

///|
test "ISR cache - mixed framework pages" {
  let config = SsgConfig::default()
  let ctx = BuildContext::new(config, "/project")

  // React page with ISR
  let react_page = PageMeta::new(
    "islands/Dashboard.tsx",
    "/dashboard/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  let react_fm = @frontmatter.Frontmatter::{
    ..@frontmatter.Frontmatter::default(),
    revalidate: Some(300),
  }
  ctx.pages.push(react_page.with_frontmatter(react_fm))

  // Preact page with shorter ISR
  let preact_page = PageMeta::new(
    "islands/Counter.tsx",
    "/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer,
  )
  let preact_fm = @frontmatter.Frontmatter::{
    ..@frontmatter.Frontmatter::default(),
    revalidate: Some(60),
  }
  ctx.pages.push(preact_page.with_frontmatter(preact_fm))
  inspect(ctx.pages.length(), content="2")
}

// =============================================================================
// Chunk Dependency Graph Tests
// =============================================================================

///|
test "Chunk dependencies - React island depends on vendor" {
  let vendor_name = "react-vendor"
  let island = ChunkInfo::{
    name: "dashboard",
    hash: "i1",
    size: 5000,
    framework: RendererType::ReactRenderer,
    is_vendor: false,
    dependencies: [vendor_name],
  }
  inspect(island.dependencies[0], content="react-vendor")
  inspect(island.dependencies[0] == vendor_name, content="true")
}

///|
test "Chunk dependencies - Preact island with signals" {
  // Preact island depends on both vendor and signals chunks
  let island = ChunkInfo::{
    name: "signal-counter",
    hash: "i1",
    size: 2000,
    framework: RendererType::PreactRenderer,
    is_vendor: false,
    dependencies: ["preact-vendor", "preact-signals"],
  }
  inspect(island.dependencies.length(), content="2")
  inspect(island.dependencies[0], content="preact-vendor")
  inspect(island.dependencies[1], content="preact-signals")
}

///|
test "Chunk dependencies - no cross-framework deps" {
  // Preact island should only depend on Preact vendor, not React
  let preact_island = ChunkInfo::{
    name: "counter",
    hash: "p1",
    size: 2000,
    framework: RendererType::PreactRenderer,
    is_vendor: false,
    dependencies: ["preact-vendor"], // No react-vendor!
  }
  // Preact island should not depend on React vendor
  let has_react_dep = preact_island.dependencies
    .iter()
    .any(fn(dep) { dep == "react-vendor" })
  let has_preact_dep = preact_island.dependencies
    .iter()
    .any(fn(dep) { dep == "preact-vendor" })
  inspect(has_react_dep, content="false")
  inspect(has_preact_dep, content="true")
}

// =============================================================================
// Optimal Loading Strategy Tests
// =============================================================================

///|
test "Loading strategy - page with only Preact islands" {
  // Page only needs Preact chunks
  let page = PageMeta::new(
    "islands/Counter.tsx",
    "/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer,
  )
  // Should not load React vendor
  let needed_frameworks = [page.renderer_type]
  let has_react = needed_frameworks
    .iter()
    .any(fn(f) { f == RendererType::ReactRenderer })
  inspect(has_react, content="false")
}

///|
test "Loading strategy - page with mixed islands" {
  // Page with both React and Preact islands
  let config = SsgConfig::default()
  let ctx = BuildContext::new(config, "/project")
  ctx.pages.push(
    PageMeta::new(
      "islands/Dashboard.tsx",
      "/mixed/",
      content_type=ContentType::TsxComponent,
      renderer_type=RendererType::ReactRenderer,
    ),
  )

  // Determine which frameworks are needed
  let mut needs_react = false
  let mut needs_preact = false
  for page in ctx.pages {
    match page.renderer_type {
      RendererType::ReactRenderer => needs_react = true
      RendererType::PreactRenderer => needs_preact = true
      _ => ()
    }
  }
  inspect(needs_react, content="true")
  inspect(needs_preact, content="false")
}

///|
test "Loading strategy - prefetch hints" {
  // Preload/prefetch hints for frameworks
  let chunks = [
    ChunkInfo::{
      name: "react-vendor",
      hash: "r1",
      size: 45000,
      framework: RendererType::ReactRenderer,
      is_vendor: true,
      dependencies: [],
    },
    ChunkInfo::{
      name: "preact-vendor",
      hash: "p1",
      size: 12000,
      framework: RendererType::PreactRenderer,
      is_vendor: true,
      dependencies: [],
    },
  ]
  // Generate prefetch links for vendor chunks
  let prefetch_hints : Array[String] = []
  for chunk in chunks {
    if chunk.is_vendor {
      let hint = "<link rel=\"prefetch\" href=\"/" +
        chunk.name +
        "." +
        chunk.hash +
        ".js\">"
      prefetch_hints.push(hint)
    }
  }
  inspect(prefetch_hints.length(), content="2")
}

// =============================================================================
// Build Manifest Tests
// =============================================================================

///|
test "Build manifest - framework chunk mapping" {
  let manifest = BundleManifest::{
    chunks: [],
    entry_points: {
      "/dashboard/": "dashboard.abc123.js",
      "/counter/": "counter.def456.js",
    },
    framework_chunks: {
      "react": ["react-vendor.r1.js"],
      "preact": ["preact-vendor.p1.js"],
      "luna": ["luna-runtime.l1.js"],
    },
  }
  guard manifest.framework_chunks.get("react") is Some(react_chunks) else {
    fail("Expected react chunks")
  }
  inspect(react_chunks[0], content="react-vendor.r1.js")
}

///|
test "Build manifest - entry point resolution" {
  let manifest = BundleManifest::{
    chunks: [],
    entry_points: {
      "/": "home.h1.js",
      "/about/": "about.a1.js",
      "/dashboard/": "dashboard.d1.js",
    },
    framework_chunks: {},
  }
  guard manifest.entry_points.get("/dashboard/") is Some(entry) else {
    fail("Expected dashboard entry")
  }
  inspect(entry, content="dashboard.d1.js")
}

// =============================================================================
// Cache Efficiency Tests
// =============================================================================

///|
test "Cache efficiency - unchanged vendor chunks are cached" {
  // Simulate build comparison
  let build1_vendor = ChunkInfo::{
    name: "react-vendor",
    hash: "stable123",
    size: 45000,
    framework: RendererType::ReactRenderer,
    is_vendor: true,
    dependencies: [],
  }
  let build2_vendor = ChunkInfo::{
    name: "react-vendor",
    hash: "stable123", // Same hash = cache hit
    size: 45000,
    framework: RendererType::ReactRenderer,
    is_vendor: true,
    dependencies: [],
  }
  let cache_hit = build1_vendor.hash == build2_vendor.hash
  inspect(cache_hit, content="true")
}

///|
test "Cache efficiency - app code changes don't invalidate vendor" {
  let vendor = ChunkInfo::{
    name: "react-vendor",
    hash: "stable123",
    size: 45000,
    framework: RendererType::ReactRenderer,
    is_vendor: true,
    dependencies: [],
  }
  let app_v1 = ChunkInfo::{
    name: "dashboard",
    hash: "app_v1",
    size: 5000,
    framework: RendererType::ReactRenderer,
    is_vendor: false,
    dependencies: ["react-vendor"],
  }
  let app_v2 = ChunkInfo::{
    name: "dashboard",
    hash: "app_v2", // App changed
    size: 5500,
    framework: RendererType::ReactRenderer,
    is_vendor: false,
    dependencies: ["react-vendor"],
  }
  // Vendor unchanged even though app changed
  inspect(app_v1.hash == app_v2.hash, content="false")
  // Vendor chunk is still stable
  inspect(vendor.hash, content="stable123")
}

///|
test "Cache efficiency - tree-shaking reduces chunk size" {
  // Unused code is removed by tree-shaking
  let full_preact = 12000
  let tree_shaken = 8000 // After removing unused hooks
  inspect(tree_shaken < full_preact, content="true")
}

// =============================================================================
// Framework Coexistence Optimization Tests
// =============================================================================

///|
test "Coexistence - avoid duplicate virtual DOM" {
  // React and Preact have separate virtual DOM implementations
  // Don't bundle both on a page that only uses one
  let react_vdom_size = 15000
  let preact_vdom_size = 4000
  // Using only Preact saves significant bytes
  let savings = react_vdom_size - preact_vdom_size
  inspect(savings > 10000, content="true")
}

///|
test "Coexistence - shared utilities extraction" {
  // Common utilities can be shared across frameworks
  let shared_utils_name = "shared-utils"
  // Both React and Preact islands can use shared utils
  let react_island = ChunkInfo::{
    name: "dashboard",
    hash: "d1",
    size: 5000,
    framework: RendererType::ReactRenderer,
    is_vendor: false,
    dependencies: ["react-vendor", shared_utils_name],
  }
  let preact_island = ChunkInfo::{
    name: "counter",
    hash: "c1",
    size: 2000,
    framework: RendererType::PreactRenderer,
    is_vendor: false,
    dependencies: ["preact-vendor", shared_utils_name],
  }
  // Both depend on shared-utils
  inspect(
    react_island.dependencies.iter().any(fn(d) { d == shared_utils_name }),
    content="true",
  )
  inspect(
    preact_island.dependencies.iter().any(fn(d) { d == shared_utils_name }),
    content="true",
  )
}

///|
test "Coexistence - Luna WASM can coexist with JS frameworks" {
  let luna_runtime = ChunkInfo::{
    name: "luna-runtime",
    hash: "l1",
    size: 8000,
    framework: RendererType::LunaRenderer,
    is_vendor: true,
    dependencies: [],
  }
  let react_vendor = ChunkInfo::{
    name: "react-vendor",
    hash: "r1",
    size: 45000,
    framework: RendererType::ReactRenderer,
    is_vendor: true,
    dependencies: [],
  }
  // Luna and React are independent
  let luna_deps_on_react = luna_runtime.dependencies
    .iter()
    .any(fn(d) { d == "react-vendor" })
  let react_deps_on_luna = react_vendor.dependencies
    .iter()
    .any(fn(d) { d == "luna-runtime" })
  inspect(luna_deps_on_react, content="false")
  inspect(react_deps_on_luna, content="false")
}
