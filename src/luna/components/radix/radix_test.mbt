///|
/// Tests for Radix-style DSD components
/// Verifies SSR output with data-* attributes for styling

///|
test "radix_button - basic (headless)" {
  let node = radix_button([@luna.text("Click me")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="button")
  // Should have class radix-button
  let has_class = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "class" && value is @luna.VStatic("radix-button")
    })
  inspect(has_class, content="true")
}

///|
test "radix_button - has data-variant attribute (headless)" {
  let node = radix_button(variant=Destructive, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Headless button has data-variant directly
  let has_variant = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-variant" && value is @luna.VStatic("destructive")
    })
  inspect(has_variant, content="true")
}

///|
test "radix_button - disabled has data-disabled (headless)" {
  let node = radix_button(disabled=true, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Headless button has data-disabled directly
  let has_disabled = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, _) = attr
      name == "data-disabled"
    })
  inspect(has_disabled, content="true")
}

///|
test "radix_checkbox - basic (headless)" {
  let node = radix_checkbox([@luna.text("Accept terms")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="button")
  // Should have class radix-checkbox
  let has_class = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "class" && value is @luna.VStatic("radix-checkbox")
    })
  inspect(has_class, content="true")
}

///|
test "radix_checkbox - has data-state (headless)" {
  let node = radix_checkbox(checked=Checked, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Check data-state on button element
  let has_state = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-state" && value is @luna.VStatic("checked")
    })
  inspect(has_state, content="true")
}

///|
test "radix_checkbox - indeterminate state (headless)" {
  let node = radix_checkbox(checked=Indeterminate, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Check data-state on button element
  let has_state = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-state" && value is @luna.VStatic("indeterminate")
    })
  inspect(has_state, content="true")
}

///|
test "radix_checkbox - has aria-checked (headless)" {
  let node = radix_checkbox(checked=Checked, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Headless checkbox has aria-checked directly on button
  let has_aria = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "aria-checked" && value is @luna.VStatic("true")
    })
  inspect(has_aria, content="true")
}

///|
test "radix_switch - basic (headless)" {
  let node = radix_switch([@luna.text("Enable")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="button")
  // Should have class radix-switch
  let has_class = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "class" && value is @luna.VStatic("radix-switch")
    })
  inspect(has_class, content="true")
}

///|
test "radix_switch - checked state (headless)" {
  let node = radix_switch(checked=true, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Check data-state on button element
  let has_state = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-state" && value is @luna.VStatic("checked")
    })
  inspect(has_state, content="true")
}

///|
test "radix_switch - unchecked state (headless)" {
  let node = radix_switch(checked=false, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Check data-state on button element
  let has_state = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-state" && value is @luna.VStatic("unchecked")
    })
  inspect(has_state, content="true")
}

///|
test "radix_switch - has role=switch (headless)" {
  let node = radix_switch([])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Headless switch has role=switch directly on button
  let has_role = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "role" && value is @luna.VStatic("switch")
    })
  inspect(has_role, content="true")
}

///|
test "radix_switch - with size (headless)" {
  let node = radix_switch(size=Small, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Headless switch has data-size directly on button
  let has_size = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-size" && value is @luna.VStatic("small")
    })
  inspect(has_size, content="true")
}

///|
test "radix_input - basic (headless)" {
  let node = radix_input(label="Username", placeholder="Enter username")
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="input")
  // Should have class radix-input
  let has_class = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "class" && value is @luna.VStatic("radix-input")
    })
  inspect(has_class, content="true")
}

///|
test "radix_input - has data-size (headless)" {
  let node = radix_input(size=Large)
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="input")

  // Check data-size directly on the input element
  let has_large = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-size" && value is @luna.VStatic("large")
    })
  inspect(has_large, content="true")
}

///|
test "radix_input - password type (headless)" {
  let node = radix_input(type_=Password)
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="input")

  // Check type directly on the input element
  let has_password = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "type" && value is @luna.VStatic("password")
    })
  inspect(has_password, content="true")
}

///|
test "radix_input - disabled" {
  let node = radix_input(disabled=true)
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Check data-disabled on host element
  let has_disabled = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, _) = attr
      name == "data-disabled"
    })
  inspect(has_disabled, content="true")
}

// ============================================================================
// Textarea Tests
// ============================================================================

///|
test "radix_textarea - basic (headless)" {
  let node = radix_textarea(
    label="Description",
    placeholder="Enter description",
  )
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="textarea")
  // Should have class radix-textarea
  let has_class = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "class" && value is @luna.VStatic("radix-textarea")
    })
  inspect(has_class, content="true")
}

///|
test "radix_textarea - with value (headless)" {
  let node = radix_textarea(value="Hello World")
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="textarea")

  // Check if textarea has text content
  let has_text = el.children.iter().any(fn(child) { child is @luna.Text(_) })
  inspect(has_text, content="true")
}

// ============================================================================
// Select Tests
// ============================================================================

///|
test "radix_select - basic (headless)" {
  let options = [select_option("a", "Option A"), select_option("b", "Option B")]
  let node = radix_select(options, label="Choose")
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="select")
  // Should have class radix-select
  let has_class = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "class" && value is @luna.VStatic("radix-select")
    })
  inspect(has_class, content="true")
}

///|
test "radix_select - with placeholder (headless)" {
  let options = [select_option("x", "X")]
  let node = radix_select(options, placeholder="Select one...")
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="select")

  // Check that first option is the placeholder (disabled, selected, empty value)
  guard el.children[0] is @luna.Element(first_option) else {
    fail("expected first option")
  }
  inspect(first_option.tag, content="option")
  // First option should have disabled and selected attributes
  let has_disabled = first_option.attrs
    .iter()
    .any(fn(attr) {
      let (name, _) = attr
      name == "disabled"
    })
  inspect(has_disabled, content="true")
}

// ============================================================================
// Radio Group Tests
// ============================================================================

///|
test "radix_radio_group - basic (headless)" {
  let options = [radio_option("yes", "Yes"), radio_option("no", "No")]
  let node = radix_radio_group("answer", options, label="Answer")
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="div")
  // Should have class radix-radio-group
  let has_class = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "class" && value is @luna.VStatic("radix-radio-group")
    })
  inspect(has_class, content="true")
}

///|
test "radix_radio_group - horizontal orientation" {
  let options = [radio_option("a", "A")]
  let node = radix_radio_group("test", options, orientation=Horizontal)
  guard node is @luna.Element(el) else { fail("expected Element") }
  let has_horizontal = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-orientation" && value is @luna.VStatic("horizontal")
    })
  inspect(has_horizontal, content="true")
}

// ============================================================================
// Toggle Tests
// ============================================================================

///|
test "radix_toggle - basic (headless)" {
  let node = radix_toggle([@luna.text("B")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="button")
  // Should have class radix-toggle
  let has_class = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "class" && value is @luna.VStatic("radix-toggle")
    })
  inspect(has_class, content="true")
}

///|
test "radix_toggle - pressed state (headless)" {
  let node = radix_toggle(pressed=true, [])
  guard node is @luna.Element(el) else { fail("expected Element") }
  let has_on = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-state" && value is @luna.VStatic("on")
    })
  inspect(has_on, content="true")
}

///|
test "radix_toggle - unpressed state (headless)" {
  let node = radix_toggle(pressed=false, [])
  guard node is @luna.Element(el) else { fail("expected Element") }
  let has_off = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-state" && value is @luna.VStatic("off")
    })
  inspect(has_off, content="true")
}

// ============================================================================
// Badge Tests
// ============================================================================

///|
test "radix_badge - basic (headless)" {
  let node = radix_badge([@luna.text("New")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="span")
  // Should have class radix-badge
  let has_class = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "class" && value is @luna.VStatic("radix-badge")
    })
  inspect(has_class, content="true")
}

///|
test "radix_badge - destructive variant (headless)" {
  let node = radix_badge(variant=Destructive, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Headless badge has data-variant directly
  let has_variant = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-variant" && value is @luna.VStatic("destructive")
    })
  inspect(has_variant, content="true")
}

// ============================================================================
// Separator Tests
// ============================================================================

///|
test "radix_separator - horizontal (headless)" {
  let node = radix_separator()
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="div")
  // Should have class radix-separator
  let has_class = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "class" && value is @luna.VStatic("radix-separator")
    })
  inspect(has_class, content="true")
  let has_horizontal = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-orientation" && value is @luna.VStatic("horizontal")
    })
  inspect(has_horizontal, content="true")
}

///|
test "radix_separator - vertical" {
  let node = radix_separator(orientation=Vertical)
  guard node is @luna.Element(el) else { fail("expected Element") }
  let has_vertical = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-orientation" && value is @luna.VStatic("vertical")
    })
  inspect(has_vertical, content="true")
}

// ============================================================================
// CSS Utility (ucss) Tests
// ============================================================================

///|
test "radix_button_ucss - generates atomic classes" {
  @css.reset_all()
  let node = radix_button_ucss([@luna.text("Click")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="button")

  // Should have class attribute with underscore-prefixed classes
  let has_class = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      match value {
        @luna.VStatic(v) => name == "class" && v.contains("_")
        _ => false
      }
    })
  inspect(has_class, content="true")

  // CSS should be generated
  let css = @css.generate_full_css()
  inspect(css.contains("display:inline-flex"), content="true")
}

///|
test "radix_button_ucss - variant styles" {
  @css.reset_all()
  let _ = radix_button_ucss(variant=Destructive, [])
  let css = @css.generate_full_css()
  // Should have destructive background color
  inspect(css.contains("background:#dc2626"), content="true")
}

///|
test "radix_button_ucss - hover states" {
  @css.reset_all()
  let _ = radix_button_ucss(variant=Default, [])
  let css = @css.generate_full_css()
  // Should have hover pseudo-class
  inspect(css.contains(":hover"), content="true")
}

///|
test "radix_badge_ucss - generates atomic classes" {
  @css.reset_all()
  let node = radix_badge_ucss([@luna.text("New")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="span")

  // CSS should be generated
  let css = @css.generate_full_css()
  inspect(css.contains("border-radius:9999px"), content="true")
}

///|
test "radix_badge_ucss - variant styles" {
  @css.reset_all()
  let _ = radix_badge_ucss(variant=Destructive, [])
  let css = @css.generate_full_css()
  inspect(css.contains("background:#dc2626"), content="true")
}

// ============================================================================
// SSR Integration Demo
// ============================================================================

///|
/// Demo: Full SSR page with radix components using luna/css
test "demo: SSR with radix_ucss components" {
  @css.reset_all()

  // Build multiple components using ucss
  let primary_btn = radix_button_ucss(variant=Default, [@luna.text("Save")])
  let danger_btn = radix_button_ucss(variant=Destructive, [@luna.text("Delete")])
  let badge = radix_badge_ucss(variant=Secondary, [@luna.text("New")])

  // All CSS is collected in the registry
  let css = @css.generate_full_css()

  // Verify CSS contains styles from all components
  inspect(css.contains("display:inline-flex"), content="true")
  inspect(css.contains("background:#18181b"), content="true") // default button
  inspect(css.contains("background:#dc2626"), content="true") // destructive button
  inspect(css.contains("background:#f4f4f5"), content="true") // secondary badge
  inspect(css.contains("border-radius:9999px"), content="true") // badge rounded

  // Verify buttons are rendered correctly
  guard primary_btn is @luna.Element(el1) else { fail("expected Element") }
  guard danger_btn is @luna.Element(el2) else { fail("expected Element") }
  guard badge is @luna.Element(el3) else { fail("expected Element") }
  inspect(el1.tag, content="button")
  inspect(el2.tag, content="button")
  inspect(el3.tag, content="span")

  // CSS classes are atomic and deduplicated
  let count = @css.registry_size()
  // Multiple components share common styles
  inspect(count > 0, content="true")
}

// ============================================================================
// Additional ucss Tests
// ============================================================================

///|
test "radix_toggle_ucss - generates atomic classes" {
  @css.reset_all()
  let node = radix_toggle_ucss([@luna.text("B")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="button")

  // CSS should be generated
  let css = @css.generate_full_css()
  inspect(css.contains("display:inline-flex"), content="true")
}

///|
test "radix_toggle_ucss - pressed state styles" {
  @css.reset_all()
  let _ = radix_toggle_ucss(pressed=true, [])
  let css = @css.generate_full_css()
  inspect(css.contains("background:#f4f4f5"), content="true")
}

///|
test "radix_input_ucss - generates atomic classes" {
  @css.reset_all()
  let node = radix_input_ucss(placeholder="Enter text")
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="input")

  // CSS should be generated
  let css = @css.generate_full_css()
  inspect(css.contains("border:1px solid #e4e4e7"), content="true")
}

///|
test "radix_input_ucss - size styles" {
  @css.reset_all()
  let _ = radix_input_ucss(size=Large)
  let css = @css.generate_full_css()
  inspect(css.contains("height:3rem"), content="true")
}

///|
test "radix_textarea_ucss - generates atomic classes" {
  @css.reset_all()
  let node = radix_textarea_ucss(placeholder="Enter description")
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="textarea")

  // CSS should be generated
  let css = @css.generate_full_css()
  inspect(css.contains("min-height:5rem"), content="true")
}

///|
test "radix_select_ucss - generates atomic classes" {
  @css.reset_all()
  let options = [select_option("a", "A"), select_option("b", "B")]
  let node = radix_select_ucss(options)
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="select")

  // CSS should be generated
  let css = @css.generate_full_css()
  inspect(css.contains("cursor:pointer"), content="true")
}

///|
test "radix_separator_ucss - horizontal styles" {
  @css.reset_all()
  let node = radix_separator_ucss()
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="div")

  // CSS should be generated
  let css = @css.generate_full_css()
  inspect(css.contains("height:1px"), content="true")
  inspect(css.contains("width:100%"), content="true")
}

///|
test "radix_separator_ucss - vertical styles" {
  @css.reset_all()
  let _ = radix_separator_ucss(orientation=Vertical)
  let css = @css.generate_full_css()
  inspect(css.contains("width:1px"), content="true")
  inspect(css.contains("height:100%"), content="true")
}

///|
test "radix_radio_group_ucss - generates atomic classes" {
  @css.reset_all()
  let options = [radio_option("yes", "Yes"), radio_option("no", "No")]
  let node = radix_radio_group_ucss("answer", options)
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="div")

  // CSS should be generated
  let css = @css.generate_full_css()
  inspect(css.contains("display:flex"), content="true")
  inspect(css.contains("flex-direction:column"), content="true")
}

///|
test "radix_radio_group_ucss - horizontal orientation" {
  @css.reset_all()
  let options = [radio_option("a", "A")]
  let _ = radix_radio_group_ucss("test", options, orientation=Horizontal)
  let css = @css.generate_full_css()
  inspect(css.contains("flex-direction:row"), content="true")
}

// ============================================================================
// CSS Mangling Tests
// ============================================================================

///|
test "css mangling - class names are deterministic" {
  @css.reset_all()
  let class1 = button_base_styles()
  @css.reset_all()
  let class2 = button_base_styles()
  // Same input should produce same output
  inspect(class1 == class2, content="true")
}

///|
test "css mangling - different inputs produce different classes" {
  @css.reset_all()
  let class1 = @css.css("display", "flex")
  let class2 = @css.css("display", "none")
  let class3 = @css.css("display", "grid")
  // Different values should produce different classes
  inspect(class1 != class2, content="true")
  inspect(class2 != class3, content="true")
  inspect(class1 != class3, content="true")
}

///|
test "css mangling - deduplication works" {
  @css.reset_all()
  let class1 = @css.css("padding", "1rem")
  let class2 = @css.css("padding", "1rem")
  // Same declaration should return same class name
  inspect(class1 == class2, content="true")

  // Registry should only have one entry for this declaration
  let css = @css.generate_full_css()
  // Count occurrences of padding:1rem
  let mut count = 0
  for _ in css.split("padding:1rem") {
    count = count + 1
  }
  // split returns n+1 parts for n occurrences, so count-1 = occurrences
  inspect(count - 1, content="1")
}

///|
test "css mangling - class name format" {
  @css.reset_all()
  let cls = @css.css("color", "red")
  // Class names should start with underscore
  inspect(cls.has_prefix("_"), content="true")
  // Class names should not contain spaces
  inspect(cls.contains(" ") == false, content="true")
}

///|
test "css mangling - pseudo classes are separate" {
  @css.reset_all()
  let base = @css.css("background", "white")
  let hover = @css.hover("background", "gray")
  // Should produce different class names
  inspect(base != hover, content="true")

  // CSS output should contain both
  let css = @css.generate_full_css()
  inspect(css.contains("background:white"), content="true")
  inspect(css.contains(":hover"), content="true")
}

///|
test "css mangling - full page integration" {
  @css.reset_all()

  // Simulate a full page with multiple ucss components
  let btn1 = radix_button_ucss(variant=Default, [@luna.text("Submit")])
  let btn2 = radix_button_ucss(variant=Outline, [@luna.text("Cancel")])
  let input1 = radix_input_ucss(placeholder="Name")
  let input2 = radix_input_ucss(placeholder="Email", type_=Email)
  let textarea = radix_textarea_ucss(placeholder="Message")
  let checkbox = radix_checkbox_ucss(checked=Checked, [])
  let toggle = radix_toggle_ucss(pressed=true, [@luna.text("B")])
  let separator = radix_separator_ucss()

  // All components should be valid
  guard btn1 is @luna.Element(_) else { fail("btn1") }
  guard btn2 is @luna.Element(_) else { fail("btn2") }
  guard input1 is @luna.Element(_) else { fail("input1") }
  guard input2 is @luna.Element(_) else { fail("input2") }
  guard textarea is @luna.Element(_) else { fail("textarea") }
  guard checkbox is @luna.Element(_) else { fail("checkbox") }
  guard toggle is @luna.Element(_) else { fail("toggle") }
  guard separator is @luna.Element(_) else { fail("separator") }

  // Extract all CSS
  let css = @css.generate_full_css()

  // Should contain styles from various components
  inspect(css.contains("display:inline-flex"), content="true") // button, toggle
  inspect(css.contains("border-radius"), content="true") // multiple
  inspect(css.contains("cursor:pointer"), content="true") // interactive elements
  inspect(css.contains(":hover"), content="true") // hover states
  inspect(css.contains(":focus"), content="true") // focus states

  // CSS should be deduplicated (shared styles appear once)
  let registry_count = @css.registry_size()
  inspect(registry_count > 0, content="true")
}
