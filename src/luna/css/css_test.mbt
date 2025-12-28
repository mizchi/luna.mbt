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
