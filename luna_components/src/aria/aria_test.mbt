///|
using @test {assert_eq}

///|
/// Tests for ARIA helpers
test "switch_aria returns correct attributes" {
  let attrs = @aria.switch_aria(true, false)
  assert_true(attrs.contains(("role", "switch")))
  assert_true(attrs.contains(("aria-checked", "true")))
  assert_true(attrs.contains(("tabindex", "0")))
}

///|
test "switch_aria with disabled" {
  let attrs = @aria.switch_aria(false, true)
  assert_true(attrs.contains(("aria-checked", "false")))
  assert_true(attrs.contains(("tabindex", "-1")))
  assert_true(attrs.contains(("aria-disabled", "true")))
}

///|
test "checkbox_aria returns correct attributes" {
  let attrs = @aria.checkbox_aria(true, false, false)
  assert_true(attrs.contains(("role", "checkbox")))
  assert_true(attrs.contains(("aria-checked", "true")))
}

///|
test "checkbox_aria indeterminate" {
  let attrs = @aria.checkbox_aria(false, false, true)
  assert_true(attrs.contains(("aria-checked", "mixed")))
}

///|
test "radio_aria returns correct attributes" {
  let attrs = @aria.radio_aria(true, false)
  assert_true(attrs.contains(("role", "radio")))
  assert_true(attrs.contains(("aria-checked", "true")))
  assert_true(attrs.contains(("tabindex", "0")))
}

///|
test "dialog_aria returns correct attributes" {
  let attrs = @aria.dialog_aria("dialog-1", true, aria_label="Test dialog")
  assert_true(attrs.contains(("role", "dialog")))
  assert_true(attrs.contains(("id", "dialog-1")))
  assert_true(attrs.contains(("aria-modal", "true")))
  assert_true(attrs.contains(("aria-label", "Test dialog")))
}

///|
test "tab_aria returns correct attributes" {
  let attrs = @aria.tab_aria("tab-1", true, "panel-1")
  assert_true(attrs.contains(("role", "tab")))
  assert_true(attrs.contains(("id", "tab-1")))
  assert_true(attrs.contains(("aria-selected", "true")))
  assert_true(attrs.contains(("aria-controls", "panel-1")))
  assert_true(attrs.contains(("tabindex", "0")))
}

///|
test "tabpanel_aria returns correct attributes" {
  let attrs = @aria.tabpanel_aria("panel-1", "tab-1")
  assert_true(attrs.contains(("role", "tabpanel")))
  assert_true(attrs.contains(("id", "panel-1")))
  assert_true(attrs.contains(("aria-labelledby", "tab-1")))
}

///|
test "is_toggle_key" {
  assert_true(@aria.is_toggle_key(" "))
  assert_true(@aria.is_toggle_key("Enter"))
  assert_false(@aria.is_toggle_key("Tab"))
  assert_false(@aria.is_toggle_key("Escape"))
}

///|
test "is_arrow_key" {
  assert_true(@aria.is_arrow_key("ArrowUp"))
  assert_true(@aria.is_arrow_key("ArrowDown"))
  assert_true(@aria.is_arrow_key("ArrowLeft"))
  assert_true(@aria.is_arrow_key("ArrowRight"))
  assert_false(@aria.is_arrow_key("Enter"))
}

///|
test "bool_to_aria" {
  assert_eq(@aria.bool_to_aria(true), "true")
  assert_eq(@aria.bool_to_aria(false), "false")
}
