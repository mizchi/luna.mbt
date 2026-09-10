///|
test "typed properties have the same CSS and hashes as string properties" {
  let typed = create([
    rule(Property::Display, "flex"),
    rule(Property::BackgroundColor, "red"),
    rule(Property::MarginInlineStart, "2px"),
    rule_on(":hover", Property::Color, "blue"),
    rule_media("min-width:768px", Property::FontSize, "18px"),
    rule_when("min-width:1024px", ":focus", Property::Color, "green"),
  ])
  let strings = create([
    rule("display", "flex"),
    rule("background-color", "red"),
    rule("margin-inline-start", "2px"),
    rule_on(":hover", "color", "blue"),
    rule_media("min-width:768px", "font-size", "18px"),
    rule_when("min-width:1024px", ":focus", "color", "green"),
  ])
  assert_eq(attrs([typed]), attrs([strings]))
  assert_eq(stylesheet([typed]), stylesheet([strings]))
}

///|
test "typed and string properties compose in the same property group" {
  let base = create([
    rule("color", "red"),
    rule_on(":hover", Property::Color, "blue"),
  ])
  let replaced = compose([base, create([rule(Property::Color, "green")])])
  assert_eq(
    stylesheet([replaced]),
    stylesheet([create([rule("color", "green")])]),
  )
  assert_eq(attrs([base, create([unset(Property::Color)])]).class_name, "")
  assert_eq(attrs([base, create([unset("color")])]).class_name, "")
}

///|
test "property names include logical layout SVG and custom string escapes" {
  assert_eq(Property::MarginInlineStart.css_name(), "margin-inline-start")
  assert_eq(Property::StrokeWidth.css_name(), "stroke-width")
  assert_eq(Property::ZIndex.css_name(), "z-index")
  let output = stylesheet([
    create([
      rule("--brand", "red"),
      rule("-webkit-app-region", "drag"),
      rule(Property::Color, "var(--brand)"),
    ]),
  ])
  assert_true(output.contains("--brand:red"))
  assert_true(output.contains("-webkit-app-region:drag"))
}
