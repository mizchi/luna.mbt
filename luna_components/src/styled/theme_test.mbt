///|
/// Tests for theme variables
test "theme_variables includes root" {
  let css = @styled.theme_variables()
  assert_true(css.contains(":root"))
}

///|
test "theme_variables includes switch vars" {
  let css = @styled.theme_variables()
  assert_true(css.contains("--switch-track-off"))
  assert_true(css.contains("--switch-track-on"))
}

///|
test "theme_variables includes accent" {
  let css = @styled.theme_variables()
  assert_true(css.contains("--accent"))
}
