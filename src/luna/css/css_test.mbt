// Tests for CSS utility module

///|
test "css() returns class name with underscore prefix" {
  reset_all()
  let cls = css("display", "flex")
  // Class name starts with underscore
  assert_true(cls.has_prefix("_"))
}

///|
test "css() deduplicates same declarations" {
  reset_all()
  let cls1 = css("test-prop-dedup", "value1")
  let cls2 = css("test-prop-dedup", "value1")
  assert_eq(cls1, cls2)
}

///|
test "css() generates different classes for different declarations" {
  reset_all()
  let cls1 = css("test-prop-diff1", "value1")
  let cls2 = css("test-prop-diff2", "value2")
  // Different declarations get different classes
  assert_true(cls1 != cls2)
}

///|
test "styles() returns space-separated class names" {
  reset_all()
  let classes = styles([("test-style1", "val1"), ("test-style2", "val2")])
  // Should contain a space (multiple classes)
  assert_true(classes.contains(" "))
}

///|
test "combine() joins class names with space" {
  reset_all()
  let flex = css("test-combine1", "val1")
  let center = css("test-combine2", "val2")
  let combined = combine([flex, center])
  assert_true(combined.contains(" "))
  assert_true(combined.contains(flex))
  assert_true(combined.contains(center))
}

///|
test "generate_css() outputs declarations in CSS format" {
  reset_all()
  let cls1 = css("test-gen-display", "flex")
  let cls2 = css("test-gen-align", "center")
  let output = generate_css()
  // Output should contain the class and declaration
  assert_true(output.contains("." + cls1 + "{test-gen-display:flex}"))
  assert_true(output.contains("." + cls2 + "{test-gen-align:center}"))
}

///|
test "hover() returns class name with _h prefix" {
  reset_all()
  let cls = hover("test-hover-bg", "#2563eb")
  assert_true(cls.has_prefix("_h"))
}

///|
test "hover() deduplicates same declarations" {
  reset_all()
  let cls1 = hover("test-hover-dedup", "#2563eb")
  let cls2 = hover("test-hover-dedup", "#2563eb")
  assert_eq(cls1, cls2)
}

///|
test "focus() returns class name with _f prefix" {
  reset_all()
  let cls = focus("test-focus-outline", "2px solid blue")
  assert_true(cls.has_prefix("_f"))
}

///|
test "active() returns class name with _ac prefix" {
  reset_all()
  let cls = active("test-active-transform", "scale(0.98)")
  assert_true(cls.has_prefix("_ac"))
}

///|
test "at_md() returns class name with _m prefix" {
  reset_all()
  let cls = at_md("test-md-padding", "2rem")
  assert_true(cls.has_prefix("_m"))
}

///|
test "dark() returns class name with _m prefix" {
  reset_all()
  let cls = dark("test-dark-bg", "#1a1a1a")
  assert_true(cls.has_prefix("_m"))
}

///|
test "generate_full_css() includes base, pseudo, and media" {
  reset_all()
  let base_cls = css("test-full-display", "flex")
  let hover_cls = hover("test-full-hover-bg", "#2563eb")
  let media_cls = at_md("test-full-md-padding", "2rem")
  let output = generate_full_css()

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
  reset_all()
  let cls1 = css("test-incr1", "val1")
  let cls2 = css("test-incr2", "val2")
  let cls3 = css("test-incr3", "val3")

  // All should be different
  assert_true(cls1 != cls2)
  assert_true(cls2 != cls3)
  assert_true(cls1 != cls3)
}

///|
test "media queries are grouped by condition" {
  reset_all()
  let md1 = at_md("test-group-padding", "1rem")
  let _ = at_lg("test-group-lg-padding", "2rem")
  let md2 = at_md("test-group-font-size", "1.25rem") // Same condition as first
  let output = generate_full_css()

  // Should have two @media blocks (md and lg)
  assert_true(output.contains("@media(min-width:768px){"))
  assert_true(output.contains("@media(min-width:1024px){"))
  // md block should contain both md declarations
  assert_true(output.contains("." + md1 + "{test-group-padding:1rem}"))
  assert_true(output.contains("." + md2 + "{test-group-font-size:1.25rem}"))
}

// =============================================================================
// Edge Cases
// =============================================================================

///|
test "edge: CSS values with special characters" {
  reset_all()
  let _ = css("box-shadow", "0 1px 3px rgba(0,0,0,0.1)")
  let _ = css("background", "linear-gradient(to right, #fff, #000)")
  let _ = css("transform", "translateX(-50%)")
  let output = generate_css()

  assert_true(output.contains("box-shadow:0 1px 3px rgba(0,0,0,0.1)"))
  assert_true(output.contains("linear-gradient(to right, #fff, #000)"))
  assert_true(output.contains("translateX(-50%)"))
}

///|
test "edge: empty property or value" {
  reset_all()
  let empty_val = css("display", "")
  let output = generate_css()
  // Should still generate a class, even with empty value
  assert_true(empty_val.has_prefix("_"))
  assert_true(output.contains("display:"))
}

///|
test "edge: at_sm breakpoint" {
  reset_all()
  let _ = at_sm("display", "block")
  let output = generate_full_css()
  assert_true(output.contains("@media(min-width:640px)"))
  assert_true(output.contains("display:block"))
}

///|
test "edge: at_xl breakpoint" {
  reset_all()
  let _ = at_xl("max-width", "1200px")
  let output = generate_full_css()
  assert_true(output.contains("@media(min-width:1280px)"))
  assert_true(output.contains("max-width:1200px"))
}

///|
test "edge: on() with pseudo-class" {
  reset_all()
  let _ = on(":first-child", "margin-top", "0")
  let _ = on(":last-child", "margin-bottom", "0")
  let output = generate_full_css()
  assert_true(output.contains(":first-child{margin-top:0}"))
  assert_true(output.contains(":last-child{margin-bottom:0}"))
}

///|
test "edge: on() with pseudo-element" {
  reset_all()
  let _ = on("::before", "content", "''")
  let _ = on("::after", "display", "block")
  let output = generate_full_css()
  assert_true(output.contains("::before{content:''}"))
  assert_true(output.contains("::after{display:block}"))
}

///|
test "edge: media() with custom condition" {
  reset_all()
  let _ = media("min-width: 1440px", "max-width", "1200px")
  let output = generate_full_css()
  assert_true(output.contains("@media(min-width: 1440px)"))
  assert_true(output.contains("max-width:1200px"))
}

///|
test "edge: styles() with single item" {
  reset_all()
  let cls = styles([("display", "flex")])
  let output = generate_css()
  // Should not contain space (only one class)
  assert_false(cls.contains(" "))
  assert_true(output.contains("display:flex"))
}

///|
test "edge: styles() with empty array" {
  reset_all()
  let cls = styles([])
  // Should return empty string for empty array
  assert_eq(cls, "")
}

///|
test "edge: combine() with single class" {
  reset_all()
  let flex = css("display", "flex")
  let combined = combine([flex])
  assert_eq(combined, flex)
}

///|
test "edge: combine() with empty array" {
  reset_all()
  let combined = combine([])
  assert_eq(combined, "")
}

///|
test "edge: many declarations do not overflow" {
  reset_all()
  // Generate 100 unique declarations
  for i = 0; i < 100; i = i + 1 {
    let _ = css("prop" + i.to_string(), "val" + i.to_string())
  }
  let output = generate_css()
  // Should contain all 100 declarations
  assert_true(output.contains("prop99:val99"))
}

///|
test "edge: reset_all clears registries" {
  let _ = css("before-reset", "value")
  reset_all()
  let output = generate_css()
  // Should not contain the declaration made before reset
  assert_false(output.contains("before-reset"))
}

///|
test "edge: focus deduplication" {
  reset_all()
  let f1 = focus("outline", "2px solid blue")
  let f2 = focus("outline", "2px solid blue")
  let f3 = focus("outline", "none") // Different value
  assert_eq(f1, f2)
  assert_true(f1 != f3)
}

///|
test "edge: active deduplication" {
  reset_all()
  let a1 = active("transform", "scale(0.98)")
  let a2 = active("transform", "scale(0.98)")
  let a3 = active("opacity", "0.8") // Different property
  assert_eq(a1, a2)
  assert_true(a1 != a3)
}

///|
test "edge: dark mode deduplication" {
  reset_all()
  let d1 = dark("background", "#1a1a1a")
  let d2 = dark("background", "#1a1a1a")
  let d3 = dark("color", "white") // Different property
  assert_eq(d1, d2)
  assert_true(d1 != d3)
}
