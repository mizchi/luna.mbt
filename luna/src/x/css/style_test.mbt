///|
test "composition replaces a property together with its conditions" {
  let base = @css.create([
    @css.rule("color", "red"),
    @css.rule_on(":hover", "color", "green"),
    @css.rule_media("min-width:768px", "color", "purple"),
    @css.rule("display", "flex"),
  ])
  let replacement = @css.create([@css.rule("color", "blue")])
  let result = @css.compose([base, replacement])
  assert_eq(
    @css.attrs([result]).class_name,
    @css.attrs([
      @css.create([@css.rule("color", "blue"), @css.rule("display", "flex")]),
    ]).class_name,
  )
  let output = @css.stylesheet([result])
  assert_false(output.contains("red"))
  assert_false(output.contains(":hover"))
  assert_false(output.contains("@media"))
  assert_true(output.contains("color:blue"))
  assert_true(@css.stylesheet([base]).contains(":hover"))
}

///|
test "conditions within a style survive and identical slots use the last value" {
  let style = @css.create([
    @css.rule("color", "red"),
    @css.rule("color", "blue"),
    @css.rule_on(":hover", "color", "green"),
    @css.rule_when("min-width:768px", ":hover", "color", "purple"),
  ])
  let output = @css.stylesheet([style])
  assert_false(output.contains("color:red"))
  assert_true(output.contains("color:blue"))
  assert_true(output.contains(":hover{color:green}"))
  assert_true(output.contains(":hover{color:purple}"))
  assert_true(output.contains("@media(min-width:768px)"))
}

///|
test "pseudo elements have separate property namespaces" {
  let base = @css.create([
    @css.rule("color", "red"),
    @css.rule_on("::before", "color", "pink"),
  ])
  let output = @css.stylesheet([
    @css.compose([base, @css.create([@css.rule("color", "blue")])]),
  ])
  assert_true(output.contains("::before{color:pink}"))
  assert_true(output.contains("color:blue"))
  assert_false(output.contains("color:red"))
}

///|
test "unset removes all conditions and remains effective through composition" {
  let base = @css.create([
    @css.rule("color", "red"),
    @css.rule_on(":hover", "color", "green"),
  ])
  let removed = @css.compose([
    @css.create([@css.rule("display", "flex")]),
    @css.create([@css.unset("color")]),
  ])
  let result = @css.compose([base, removed])
  assert_eq(
    @css.attrs([result]).class_name,
    @css.attrs([@css.create([@css.rule("display", "flex")])]).class_name,
  )
  assert_eq(@css.stylesheet([@css.create([@css.unset("color")])]), "")
  assert_eq(
    @css.stylesheet([
      @css.create([
        @css.rule_on(":hover", "color", "green"),
        @css.unset("color"),
      ]),
    ]),
    "",
  )
}

///|
test "responsive CSS orders numeric breakpoints and max queries deterministically" {
  let style = @css.create([
    @css.rule_media("min-width:1024px", "color", "blue"),
    @css.rule_media("min-width:768px", "color", "red"),
    @css.rule_media("max-width:768px", "display", "block"),
    @css.rule_media("max-width:1024px", "display", "flex"),
  ])
  let output = @css.stylesheet([style])
  assert_true(
    output.find("min-width:768px").unwrap() <
    output.find("min-width:1024px").unwrap(),
  )
  assert_true(
    output.find("max-width:1024px").unwrap() <
    output.find("max-width:768px").unwrap(),
  )
}

///|
test "stylesheet text cannot close an SSR style element" {
  let style = @css.create([@css.rule_on("::before", "content", "\"</style>\"")])
  assert_false(@css.stylesheet([style]).contains("</style>"))
  assert_true(@css.stylesheet([style]).contains("\\3c /style>"))
}

///|
test "conditional style and empty composition" {
  let base = @css.create([@css.rule("color", "red")])
  let active = @css.create([@css.rule("color", "blue")])
  assert_eq(@css.attrs([base, active.when(false)]), @css.attrs([base]))
  assert_eq(@css.attrs([base, active.when(true)]), @css.attrs([active]))
  assert_eq(@css.attrs([]).class_name, "")
  assert_eq(@css.attrs([]).style, "")
}

///|
test "styles do not depend on global registries or caller mutation" {
  @css.reset_all()
  let declarations = [@css.rule("display", "flex")]
  let style = @css.create(declarations)
  let before = @css.attrs([style])
  let css_before = @css.stylesheet([style])
  declarations.push(@css.rule("color", "red"))
  ignore(@css.css("color", "green"))
  @css.reset_all()
  assert_eq(@css.attrs([style]), before)
  assert_eq(@css.stylesheet([style]), css_before)
  assert_eq(@css.registry_size(), 0)
}

///|
test "stylesheets deduplicate and have stable order independent of collection" {
  let a = @css.create([
    @css.rule("color", "red"),
    @css.rule_media("min-width:768px", "width", "10px"),
  ])
  let b = @css.create([@css.rule("display", "flex"), @css.rule("color", "red")])
  assert_eq(@css.stylesheet([a, b, a]), @css.stylesheet([b, a]))
  assert_eq(
    @css.attrs([@css.compose([a, b])]),
    @css.attrs([@css.compose([b, a])]),
  )
}

///|
test "themes compose while dynamic values stay out of generated CSS" {
  let light = @css.create_theme([("--surface", "white"), ("--text", "black")])
  let dark = @css.create_theme([("--surface", "black")])
  let component = @css.create([
    @css.rule("background-color", "var(--surface)"),
    @css.rule("width", "var(--width)"),
  ])
  let small = component.with_vars([("--width", "12px")])
  let large = component.with_vars([("--width", "24px")])
  assert_eq(@css.attrs([small]).class_name, @css.attrs([large]).class_name)
  assert_eq(@css.stylesheet([small]), @css.stylesheet([large]))
  assert_eq(@css.attrs([small, large]).style, "--width:24px")
  assert_eq(@css.attrs([component]).style, "")
  let themed = @css.stylesheet([@css.compose([light, dark])])
  assert_true(themed.contains("--surface:black"))
  assert_true(themed.contains("--text:black"))
  assert_false(themed.contains("--surface:white"))
}

///|
test "custom property APIs reject ordinary properties" {
  try @css.create_theme([("color", "red")]) catch {
    _ => ()
  } noraise {
    _ => fail("ordinary properties must be rejected")
  }
  try @css.create([]).with_vars([("width", "12px")]) catch {
    _ => ()
  } noraise {
    _ => fail("ordinary properties must be rejected")
  }
  try @css.create_theme([("--bad;name", "red")]) catch {
    _ => ()
  } noraise {
    _ => fail("invalid custom property names must be rejected")
  }
}
