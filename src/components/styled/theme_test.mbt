///|
/// Tests for theme variables

test "theme_variables includes root" {
  let css = theme_variables()
  assert_true(css.contains(":root"))
}

test "theme_variables includes switch vars" {
  let css = theme_variables()
  assert_true(css.contains("--switch-track-off"))
  assert_true(css.contains("--switch-track-on"))
}

test "theme_variables includes accent" {
  let css = theme_variables()
  assert_true(css.contains("--accent"))
}
