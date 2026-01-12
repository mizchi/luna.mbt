///|
/// Tests for ARIA helpers
test "switch_aria returns correct attributes" {
  let attrs = switch_aria(true, false)
  assert_true(attrs.contains(("role", "switch")))
  assert_true(attrs.contains(("aria-checked", "true")))
  assert_true(attrs.contains(("tabindex", "0")))
}

///|
test "switch_aria with disabled" {
  let attrs = switch_aria(false, true)
  assert_true(attrs.contains(("aria-checked", "false")))
  assert_true(attrs.contains(("tabindex", "-1")))
  assert_true(attrs.contains(("aria-disabled", "true")))
}

///|
test "checkbox_aria returns correct attributes" {
  let attrs = checkbox_aria(true, false, false)
  assert_true(attrs.contains(("role", "checkbox")))
  assert_true(attrs.contains(("aria-checked", "true")))
}

///|
test "checkbox_aria indeterminate" {
  let attrs = checkbox_aria(false, false, true)
  assert_true(attrs.contains(("aria-checked", "mixed")))
}

///|
test "radio_aria returns correct attributes" {
  let attrs = radio_aria(true, false)
  assert_true(attrs.contains(("role", "radio")))
  assert_true(attrs.contains(("aria-checked", "true")))
  assert_true(attrs.contains(("tabindex", "0")))
}

///|
test "dialog_aria returns correct attributes" {
  let attrs = dialog_aria("dialog-1", true, aria_label="Test dialog")
  assert_true(attrs.contains(("role", "dialog")))
  assert_true(attrs.contains(("id", "dialog-1")))
  assert_true(attrs.contains(("aria-modal", "true")))
  assert_true(attrs.contains(("aria-label", "Test dialog")))
}

///|
test "tab_aria returns correct attributes" {
  let attrs = tab_aria("tab-1", true, "panel-1")
  assert_true(attrs.contains(("role", "tab")))
  assert_true(attrs.contains(("id", "tab-1")))
  assert_true(attrs.contains(("aria-selected", "true")))
  assert_true(attrs.contains(("aria-controls", "panel-1")))
  assert_true(attrs.contains(("tabindex", "0")))
}

///|
test "tabpanel_aria returns correct attributes" {
  let attrs = tabpanel_aria("panel-1", "tab-1")
  assert_true(attrs.contains(("role", "tabpanel")))
  assert_true(attrs.contains(("id", "panel-1")))
  assert_true(attrs.contains(("aria-labelledby", "tab-1")))
}
