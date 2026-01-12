///|
/// Tests for default switch component
test "switch_css returns valid CSS" {
  let css = switch_css()
  // Check that CSS contains expected selectors
  assert_true(css.contains(".switch"))
  assert_true(css.contains(".switch__track"))
  assert_true(css.contains(".switch__thumb"))
  assert_true(css.contains(".switch__icon"))
  assert_true(css.contains(".switch__label"))
  assert_true(css.contains(".switch-group"))
  // Check data attribute selectors
  assert_true(css.contains("[data-state=\"on\"]"))
  assert_true(css.contains("[data-disabled]"))
}

///|
test "switch_slots returns BEM class names" {
  let slots = switch_slots()
  assert_eq(slots.root, "switch")
  assert_eq(slots.track, "switch__track")
  assert_eq(slots.thumb, "switch__thumb")
  assert_eq(slots.icon, "switch__icon")
  assert_eq(slots.label, "switch__label")
}
