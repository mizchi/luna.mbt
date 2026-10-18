///|
test "typed properties have the same CSS and hashes as string properties" {
  let typed = @css.create([
    @css.rule(@css.Property::Display, "flex"),
    @css.rule(@css.Property::BackgroundColor, "red"),
    @css.rule(@css.Property::MarginInlineStart, "2px"),
    @css.rule_on(":hover", @css.Property::Color, "blue"),
    @css.rule_media("min-width:768px", @css.Property::FontSize, "18px"),
    @css.rule_when("min-width:1024px", ":focus", @css.Property::Color, "green"),
  ])
  let strings = @css.create([
    @css.rule("display", "flex"),
    @css.rule("background-color", "red"),
    @css.rule("margin-inline-start", "2px"),
    @css.rule_on(":hover", "color", "blue"),
    @css.rule_media("min-width:768px", "font-size", "18px"),
    @css.rule_when("min-width:1024px", ":focus", "color", "green"),
  ])
  assert_eq(@css.attrs([typed]), @css.attrs([strings]))
  assert_eq(@css.stylesheet([typed]), @css.stylesheet([strings]))
}

///|
test "typed and string properties compose in the same property group" {
  let base = @css.create([
    @css.rule("color", "red"),
    @css.rule_on(":hover", @css.Property::Color, "blue"),
  ])
  let replaced = @css.compose([
    base,
    @css.create([@css.rule(@css.Property::Color, "green")]),
  ])
  assert_eq(
    @css.stylesheet([replaced]),
    @css.stylesheet([@css.create([@css.rule("color", "green")])]),
  )
  assert_eq(
    @css.attrs([base, @css.create([@css.unset(@css.Property::Color)])]).class_name,
    "",
  )
  assert_eq(
    @css.attrs([base, @css.create([@css.unset("color")])]).class_name,
    "",
  )
}

///|
test "property names include logical layout SVG and custom string escapes" {
  assert_eq(@css.Property::MarginInlineStart.css_name(), "margin-inline-start")
  assert_eq(@css.Property::StrokeWidth.css_name(), "stroke-width")
  assert_eq(@css.Property::ZIndex.css_name(), "z-index")
  let output = @css.stylesheet([
    @css.create([
      @css.rule("--brand", "red"),
      @css.rule("-webkit-app-region", "drag"),
      @css.rule(@css.Property::Color, "var(--brand)"),
    ]),
  ])
  assert_true(output.contains("--brand:red"))
  assert_true(output.contains("-webkit-app-region:drag"))
}
