// Tests for Complex CSS Integration Scenarios - Sol SSG + Luna CSS
//
// Advanced tests covering multi-locale, ISR caching, island isolation,
// theme switching, component composition, and build determinism.

// =============================================================================
// Test Types for Complex Scenarios
// =============================================================================

///|
/// Locale-aware CSS bundle
struct LocaleCssBundle {
  locale : String
  direction : String // "ltr" or "rtl"
  css : String
  classes : Array[String]
  font_family : String
}

///|
/// ISR cache entry with CSS metadata
struct IsrCssEntry {
  page_path : String
  html_hash : String
  css_hash : String
  last_modified : Int
  revalidate_at : Int
  css_size : Int
}

///|
/// Island CSS scope
struct IslandCssScope {
  island_id : String
  framework : RendererType
  classes : Array[String]
  scoped_prefix : String
}

///|
/// Theme CSS state
struct ThemeCssState {
  mode : String // "light", "dark", "system"
  variables : Array[(String, String)]
  media_queries : Array[String]
}

///|
/// Build CSS snapshot for determinism testing
struct BuildCssSnapshot {
  build_id : String
  pages : Array[String]
  css_output : String
  css_hash : String
  class_count : Int
}

///|
/// Component CSS dependency
struct ComponentCssDep {
  component_id : String
  parent : String?
  own_classes : Array[String]
  inherited_classes : Array[String]
}

// =============================================================================
// Multi-Locale CSS Integration Tests
// =============================================================================

///|
test "Locale CSS - RTL language direction" {
  let ar_bundle = LocaleCssBundle::{
    locale: "ar",
    direction: "rtl",
    css: "[dir=\"rtl\"]{direction:rtl}[dir=\"rtl\"] .nav{flex-direction:row-reverse}",
    classes: ["_rtl_nav", "_rtl_text"],
    font_family: "Noto Sans Arabic, sans-serif",
  }
  let en_bundle = LocaleCssBundle::{
    locale: "en",
    direction: "ltr",
    css: "",
    classes: [],
    font_family: "Inter, sans-serif",
  }

  inspect(ar_bundle.direction, content="rtl")
  inspect(en_bundle.direction, content="ltr")
  // RTL bundle has additional CSS
  inspect(ar_bundle.css.length() > en_bundle.css.length(), content="true")
}

///|
test "Locale CSS - cache key differentiation" {
  fn locale_cache_key(path : String, locale : String) -> String {
    if locale == "en" || locale == "" {
      path
    } else {
      "/" + locale + path
    }
  }

  let en_key = locale_cache_key("/guide/", "en")
  let ja_key = locale_cache_key("/guide/", "ja")
  let ar_key = locale_cache_key("/guide/", "ar")

  inspect(en_key, content="/guide/")
  inspect(ja_key, content="/ja/guide/")
  inspect(ar_key, content="/ar/guide/")
  // Each locale has unique cache key
  inspect(en_key == ja_key, content="false")
}

///|
test "Locale CSS - logical properties for RTL" {
  // CSS logical properties work for both LTR and RTL
  let logical_classes = [
    ("_ms1", "margin-inline-start", "1rem"),
    ("_me1", "margin-inline-end", "1rem"),
    ("_ps2", "padding-inline-start", "2rem"),
    ("_pe2", "padding-inline-end", "2rem"),
  ]

  for cls in logical_classes {
    // Logical properties don't need RTL override
    inspect(cls.1.contains("inline"), content="true")
  }
  inspect(logical_classes.length(), content="4")
}

///|
test "Locale CSS - font family per locale" {
  let locales : Array[LocaleCssBundle] = [
    {
      locale: "en",
      direction: "ltr",
      css: "",
      classes: [],
      font_family: "Inter, sans-serif",
    },
    {
      locale: "ja",
      direction: "ltr",
      css: "",
      classes: [],
      font_family: "Noto Sans JP, sans-serif",
    },
    {
      locale: "ar",
      direction: "rtl",
      css: "",
      classes: [],
      font_family: "Noto Sans Arabic, sans-serif",
    },
    {
      locale: "zh",
      direction: "ltr",
      css: "",
      classes: [],
      font_family: "Noto Sans SC, sans-serif",
    },
  ]

  // Each locale can have different font
  let mut unique_fonts = 0
  for i = 0; i < locales.length(); i = i + 1 {
    let mut is_unique = true
    for j = 0; j < i; j = j + 1 {
      if locales[i].font_family == locales[j].font_family {
        is_unique = false
      }
    }
    if is_unique {
      unique_fonts = unique_fonts + 1
    }
  }
  inspect(unique_fonts, content="4")
}

///|
test "Locale CSS - split bundle per locale" {
  let config = CssUtilitiesConfig::{
    enabled: true,
    split: true, // Enable splitting
    inline_threshold: 4096,
    source_dirs: ["src"],
  }

  // Each locale gets separate CSS bundle when split enabled
  let locale_bundles : Map[String, Int] = {}
  locale_bundles.set("en", 5000)
  locale_bundles.set("ja", 5200) // Slightly larger (font declarations)
  locale_bundles.set("ar", 5500) // Larger (RTL overrides)

  inspect(config.split, content="true")
  inspect(locale_bundles.length(), content="3")
}

// =============================================================================
// ISR + CSS Caching Tests
// =============================================================================

///|
test "ISR CSS - cache entry structure" {
  let entry = IsrCssEntry::{
    page_path: "/blog/hello-world/",
    html_hash: "abc123def456",
    css_hash: "xyz789uvw012",
    last_modified: 1704067200,
    revalidate_at: 1704070800,
    css_size: 2048,
  }

  inspect(entry.page_path, content="/blog/hello-world/")
  inspect(entry.css_hash.length() > 0, content="true")
  // Revalidate time is after last modified
  inspect(entry.revalidate_at > entry.last_modified, content="true")
}

///|
test "ISR CSS - stale while revalidate scenario" {
  let now = 1704072000
  let entries : Array[IsrCssEntry] = [
    {
      page_path: "/page1/",
      html_hash: "h1",
      css_hash: "c1",
      last_modified: 1704060000,
      revalidate_at: 1704070000, // Past
      css_size: 1000,
    },
    {
      page_path: "/page2/",
      html_hash: "h2",
      css_hash: "c2",
      last_modified: 1704065000,
      revalidate_at: 1704080000, // Future
      css_size: 1200,
    },
  ]

  let mut stale_count = 0
  let mut fresh_count = 0
  for entry in entries {
    if entry.revalidate_at < now {
      stale_count = stale_count + 1
    } else {
      fresh_count = fresh_count + 1
    }
  }

  inspect(stale_count, content="1")
  inspect(fresh_count, content="1")
}

///|
test "ISR CSS - hash change triggers regeneration" {
  let old_entry = IsrCssEntry::{
    page_path: "/products/123/",
    html_hash: "old_html",
    css_hash: "old_css",
    last_modified: 1704000000,
    revalidate_at: 1704003600,
    css_size: 1500,
  }

  let new_content_hash = "new_html"
  let new_css_hash = "new_css"

  // Content changed → need regeneration
  let html_changed = old_entry.html_hash != new_content_hash
  let css_changed = old_entry.css_hash != new_css_hash

  inspect(html_changed, content="true")
  inspect(css_changed, content="true")
}

///|
test "ISR CSS - config hash invalidates all" {
  fn compute_config_hash(config : CssUtilitiesConfig) -> String {
    let parts = [
      config.enabled.to_string(),
      config.split.to_string(),
      config.inline_threshold.to_string(),
    ]
    // Simplified hash
    let mut hash = 0
    for p in parts {
      hash = hash + p.length()
    }
    "config_" + hash.to_string()
  }

  let config1 = CssUtilitiesConfig::default()
  let config2 = CssUtilitiesConfig::{
    enabled: true,
    split: true, // Changed
    inline_threshold: 4096,
    source_dirs: ["src"],
  }

  let hash1 = compute_config_hash(config1)
  let hash2 = compute_config_hash(config2)

  // Config change produces different hash
  inspect(hash1 == hash2, content="false")
}

///|
test "ISR CSS - TTL based revalidation" {
  let revalidate_seconds = 300 // 5 minutes

  fn should_revalidate(
    last_modified : Int,
    revalidate_interval : Int,
    now : Int
  ) -> Bool {
    now >= last_modified + revalidate_interval
  }

  let last_modified = 1704067200
  let now_fresh = 1704067400 // 200 seconds later
  let now_stale = 1704067600 // 400 seconds later

  inspect(
    should_revalidate(last_modified, revalidate_seconds, now_fresh),
    content="false",
  )
  inspect(
    should_revalidate(last_modified, revalidate_seconds, now_stale),
    content="true",
  )
}

// =============================================================================
// Island CSS Isolation Tests
// =============================================================================

///|
test "Island CSS - framework scope prefixes" {
  let islands : Array[IslandCssScope] = [
    {
      island_id: "counter",
      framework: RendererType::ReactRenderer,
      classes: ["_btn", "_count"],
      scoped_prefix: "react_",
    },
    {
      island_id: "counter",
      framework: RendererType::PreactRenderer,
      classes: ["_btn", "_count"],
      scoped_prefix: "preact_",
    },
    {
      island_id: "counter",
      framework: RendererType::LunaRenderer,
      classes: ["_btn", "_count"],
      scoped_prefix: "luna_",
    },
  ]

  // Same island ID with different frameworks
  for island in islands {
    inspect(island.island_id, content="counter")
  }

  // Different prefixes for different frameworks
  inspect(islands[0].scoped_prefix, content="react_")
  inspect(islands[1].scoped_prefix, content="preact_")
  inspect(islands[2].scoped_prefix, content="luna_")
}

///|
test "Island CSS - class collision detection" {
  let react_island = IslandCssScope::{
    island_id: "widget",
    framework: RendererType::ReactRenderer,
    classes: ["_a1b2", "_c3d4"],
    scoped_prefix: "react_",
  }
  let luna_island = IslandCssScope::{
    island_id: "widget",
    framework: RendererType::LunaRenderer,
    classes: ["_a1b2", "_e5f6"], // _a1b2 collision!
    scoped_prefix: "luna_",
  }

  // Detect collision
  let collisions : Array[String] = []
  for cls in react_island.classes {
    for other in luna_island.classes {
      if cls == other {
        collisions.push(cls)
      }
    }
  }

  inspect(collisions.length(), content="1")
  inspect(collisions[0], content="_a1b2")
}

///|
test "Island CSS - mixed framework page" {
  // Page with multiple framework islands
  let page_islands : Array[IslandCssScope] = [
    {
      island_id: "header-nav",
      framework: RendererType::ReactRenderer,
      classes: ["_nav", "_link"],
      scoped_prefix: "react_",
    },
    {
      island_id: "counter",
      framework: RendererType::PreactRenderer,
      classes: ["_btn", "_count"],
      scoped_prefix: "preact_",
    },
    {
      island_id: "chart",
      framework: RendererType::LunaRenderer,
      classes: ["_chart", "_axis"],
      scoped_prefix: "luna_",
    },
  ]

  // Collect all unique classes
  let all_classes : Array[String] = []
  for island in page_islands {
    for cls in island.classes {
      all_classes.push(cls)
    }
  }

  inspect(all_classes.length(), content="6")

  // Count frameworks
  let framework_count : Map[String, Int] = {}
  for island in page_islands {
    let key = island.framework.to_string()
    framework_count.set(key, framework_count.get(key).unwrap_or(0) + 1)
  }
  inspect(framework_count.length(), content="3")
}

///|
test "Island CSS - client-only vs SSR isolation" {
  let ssr_island = IslandCssScope::{
    island_id: "product-card",
    framework: RendererType::ReactRenderer,
    classes: ["_card", "_img", "_price"],
    scoped_prefix: "ssr_",
  }
  let client_only_island = IslandCssScope::{
    island_id: "canvas-editor",
    framework: RendererType::ClientOnlyRenderer,
    classes: ["_canvas", "_toolbar"],
    scoped_prefix: "client_",
  }

  // SSR island needs CSS in initial HTML
  inspect(ssr_island.framework == RendererType::ReactRenderer, content="true")
  // Client-only island CSS can be deferred
  inspect(
    client_only_island.framework == RendererType::ClientOnlyRenderer,
    content="true",
  )
}

// =============================================================================
// Theme / Dark Mode CSS Tests
// =============================================================================

///|
test "Theme CSS - variable cascade" {
  let light_theme = ThemeCssState::{
    mode: "light",
    variables: [
      ("--bg-color", "#ffffff"),
      ("--text-color", "#1a1a1a"),
      ("--primary-color", "#fbbf24"),
    ],
    media_queries: [],
  }
  let dark_theme = ThemeCssState::{
    mode: "dark",
    variables: [
      ("--bg-color", "#1a1a1a"),
      ("--text-color", "#f5f5f5"),
      ("--primary-color", "#fbbf24"), // Same primary
    ],
    media_queries: ["@media(prefers-color-scheme:dark)"],
  }

  // Primary color same in both themes
  inspect(light_theme.variables[2].1, content="#fbbf24")
  inspect(dark_theme.variables[2].1, content="#fbbf24")
  // Background differs
  inspect(light_theme.variables[0].1 == dark_theme.variables[0].1, content="false")
}

///|
test "Theme CSS - media query vs class toggle" {
  fn generate_theme_css(mode : String, variables : Array[(String, String)]) -> String {
    let mut css = ""
    match mode {
      "light" => {
        css = css + ":root{"
        for v in variables {
          css = css + v.0 + ":" + v.1 + ";"
        }
        css = css + "}"
      }
      "dark" => {
        css = css + "html.dark{"
        for v in variables {
          css = css + v.0 + ":" + v.1 + ";"
        }
        css = css + "}"
        css = css + "@media(prefers-color-scheme:dark){:root{"
        for v in variables {
          css = css + v.0 + ":" + v.1 + ";"
        }
        css = css + "}}"
      }
      _ => ()
    }
    css
  }

  let dark_css = generate_theme_css(
    "dark",
    [("--bg", "#000"), ("--fg", "#fff")],
  )

  // Both class and media query selectors present
  inspect(dark_css.contains("html.dark"), content="true")
  inspect(dark_css.contains("prefers-color-scheme:dark"), content="true")
}

///|
test "Theme CSS - specificity resolution" {
  // CSS specificity order (highest to lowest):
  // 1. html.dark (class selector) - user preference
  // 2. @media prefers-color-scheme:dark - OS preference
  // 3. :root (type selector) - default

  let selectors = [
    ("html.dark", 10),  // Class specificity
    (":root", 1),       // Type specificity
  ]

  // html.dark wins over :root
  inspect(selectors[0].1 > selectors[1].1, content="true")
}

///|
test "Theme CSS - ISR with theme state" {
  // ISR caches page but theme is client-side state
  let cached_page = IsrCssEntry::{
    page_path: "/settings/",
    html_hash: "static_html",
    css_hash: "theme_agnostic",
    last_modified: 1704067200,
    revalidate_at: 1704070800,
    css_size: 3000,
  }

  // Theme CSS should be separate from page CSS for ISR
  // Page HTML is cached, theme CSS variables apply at runtime
  inspect(cached_page.css_hash, content="theme_agnostic")
}

///|
test "Theme CSS - custom CSS injection" {
  let theme_config = ThemeConfig::default()
  guard theme_config.primary_color is Some(primary) else {
    fail("Expected primary color")
  }

  // Custom CSS can reference theme variables
  let custom_css = ".custom-btn{background:var(--primary-color)}"
  inspect(custom_css.contains("var(--primary-color)"), content="true")
  inspect(primary, content="#fbbf24")
}

// =============================================================================
// CSS Registry Determinism Tests
// =============================================================================

///|
test "Registry - deterministic hash for same input" {
  fn djb2_hash(s : String) -> UInt {
    let mut hash : UInt = 5381
    for i = 0; i < s.length(); i = i + 1 {
      let c = s[i]
      hash = ((hash << 5) + hash) + c.to_uint()
    }
    hash
  }

  // Same input always produces same hash
  let input = "display:flex"
  let hash1 = djb2_hash(input)
  let hash2 = djb2_hash(input)
  let hash3 = djb2_hash(input)

  inspect(hash1 == hash2, content="true")
  inspect(hash2 == hash3, content="true")
}

///|
test "Registry - build snapshot consistency" {
  let build1 = BuildCssSnapshot::{
    build_id: "build_001",
    pages: ["/", "/about/", "/blog/"],
    css_output: "._a{display:flex}._b{color:#333}._c{margin:0}",
    css_hash: "snapshot_hash_123",
    class_count: 3,
  }
  let build2 = BuildCssSnapshot::{
    build_id: "build_002",
    pages: ["/", "/about/", "/blog/"], // Same pages
    css_output: "._a{display:flex}._b{color:#333}._c{margin:0}", // Same CSS
    css_hash: "snapshot_hash_123", // Same hash
    class_count: 3,
  }

  // Identical builds produce identical output
  inspect(build1.css_output == build2.css_output, content="true")
  inspect(build1.css_hash == build2.css_hash, content="true")
}

///|
test "Registry - class ordering stability" {
  // CSS output order should be stable
  let declarations : Array[(String, String)] = [
    ("_z", "z-index:10"),
    ("_a", "align-items:center"),
    ("_m", "margin:0"),
  ]

  // Sort by class name for consistent output
  let sorted = declarations.copy()
  // Simple bubble sort for test
  for i = 0; i < sorted.length(); i = i + 1 {
    for j = 0; j < sorted.length() - 1 - i; j = j + 1 {
      if sorted[j].0 > sorted[j + 1].0 {
        let tmp = sorted[j]
        sorted[j] = sorted[j + 1]
        sorted[j + 1] = tmp
      }
    }
  }

  inspect(sorted[0].0, content="_a")
  inspect(sorted[1].0, content="_m")
  inspect(sorted[2].0, content="_z")
}

///|
test "Registry - incremental build consistency" {
  // Adding same declarations in different order should produce same result
  let registry1 : Map[String, String] = {}
  registry1.set("display:flex", "_a")
  registry1.set("color:#333", "_b")
  registry1.set("margin:0", "_c")

  let registry2 : Map[String, String] = {}
  registry2.set("margin:0", "_c")
  registry2.set("display:flex", "_a")
  registry2.set("color:#333", "_b")

  // Same entries regardless of insertion order
  inspect(registry1.length() == registry2.length(), content="true")
  inspect(registry1.get("display:flex"), content="Some(\"_a\")")
  inspect(registry2.get("display:flex"), content="Some(\"_a\")")
}

// =============================================================================
// Component CSS Composition Tests
// =============================================================================

///|
test "Component CSS - dependency tree" {
  let components : Array[ComponentCssDep] = [
    {
      component_id: "page",
      parent: None,
      own_classes: ["_page_layout"],
      inherited_classes: [],
    },
    {
      component_id: "header",
      parent: Some("page"),
      own_classes: ["_header", "_sticky"],
      inherited_classes: ["_page_layout"],
    },
    {
      component_id: "nav",
      parent: Some("header"),
      own_classes: ["_nav", "_flex"],
      inherited_classes: ["_page_layout", "_header", "_sticky"],
    },
  ]

  // Nav inherits from header which inherits from page
  let nav = components[2]
  inspect(nav.inherited_classes.length(), content="3")
  inspect(nav.inherited_classes[0], content="_page_layout")
}

///|
test "Component CSS - total class collection" {
  let header_deps = ComponentCssDep::{
    component_id: "header",
    parent: None,
    own_classes: ["_header_bg", "_header_border"],
    inherited_classes: [],
  }
  let nav_deps = ComponentCssDep::{
    component_id: "nav",
    parent: Some("header"),
    own_classes: ["_nav_flex", "_nav_gap"],
    inherited_classes: ["_header_bg", "_header_border"],
  }
  let logo_deps = ComponentCssDep::{
    component_id: "logo",
    parent: Some("nav"),
    own_classes: ["_logo_img"],
    inherited_classes: ["_header_bg", "_header_border", "_nav_flex", "_nav_gap"],
  }

  // Collect all unique classes for page
  let all_classes : Map[String, Bool] = {}
  for cls in header_deps.own_classes {
    all_classes.set(cls, true)
  }
  for cls in nav_deps.own_classes {
    all_classes.set(cls, true)
  }
  for cls in logo_deps.own_classes {
    all_classes.set(cls, true)
  }

  inspect(all_classes.length(), content="5")
}

///|
test "Component CSS - conditional rendering impact" {
  // Component rendered conditionally
  let base_classes = ["_layout", "_container"]
  let conditional_classes = ["_sidebar", "_sidebar_open"]

  fn get_required_classes(has_sidebar : Bool) -> Array[String] {
    let result : Array[String] = []
    for cls in base_classes {
      result.push(cls)
    }
    if has_sidebar {
      for cls in conditional_classes {
        result.push(cls)
      }
    }
    result
  }

  let with_sidebar = get_required_classes(true)
  let without_sidebar = get_required_classes(false)

  inspect(with_sidebar.length(), content="4")
  inspect(without_sidebar.length(), content="2")
}

///|
test "Component CSS - override detection" {
  // Child component overrides parent style
  let parent_style = ("padding", "1rem")
  let child_style = ("padding", "2rem") // Override

  fn detect_override(
    parent_prop : String,
    child_prop : String
  ) -> Bool {
    parent_prop == child_prop
  }

  inspect(detect_override(parent_style.0, child_style.0), content="true")
}

// =============================================================================
// Critical CSS / Above-the-Fold Tests
// =============================================================================

///|
test "Critical CSS - layout classes priority" {
  // Classes needed for initial render (above-the-fold)
  let critical_classes = [
    "_layout",      // Page layout
    "_header",      // Header visible
    "_nav",         // Navigation
    "_hero",        // Hero section
  ]
  // Classes for below-the-fold content
  let deferred_classes = [
    "_footer",      // Footer (below fold)
    "_comments",    // Comments section
    "_related",     // Related posts
  ]

  // Critical CSS should be inlined
  let critical_size = critical_classes.length() * 25 // Estimate
  let deferred_size = deferred_classes.length() * 25

  inspect(critical_size, content="100")
  inspect(deferred_size, content="75")
  // Critical CSS smaller, good for inlining
  inspect(critical_size < 4096, content="true")
}

///|
test "Critical CSS - inline threshold with minification" {
  let config = CssUtilitiesConfig::default()

  // Pre-minification size
  let pretty_size = 5000
  // After minification (~30% reduction)
  let minified_size = 3500

  // Pretty would be external, minified can be inline
  let pretty_inline = pretty_size <= config.inline_threshold
  let minified_inline = minified_size <= config.inline_threshold

  inspect(pretty_inline, content="false")
  inspect(minified_inline, content="true")
}

// =============================================================================
// CSS Hydration Consistency Tests
// =============================================================================

///|
test "Hydration CSS - SSR class must exist in CSS" {
  // Simulate SSR output with classes
  let ssr_html_classes = ["_a1b2", "_c3d4", "_e5f6"]

  // CSS registry must contain all SSR classes
  let css_registry : Map[String, String] = {}
  css_registry.set("_a1b2", "display:flex")
  css_registry.set("_c3d4", "gap:1rem")
  css_registry.set("_e5f6", "padding:1rem")

  // Verify all SSR classes have CSS rules
  let mut missing = 0
  for cls in ssr_html_classes {
    if css_registry.get(cls) is None {
      missing = missing + 1
    }
  }
  inspect(missing, content="0")
}

///|
test "Hydration CSS - dynamic class addition" {
  // Client adds class dynamically after hydration
  let initial_classes = ["_static1", "_static2"]
  let dynamic_class = "_hover_effect"

  // CSS must include dynamic class even if not in SSR output
  let css_registry : Map[String, Bool] = {}
  for cls in initial_classes {
    css_registry.set(cls, true)
  }
  css_registry.set(dynamic_class, true)

  inspect(css_registry.length(), content="3")
  inspect(css_registry.get(dynamic_class) is Some(_), content="true")
}

///|
test "Hydration CSS - FOUC prevention" {
  // Flash of Unstyled Content prevention
  // CSS must be available before HTML renders

  let css_injection_points = [
    ("head_inline", true),   // Best: inline in <head>
    ("head_link", true),     // Good: <link> in <head>
    ("body_end", false),     // Bad: CSS after content
  ]

  for point in css_injection_points {
    if point.0 == "head_inline" || point.0 == "head_link" {
      inspect(point.1, content="true")
    }
  }
}

// =============================================================================
// Edge Cases and Error Handling
// =============================================================================

///|
test "Edge case - empty locale CSS bundle" {
  let empty_bundle = LocaleCssBundle::{
    locale: "en",
    direction: "ltr",
    css: "",
    classes: [],
    font_family: "",
  }
  inspect(empty_bundle.css.is_empty(), content="true")
  inspect(empty_bundle.classes.is_empty(), content="true")
}

///|
test "Edge case - ISR entry with zero TTL" {
  let instant_revalidate = IsrCssEntry::{
    page_path: "/realtime/",
    html_hash: "rt",
    css_hash: "rt_css",
    last_modified: 1704067200,
    revalidate_at: 1704067200, // Same as last_modified (instant)
    css_size: 500,
  }
  // Zero TTL means always revalidate
  inspect(
    instant_revalidate.revalidate_at == instant_revalidate.last_modified,
    content="true",
  )
}

///|
test "Edge case - deeply nested component hierarchy" {
  // 5 levels of component nesting
  let depth = 5
  let mut total_inherited = 0
  let mut current_inherited = 0

  for i = 0; i < depth; i = i + 1 {
    let own_classes = 2 // Each component adds 2 classes
    current_inherited = current_inherited + own_classes
    total_inherited = total_inherited + current_inherited
  }

  // Total classes grows quadratically with depth
  // 2 + 4 + 6 + 8 + 10 = 30
  inspect(total_inherited, content="30")
}

///|
test "Edge case - theme with many variables" {
  let many_variables : Array[(String, String)] = []
  for i = 0; i < 50; i = i + 1 {
    many_variables.push(("--color-" + i.to_string(), "#" + i.to_string()))
  }

  let theme = ThemeCssState::{
    mode: "light",
    variables: many_variables,
    media_queries: [],
  }

  inspect(theme.variables.length(), content="50")
}

///|
test "Edge case - island with no CSS classes" {
  let no_css_island = IslandCssScope::{
    island_id: "pure-logic",
    framework: RendererType::LunaRenderer,
    classes: [], // No CSS needed
    scoped_prefix: "luna_",
  }

  inspect(no_css_island.classes.is_empty(), content="true")
}

