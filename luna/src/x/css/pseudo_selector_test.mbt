///|
test "typed pseudo selectors share CSS and hashes with strings" {
  let typed = create([
    rule_on(Pseudo::Hover, Property::Color, "blue"),
    rule_on(Pseudo::FocusVisible, Property::Outline, "2px solid blue"),
    rule_on(Pseudo::Disabled, Property::Opacity, "0.5"),
    rule_on(Pseudo::NthChild("2n"), Property::Color, "red"),
    rule_on(Pseudo::Not(":disabled"), Property::Cursor, "pointer"),
    rule_on(Pseudo::Before, Property::Content, "\"hello\""),
    rule_when("min-width:768px", Pseudo::Hover, Property::Color, "green"),
  ])
  let strings = create([
    rule_on(":hover", "color", "blue"),
    rule_on(":focus-visible", "outline", "2px solid blue"),
    rule_on(":disabled", "opacity", "0.5"),
    rule_on(":nth-child(2n)", "color", "red"),
    rule_on(":not(:disabled)", "cursor", "pointer"),
    rule_on("::before", "content", "\"hello\""),
    rule_when("min-width:768px", ":hover", "color", "green"),
  ])
  assert_eq(attrs([typed]), attrs([strings]))
  assert_eq(stylesheet([typed]), stylesheet([strings]))
}

///|
test "typed pseudo elements remain independent when element styles are replaced" {
  let base = create([
    rule_on(Pseudo::Hover, Property::Color, "red"),
    rule_on(Pseudo::Before, Property::Color, "blue"),
    rule_on(Pseudo::Part("label"), Property::Color, "purple"),
  ])
  let result = compose([base, create([rule(Property::Color, "green")])])
  let output = stylesheet([result])
  assert_false(output.contains(":hover"))
  assert_true(output.contains("::before{color:blue}"))
  assert_true(output.contains("::part(label){color:purple}"))
}
