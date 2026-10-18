///|
test "typed pseudo selectors share CSS and hashes with strings" {
  let typed = @css.create([
    @css.rule_on(@css.Pseudo::Hover, @css.Property::Color, "blue"),
    @css.rule_on(
      @css.Pseudo::FocusVisible,
      @css.Property::Outline,
      "2px solid blue",
    ),
    @css.rule_on(@css.Pseudo::Disabled, @css.Property::Opacity, "0.5"),
    @css.rule_on(@css.Pseudo::NthChild("2n"), @css.Property::Color, "red"),
    @css.rule_on(
      @css.Pseudo::Not(":disabled"),
      @css.Property::Cursor,
      "pointer",
    ),
    @css.rule_on(@css.Pseudo::Before, @css.Property::Content, "\"hello\""),
    @css.rule_when(
      "min-width:768px",
      @css.Pseudo::Hover,
      @css.Property::Color,
      "green",
    ),
  ])
  let strings = @css.create([
    @css.rule_on(":hover", "color", "blue"),
    @css.rule_on(":focus-visible", "outline", "2px solid blue"),
    @css.rule_on(":disabled", "opacity", "0.5"),
    @css.rule_on(":nth-child(2n)", "color", "red"),
    @css.rule_on(":not(:disabled)", "cursor", "pointer"),
    @css.rule_on("::before", "content", "\"hello\""),
    @css.rule_when("min-width:768px", ":hover", "color", "green"),
  ])
  assert_eq(@css.attrs([typed]), @css.attrs([strings]))
  assert_eq(@css.stylesheet([typed]), @css.stylesheet([strings]))
}

///|
test "typed pseudo elements remain independent when element styles are replaced" {
  let base = @css.create([
    @css.rule_on(@css.Pseudo::Hover, @css.Property::Color, "red"),
    @css.rule_on(@css.Pseudo::Before, @css.Property::Color, "blue"),
    @css.rule_on(@css.Pseudo::Part("label"), @css.Property::Color, "purple"),
  ])
  let result = @css.compose([
    base,
    @css.create([@css.rule(@css.Property::Color, "green")]),
  ])
  let output = @css.stylesheet([result])
  assert_false(output.contains(":hover"))
  assert_true(output.contains("::before{color:blue}"))
  assert_true(output.contains("::part(label){color:purple}"))
}
