///|
using @test {assert_eq}

// Tests for CSS utility module

///|
test "css() returns class name with underscore prefix" {
  @css.reset_all()
  let cls = @css.css("display", "flex")
  // Class name starts with underscore
  assert_true(cls.has_prefix("_"))
}

///|
test "css() deduplicates same declarations" {
  @css.reset_all()
  let cls1 = @css.css("test-prop-dedup", "value1")
  let cls2 = @css.css("test-prop-dedup", "value1")
  assert_eq(cls1, cls2)
}

///|
test "css() generates different classes for different declarations" {
  @css.reset_all()
  let cls1 = @css.css("test-prop-diff1", "value1")
  let cls2 = @css.css("test-prop-diff2", "value2")
  // Different declarations get different classes
  assert_true(cls1 != cls2)
}

///|
test "styles() returns space-separated class names" {
  @css.reset_all()
  let classes = @css.styles([("test-style1", "val1"), ("test-style2", "val2")])
  // Should contain a space (multiple classes)
  assert_true(classes.contains(" "))
}

///|
test "combine() joins class names with space" {
  @css.reset_all()
  let flex = @css.css("test-combine1", "val1")
  let center = @css.css("test-combine2", "val2")
  let combined = @css.combine([flex, center])
  assert_true(combined.contains(" "))
  assert_true(combined.contains(flex))
  assert_true(combined.contains(center))
}

///|
test "generate_css() outputs declarations in CSS format" {
  @css.reset_all()
  let cls1 = @css.css("test-gen-display", "flex")
  let cls2 = @css.css("test-gen-align", "center")
  let output = @css.generate_css()
  // Output should contain the class and declaration
  assert_true(output.contains("." + cls1 + "{test-gen-display:flex}"))
  assert_true(output.contains("." + cls2 + "{test-gen-align:center}"))
}

///|
test "hover() returns class name with _ prefix" {
  @css.reset_all()
  let cls = @css.hover("test-hover-bg", "#2563eb")
  assert_true(cls.has_prefix("_"))
}

///|
test "hover() deduplicates same declarations" {
  @css.reset_all()
  let cls1 = @css.hover("test-hover-dedup", "#2563eb")
  let cls2 = @css.hover("test-hover-dedup", "#2563eb")
  assert_eq(cls1, cls2)
}

///|
test "focus() returns class name with _ prefix" {
  @css.reset_all()
  let cls = @css.focus("test-focus-outline", "2px solid blue")
  assert_true(cls.has_prefix("_"))
}

///|
test "active() returns class name with _ prefix" {
  @css.reset_all()
  let cls = @css.active("test-active-transform", "scale(0.98)")
  assert_true(cls.has_prefix("_"))
}

///|
test "at_md() returns class name with hash prefix" {
  @css.reset_all()
  let cls = @css.at_md("test-md-padding", "2rem")
  assert_true(cls.has_prefix("_"))
}

///|
test "dark() returns class name with hash prefix" {
  @css.reset_all()
  let cls = @css.dark("test-dark-bg", "#1a1a1a")
  assert_true(cls.has_prefix("_"))
}

///|
test "generate_full_css() includes base, pseudo, and media" {
  @css.reset_all()
  let base_cls = @css.css("test-full-display", "flex")
  let hover_cls = @css.hover("test-full-hover-bg", "#2563eb")
  let media_cls = @css.at_md("test-full-md-padding", "2rem")
  let output = @css.generate_full_css()

  // Check base style
  assert_true(output.contains("." + base_cls + "{test-full-display:flex}"))
  // Check pseudo-class
  assert_true(
    output.contains("." + hover_cls + ":hover{test-full-hover-bg:#2563eb}"),
  )
  // Check media query
  assert_true(
    output.contains(
      "@media(min-width:768px){." + media_cls + "{test-full-md-padding:2rem}}",
    ),
  )
}

///|
test "class names increment correctly" {
  @css.reset_all()
  let cls1 = @css.css("test-incr1", "val1")
  let cls2 = @css.css("test-incr2", "val2")
  let cls3 = @css.css("test-incr3", "val3")

  // All should be different
  assert_true(cls1 != cls2)
  assert_true(cls2 != cls3)
  assert_true(cls1 != cls3)
}

///|
test "media queries are grouped by condition" {
  @css.reset_all()
  let md1 = @css.at_md("test-group-padding", "1rem")
  let _ = @css.at_lg("test-group-lg-padding", "2rem")
  let md2 = @css.at_md("test-group-font-size", "1.25rem") // Same condition as first
  let output = @css.generate_full_css()

  // Should have two @media blocks (md and lg)
  assert_true(output.contains("@media(min-width:768px){"))
  assert_true(output.contains("@media(min-width:1024px){"))
  // md block should contain both md declarations
  assert_true(output.contains("." + md1 + "{test-group-padding:1rem}"))
  assert_true(output.contains("." + md2 + "{test-group-font-size:1.25rem}"))
}

///|
test "media class names match static extraction and ignore registration order" {
  @css.reset_all()
  let first = @css.at_md("padding", "2rem")
  // Same DJB2 input used by both static extractors.
  assert_eq(first, "_m2bz")
  @css.reset_all()
  ignore(@css.at_lg("display", "flex"))
  assert_eq(@css.at_md("padding", "2rem"), first)
}

// =============================================================================
// Edge Cases
// =============================================================================

///|
test "edge: CSS values with special characters" {
  @css.reset_all()
  let _ = @css.css("box-shadow", "0 1px 3px rgba(0,0,0,0.1)")
  let _ = @css.css("background", "linear-gradient(to right, #fff, #000)")
  let _ = @css.css("transform", "translateX(-50%)")
  let output = @css.generate_css()
  assert_true(output.contains("box-shadow:0 1px 3px rgba(0,0,0,0.1)"))
  assert_true(output.contains("linear-gradient(to right, #fff, #000)"))
  assert_true(output.contains("translateX(-50%)"))
}

///|
test "edge: empty property or value" {
  @css.reset_all()
  let empty_val = @css.css("display", "")
  let output = @css.generate_css()
  // Should still generate a class, even with empty value
  assert_true(empty_val.has_prefix("_"))
  assert_true(output.contains("display:"))
}

///|
test "edge: at_sm breakpoint" {
  @css.reset_all()
  let _ = @css.at_sm("display", "block")
  let output = @css.generate_full_css()
  assert_true(output.contains("@media(min-width:640px)"))
  assert_true(output.contains("display:block"))
}

///|
test "edge: at_xl breakpoint" {
  @css.reset_all()
  let _ = @css.at_xl("max-width", "1200px")
  let output = @css.generate_full_css()
  assert_true(output.contains("@media(min-width:1280px)"))
  assert_true(output.contains("max-width:1200px"))
}

///|
test "edge: on() with pseudo-class" {
  @css.reset_all()
  let _ = @css.on(":first-child", "margin-top", "0")
  let _ = @css.on(":last-child", "margin-bottom", "0")
  let output = @css.generate_full_css()
  assert_true(output.contains(":first-child{margin-top:0}"))
  assert_true(output.contains(":last-child{margin-bottom:0}"))
}

///|
test "edge: on() with pseudo-element" {
  @css.reset_all()
  let _ = @css.on("::before", "content", "''")
  let _ = @css.on("::after", "display", "block")
  let output = @css.generate_full_css()
  assert_true(output.contains("::before{content:''}"))
  assert_true(output.contains("::after{display:block}"))
}

///|
test "edge: media() with custom condition" {
  @css.reset_all()
  let _ = @css.media("min-width: 1440px", "max-width", "1200px")
  let output = @css.generate_full_css()
  assert_true(output.contains("@media(min-width: 1440px)"))
  assert_true(output.contains("max-width:1200px"))
}

///|
test "edge: styles() with single item" {
  @css.reset_all()
  let cls = @css.styles([("display", "flex")])
  let output = @css.generate_css()
  // Should not contain space (only one class)
  assert_false(cls.contains(" "))
  assert_true(output.contains("display:flex"))
}

///|
test "edge: styles() with empty array" {
  @css.reset_all()
  let cls = @css.styles([])
  // Should return empty string for empty array
  assert_eq(cls, "")
}

///|
test "edge: combine() with single class" {
  @css.reset_all()
  let flex = @css.css("display", "flex")
  let combined = @css.combine([flex])
  assert_eq(combined, flex)
}

///|
test "edge: combine() with empty array" {
  @css.reset_all()
  let combined = @css.combine([])
  assert_eq(combined, "")
}

///|
test "edge: many declarations do not overflow" {
  @css.reset_all()
  // Generate 100 unique declarations
  for i in 0..<100 {
    let _ = @css.css("prop" + i.to_string(), "val" + i.to_string())
  }
  let output = @css.generate_css()
  // Should contain all 100 declarations
  assert_true(output.contains("prop99:val99"))
}

///|
test "edge: reset_all clears registries" {
  let _ = @css.css("before-reset", "value")
  @css.reset_all()
  let output = @css.generate_css()
  // Should not contain the declaration made before reset
  assert_false(output.contains("before-reset"))
}

///|
test "edge: focus deduplication" {
  @css.reset_all()
  let f1 = @css.focus("outline", "2px solid blue")
  let f2 = @css.focus("outline", "2px solid blue")
  let f3 = @css.focus("outline", "none") // Different value
  assert_eq(f1, f2)
  assert_true(f1 != f3)
}

///|
test "edge: active deduplication" {
  @css.reset_all()
  let a1 = @css.active("transform", "scale(0.98)")
  let a2 = @css.active("transform", "scale(0.98)")
  let a3 = @css.active("opacity", "0.8") // Different property
  assert_eq(a1, a2)
  assert_true(a1 != a3)
}

///|
test "edge: dark mode deduplication" {
  @css.reset_all()
  let d1 = @css.dark("background", "#1a1a1a")
  let d2 = @css.dark("background", "#1a1a1a")
  let d3 = @css.dark("color", "white") // Different property
  assert_eq(d1, d2)
  assert_true(d1 != d3)
}
