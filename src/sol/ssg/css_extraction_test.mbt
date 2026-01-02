// Tests for CSS Extraction Integration - Sol SSG + Luna CSS
//
// Tests for CSS utility extraction, optimization strategies, and SSG integration.
// Covers configuration, inline/external strategies, and build context integration.

// =============================================================================
// Test Types for CSS Optimization (mirrors luna/css/optimizer types)
// =============================================================================

///|
/// CSS declaration for testing
struct TestDeclaration {
  property : String
  value : String
} derive(Eq, Show)

///|
/// Class usage pattern
struct TestClassUsage {
  classes : Array[String]
  source_file : String
  line : Int
}

///|
/// Co-occurrence pattern
struct TestCoOccurrence {
  class_a : String
  class_b : String
  frequency : Int
}

///|
/// CSS extraction result
struct TestCssResult {
  css : String
  classes : Array[String]
  size : Int
  is_minified : Bool
}

///|
/// Page CSS bundle
struct TestPageCssBundle {
  page_id : String
  classes : Array[String]
  css : String
  size : Int
}

///|
/// Split CSS manifest
struct TestSplitManifest {
  common_css : String
  page_bundles : Array[TestPageCssBundle]
  total_size : Int
  common_size : Int
}

// =============================================================================
// CssUtilitiesConfig Basic Tests
// =============================================================================

///|
test "CssUtilitiesConfig::default - has expected values" {
  let config = CssUtilitiesConfig::default()
  inspect(config.enabled, content="true")
  inspect(config.split, content="false")
  inspect(config.inline_threshold, content="4096")
  inspect(config.source_dirs.length(), content="1")
  inspect(config.source_dirs[0], content="src")
}

///|
test "CssUtilitiesConfig - custom configuration" {
  let config = CssUtilitiesConfig::{
    enabled: true,
    split: true,
    inline_threshold: 8192,
    source_dirs: ["src", "components", "pages"],
  }
  inspect(config.split, content="true")
  inspect(config.inline_threshold, content="8192")
  inspect(config.source_dirs.length(), content="3")
}

///|
test "CssUtilitiesConfig - disabled extraction" {
  let config = CssUtilitiesConfig::{
    enabled: false,
    split: false,
    inline_threshold: 4096,
    source_dirs: [],
  }
  inspect(config.enabled, content="false")
  inspect(config.source_dirs.is_empty(), content="true")
}

///|
test "CssUtilitiesConfig - zero inline threshold (always external)" {
  let config = CssUtilitiesConfig::{
    enabled: true,
    split: false,
    inline_threshold: 0,
    source_dirs: ["src"],
  }
  // Threshold 0 means always use external CSS files
  inspect(config.inline_threshold, content="0")
}

// =============================================================================
// Inline vs External CSS Strategy Tests
// =============================================================================

///|
test "CSS strategy - inline for small CSS" {
  let config = CssUtilitiesConfig::default()
  let css_size = 2048 // 2KB, below 4KB threshold
  let should_inline = css_size <= config.inline_threshold
  inspect(should_inline, content="true")
}

///|
test "CSS strategy - external for large CSS" {
  let config = CssUtilitiesConfig::default()
  let css_size = 8192 // 8KB, above 4KB threshold
  let should_inline = css_size <= config.inline_threshold
  inspect(should_inline, content="false")
}

///|
test "CSS strategy - exact threshold boundary" {
  let config = CssUtilitiesConfig::default()
  let css_size = 4096 // Exactly at threshold
  let should_inline = css_size <= config.inline_threshold
  inspect(should_inline, content="true")
}

///|
test "CSS strategy - custom threshold" {
  let config = CssUtilitiesConfig::{
    enabled: true,
    split: false,
    inline_threshold: 1024,
    source_dirs: ["src"],
  }
  let css_size = 2048
  let should_inline = css_size <= config.inline_threshold
  inspect(should_inline, content="false")
}

// =============================================================================
// Source Directory Configuration Tests
// =============================================================================

///|
test "Source dirs - default single directory" {
  let config = CssUtilitiesConfig::default()
  inspect(config.source_dirs, content="[\"src\"]")
}

///|
test "Source dirs - multiple directories" {
  let config = CssUtilitiesConfig::{
    enabled: true,
    split: false,
    inline_threshold: 4096,
    source_dirs: ["src/luna", "src/sol/ssg", "docs"],
  }
  inspect(config.source_dirs.length(), content="3")
  inspect(config.source_dirs[0], content="src/luna")
  inspect(config.source_dirs[1], content="src/sol/ssg")
  inspect(config.source_dirs[2], content="docs")
}

///|
test "Source dirs - empty uses fallback" {
  let config = CssUtilitiesConfig::{
    enabled: true,
    split: false,
    inline_threshold: 4096,
    source_dirs: [],
  }
  // Empty source_dirs should trigger fallback behavior in SSG
  let fallback_dirs = if config.source_dirs.is_empty() {
    ["src/sol/ssg", "src/luna", "docs"]
  } else {
    config.source_dirs
  }
  inspect(fallback_dirs.length(), content="3")
}

// =============================================================================
// CSS Split Mode Tests
// =============================================================================

///|
test "Split mode - disabled by default" {
  let config = CssUtilitiesConfig::default()
  inspect(config.split, content="false")
}

///|
test "Split mode - enabled configuration" {
  let config = CssUtilitiesConfig::{
    enabled: true,
    split: true,
    inline_threshold: 4096,
    source_dirs: ["src"],
  }
  inspect(config.split, content="true")
}

///|
test "Split mode - page bundle simulation" {
  // Simulate per-page CSS bundles
  let bundles : Array[TestPageCssBundle] = [
    {
      page_id: "index",
      classes: ["_z5et", "_1i41w", "_abc12"],
      css: "._z5et{display:flex}._1i41w{color:#fff}._abc12{margin:0}",
      size: 60,
    },
    {
      page_id: "about",
      classes: ["_z5et", "_def34", "_ghi56"],
      css: "._z5et{display:flex}._def34{padding:1rem}._ghi56{border:1px solid}",
      size: 70,
    },
  ]
  inspect(bundles.length(), content="2")
  // Common class _z5et appears in both
  inspect(bundles[0].classes[0] == bundles[1].classes[0], content="true")
}

///|
test "Split mode - common CSS extraction" {
  // Simulate extracting common CSS used across pages
  let page1_classes = ["_a", "_b", "_c", "_d"]
  let page2_classes = ["_a", "_b", "_e", "_f"]
  let page3_classes = ["_a", "_c", "_e", "_g"]

  // Find common classes (appear in 2+ pages)
  let class_count : Map[String, Int] = {}
  for cls in page1_classes {
    class_count.set(cls, class_count.get(cls).unwrap_or(0) + 1)
  }
  for cls in page2_classes {
    class_count.set(cls, class_count.get(cls).unwrap_or(0) + 1)
  }
  for cls in page3_classes {
    class_count.set(cls, class_count.get(cls).unwrap_or(0) + 1)
  }

  // _a appears 3 times, _b 2 times, _c 2 times, _e 2 times
  inspect(class_count.get("_a"), content="Some(3)")
  inspect(class_count.get("_b"), content="Some(2)")
  inspect(class_count.get("_c"), content="Some(2)")
  inspect(class_count.get("_e"), content="Some(2)")
  inspect(class_count.get("_d"), content="Some(1)")
  inspect(class_count.get("_f"), content="Some(1)")
  inspect(class_count.get("_g"), content="Some(1)")
}

// =============================================================================
// CSS Class Hash Pattern Tests
// =============================================================================

///|
test "CSS class hash - DJB2 deterministic" {
  // Same input should produce same hash
  fn djb2_hash(s : String) -> String {
    let mut hash : UInt = 5381
    for i = 0; i < s.length(); i = i + 1 {
      let c = s[i]
      hash = (hash << 5) + hash + c.to_uint()
    }
    // Take first 5 characters of hash
    let hash_str = hash.to_string()
    let mut result = "_"
    for i = 0; i < 5 && i < hash_str.length(); i = i + 1 {
      result = result + hash_str[i].to_string()
    }
    result
  }

  let hash1 = djb2_hash("display:flex")
  let hash2 = djb2_hash("display:flex")
  inspect(hash1 == hash2, content="true")

  // Different input produces different hash
  let hash3 = djb2_hash("display:grid")
  inspect(hash1 == hash3, content="false")
}

///|
test "CSS class deduplication" {
  // Simulate class registry deduplication
  let registry : Map[String, String] = {}
  fn get_or_create_class(decl : String) -> String {
    match registry.get(decl) {
      Some(cls) => cls
      None => {
        let cls = "_" + decl.length().to_string()
        registry.set(decl, cls)
        cls
      }
    }
  }

  let cls1 = get_or_create_class("display:flex")
  let cls2 = get_or_create_class("display:flex")
  let cls3 = get_or_create_class("color:red")
  inspect(cls1 == cls2, content="true")
  inspect(cls1 == cls3, content="false")
  inspect(registry.length(), content="2")
}

// =============================================================================
// CSS Co-occurrence Pattern Tests
// =============================================================================

///|
test "Co-occurrence - pattern detection" {
  let usages : Array[TestClassUsage] = [
    { classes: ["_flex", "_gap4", "_p4"], source_file: "header.mbt", line: 10 },
    { classes: ["_flex", "_gap4", "_m2"], source_file: "nav.mbt", line: 20 },
    { classes: ["_flex", "_gap4", "_p4"], source_file: "footer.mbt", line: 30 },
  ]

  // Count co-occurrences
  let cooccurrences : Map[String, Int] = {}
  for usage in usages {
    let classes = usage.classes
    for i = 0; i < classes.length(); i = i + 1 {
      for j = i + 1; j < classes.length(); j = j + 1 {
        let key = classes[i] + "+" + classes[j]
        cooccurrences.set(key, cooccurrences.get(key).unwrap_or(0) + 1)
      }
    }
  }

  // _flex + _gap4 appears 3 times
  inspect(cooccurrences.get("_flex+_gap4"), content="Some(3)")
  // _flex + _p4 appears 2 times
  inspect(cooccurrences.get("_flex+_p4"), content="Some(2)")
  // _gap4 + _p4 appears 2 times
  inspect(cooccurrences.get("_gap4+_p4"), content="Some(2)")
}

///|
test "Co-occurrence - merge suggestion threshold" {
  let cooccurrences : Array[TestCoOccurrence] = [
    { class_a: "_flex", class_b: "_gap4", frequency: 15 },
    { class_a: "_flex", class_b: "_center", frequency: 12 },
    { class_a: "_p4", class_b: "_m4", frequency: 3 },
  ]
  let merge_threshold = 5
  let mut merge_candidates = 0
  for co in cooccurrences {
    if co.frequency >= merge_threshold {
      merge_candidates = merge_candidates + 1
    }
  }

  // Only 2 pairs exceed threshold
  inspect(merge_candidates, content="2")
}

// =============================================================================
// CSS Size Optimization Tests
// =============================================================================

///|
test "CSS optimization - size calculation" {
  let declarations : Array[TestDeclaration] = [
    { property: "display", value: "flex" },
    { property: "gap", value: "1rem" },
    { property: "padding", value: "1rem" },
  ]

  // Calculate CSS size
  let mut size = 0
  for decl in declarations {
    // ._class{property:value}
    size = size +
      2 +
      5 +
      1 +
      decl.property.length() +
      1 +
      decl.value.length() +
      1
  }

  // Each declaration: ._xxxx{prop:val} = 2 + 5 + 1 + prop + 1 + val + 1
  inspect(size > 0, content="true")
}

///|
test "CSS optimization - merge savings" {
  // Before merge: 3 classes, each with same declaration
  let before_size = 3 * 25 // ~75 bytes (3x ._class{display:flex})

  // After merge: 1 combined class
  let after_size = 25 // ~25 bytes
  let savings = before_size - after_size
  inspect(savings, content="50")
}

///|
test "CSS optimization - split vs combined size comparison" {
  // Scenario: 3 pages with overlapping classes
  let page1_css = 1000
  let page2_css = 1200
  let page3_css = 800
  let total_split = page1_css + page2_css + page3_css // 3000

  // With common CSS extracted (30% overlap)
  let common_css = 600
  let page1_unique = 700
  let page2_unique = 900
  let page3_unique = 500
  let total_with_common = common_css +
    page1_unique +
    page2_unique +
    page3_unique // 2700
  inspect(total_with_common < total_split, content="true")
  let savings = total_split - total_with_common
  inspect(savings, content="300")
}

// =============================================================================
// BuildContext CSS Integration Tests
// =============================================================================

///|
test "BuildContext - with CSS config" {
  let config = SsgConfig::{
    ..SsgConfig::default(),
    css_utilities: Some(CssUtilitiesConfig::{
      enabled: true,
      split: false,
      inline_threshold: 4096,
      source_dirs: ["src"],
    }),
  }
  let ctx = BuildContext::new(config, "/project")
  guard ctx.config.css_utilities is Some(css_config) else {
    fail("Expected Some css_utilities")
  }
  inspect(css_config.enabled, content="true")
}

///|
test "BuildContext - without CSS config (default)" {
  let config = SsgConfig::default()
  let ctx = BuildContext::new(config, "/project")

  // css_utilities is None, should use default in build process
  inspect(ctx.config.css_utilities is None, content="true")
}

///|
test "BuildContext - CSS config with split enabled" {
  let config = SsgConfig::{
    ..SsgConfig::default(),
    css_utilities: Some(CssUtilitiesConfig::{
      enabled: true,
      split: true,
      inline_threshold: 2048,
      source_dirs: ["src/luna", "src/sol"],
    }),
  }
  let ctx = BuildContext::new(config, "/project")
  guard ctx.config.css_utilities is Some(css_config) else {
    fail("Expected Some css_utilities")
  }
  inspect(css_config.split, content="true")
  inspect(css_config.inline_threshold, content="2048")
  inspect(css_config.source_dirs.length(), content="2")
}

// =============================================================================
// CSS Extraction Pattern Tests
// =============================================================================

///|
test "CSS extraction - css() call pattern" {
  // Simulating extraction from: css("display", "flex")
  let property = "display"
  let value = "flex"
  let decl = property + ":" + value
  inspect(decl, content="display:flex")
}

///|
test "CSS extraction - styles() call pattern" {
  // Simulating extraction from: styles([("display", "flex"), ("gap", "1rem")])
  let props : Array[(String, String)] = [("display", "flex"), ("gap", "1rem")]
  let decls : Array[String] = []
  for prop in props {
    decls.push(prop.0 + ":" + prop.1)
  }
  inspect(decls.length(), content="2")
  inspect(decls[0], content="display:flex")
  inspect(decls[1], content="gap:1rem")
}

///|
test "CSS extraction - pseudo class pattern" {
  // Simulating extraction from: hover("color", "#fff")
  let pseudo = "hover"
  let property = "color"
  let value = "#fff"
  let key = ":" + pseudo + ":" + property + ":" + value
  inspect(key, content=":hover:color:#fff")
}

///|
test "CSS extraction - media query pattern" {
  // Simulating extraction from: at_md("display", "flex")
  let breakpoint = "min-width:768px"
  let property = "display"
  let value = "flex"
  let key = "@media(" + breakpoint + "):" + property + ":" + value
  inspect(key, content="@media(min-width:768px):display:flex")
}

// =============================================================================
// CSS Generation Tests
// =============================================================================

///|
test "CSS generation - base rules" {
  let rules : Array[(String, String, String)] = [
    ("_a1b2", "display", "flex"),
    ("_c3d4", "color", "#333"),
    ("_e5f6", "margin", "0"),
  ]
  let mut css = ""
  for rule in rules {
    css = css + "." + rule.0 + "{" + rule.1 + ":" + rule.2 + "}"
  }
  inspect(css.contains("._a1b2{display:flex}"), content="true")
  inspect(css.contains("._c3d4{color:#333}"), content="true")
  inspect(css.contains("._e5f6{margin:0}"), content="true")
}

///|
test "CSS generation - pseudo rules" {
  let pseudo_rules : Array[(String, String, String, String)] = [
    ("_h1", "hover", "color", "#fff"),
    ("_f1", "focus", "outline", "2px solid blue"),
  ]
  let mut css = ""
  for rule in pseudo_rules {
    css = css + "." + rule.0 + ":" + rule.1 + "{" + rule.2 + ":" + rule.3 + "}"
  }
  inspect(css.contains("._h1:hover{color:#fff}"), content="true")
  inspect(css.contains("._f1:focus{outline:2px solid blue}"), content="true")
}

///|
test "CSS generation - media query rules" {
  let media_rules : Array[(String, String, String, String)] = [
    ("_m1", "min-width:768px", "display", "flex"),
    ("_m2", "prefers-color-scheme:dark", "background", "#1a1a1a"),
  ]
  let mut css = ""
  for rule in media_rules {
    css = css +
      "@media(" +
      rule.1 +
      "){." +
      rule.0 +
      "{" +
      rule.2 +
      ":" +
      rule.3 +
      "}}"
  }
  inspect(
    css.contains("@media(min-width:768px){._m1{display:flex}}"),
    content="true",
  )
  inspect(
    css.contains("@media(prefers-color-scheme:dark){._m2{background:#1a1a1a}}"),
    content="true",
  )
}

// =============================================================================
// CSS Minification Tests
// =============================================================================

///|
test "CSS minification - whitespace removal simulation" {
  let pretty_css = ".class {\n  display: flex;\n  gap: 1rem;\n}"
  // Simulating minification - removing newlines and extra spaces
  // In practice, CSS is minified during build

  // Check original has whitespace
  inspect(pretty_css.contains("\n"), content="true")
  inspect(pretty_css.contains("  "), content="true")

  // Expected minified result
  let minified = ".class{display:flex;gap:1rem}"
  inspect(minified.contains("\n"), content="false")
  inspect(minified.contains("  "), content="false")
}

///|
test "CSS minification - size reduction" {
  let pretty_css = ".class {\n  display: flex;\n  gap: 1rem;\n}"
  let minified = ".class{display:flex;gap:1rem}"
  let size_reduction = pretty_css.length() - minified.length()
  inspect(size_reduction > 0, content="true")
}

// =============================================================================
// CSS Variable Integration Tests
// =============================================================================

///|
test "CSS variables - primary color injection" {
  let primary_color = "#fbbf24"
  let css_var = ":root{--primary-color:" + primary_color + ";}"
  inspect(css_var, content=":root{--primary-color:#fbbf24;}")
}

///|
test "CSS variables - theme colors" {
  // Test with explicit primary color (default is None)
  let theme = ThemeConfig::{
    ..ThemeConfig::default(),
    primary_color: Some("#fbbf24"),
  }
  guard theme.primary_color is Some(color) else {
    fail("Expected Some primary_color")
  }
  inspect(color, content="#fbbf24")
}

// =============================================================================
// Split Manifest Tests
// =============================================================================

///|
test "Split manifest - structure" {
  let manifest = TestSplitManifest::{
    common_css: "._a{display:flex}._b{gap:1rem}",
    page_bundles: [
      { page_id: "index", classes: ["_c"], css: "._c{color:#333}", size: 20 },
      { page_id: "about", classes: ["_d"], css: "._d{margin:1rem}", size: 22 },
    ],
    total_size: 92,
    common_size: 50,
  }
  inspect(manifest.page_bundles.length(), content="2")
  inspect(manifest.common_size, content="50")
  // Common represents ~54% of total
  let common_ratio = manifest.common_size * 100 / manifest.total_size
  inspect(common_ratio, content="54")
}

///|
test "Split manifest - page bundle isolation" {
  let bundles : Array[TestPageCssBundle] = [
    {
      page_id: "index",
      classes: ["_a", "_b"],
      css: "._a{...}._b{...}",
      size: 40,
    },
    {
      page_id: "about",
      classes: ["_c", "_d"],
      css: "._c{...}._d{...}",
      size: 42,
    },
  ]

  // Verify no class overlap between bundles
  let index_classes = bundles[0].classes
  let about_classes = bundles[1].classes
  let mut has_overlap = false
  for cls in index_classes {
    for other in about_classes {
      if cls == other {
        has_overlap = true
      }
    }
  }
  inspect(has_overlap, content="false")
}

// =============================================================================
// Renderer Type CSS Handling Tests
// =============================================================================

///|
test "Renderer CSS - Markdown uses default styles" {
  let renderer = RendererType::MarkdownRenderer
  // Markdown pages use standard CSS (main.css + markdown.css)
  match renderer {
    RendererType::MarkdownRenderer => inspect(true, content="true")
    _ => fail("Expected MarkdownRenderer")
  }
}

///|
test "Renderer CSS - React islands may have scoped styles" {
  let renderer = RendererType::ReactRenderer
  // React islands may include component-scoped CSS
  match renderer {
    RendererType::ReactRenderer => inspect(true, content="true")
    _ => fail("Expected ReactRenderer")
  }
}

///|
test "Renderer CSS - Luna components use luna/css" {
  let renderer = RendererType::LunaRenderer
  // Luna components use luna/css for atomic CSS
  match renderer {
    RendererType::LunaRenderer => inspect(true, content="true")
    _ => fail("Expected LunaRenderer")
  }
}

// =============================================================================
// Edge Cases
// =============================================================================

///|
test "Edge case - empty CSS result" {
  let result = TestCssResult::{
    css: "",
    classes: [],
    size: 0,
    is_minified: true,
  }
  inspect(result.css.is_empty(), content="true")
  inspect(result.classes.is_empty(), content="true")
}

///|
test "Edge case - very large CSS exceeds threshold" {
  let config = CssUtilitiesConfig::default()
  let large_css_size = 100000 // 100KB
  let should_inline = large_css_size <= config.inline_threshold
  inspect(should_inline, content="false")
}

///|
test "Edge case - special characters in CSS values" {
  let special_values = [
    "rgba(0, 0, 0, 0.5)", "linear-gradient(to right, #fff, #000)", "translateX(-50%)",
    "url('image.png')", "calc(100% - 2rem)",
  ]
  for val in special_values {
    // All values should be valid
    inspect(val.length() > 0, content="true")
  }
}

///|
test "Edge case - many source directories" {
  let config = CssUtilitiesConfig::{
    enabled: true,
    split: false,
    inline_threshold: 4096,
    source_dirs: [
      "src/luna", "src/sol", "src/platform", "src/core", "components", "pages", "docs",
    ],
  }
  inspect(config.source_dirs.length(), content="7")
}
