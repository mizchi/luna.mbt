///|
test "composition replaces a property together with its conditions" {
  let base = create([
    rule("color", "red"),
    rule_on(":hover", "color", "green"),
    rule_media("min-width:768px", "color", "purple"),
    rule("display", "flex"),
  ])
  let override = create([rule("color", "blue")])
  let result = compose([base, override])
  assert_eq(
    attrs([result]).class_name,
    attrs([create([rule("color", "blue"), rule("display", "flex")])]).class_name,
  )
  let output = stylesheet([result])
  assert_false(output.contains("red"))
  assert_false(output.contains(":hover"))
  assert_false(output.contains("@media"))
  assert_true(output.contains("color:blue"))
  assert_true(stylesheet([base]).contains(":hover"))
}

///|
test "conditions within a style survive and identical slots use the last value" {
  let style = create([
    rule("color", "red"),
    rule("color", "blue"),
    rule_on(":hover", "color", "green"),
    rule_when("min-width:768px", ":hover", "color", "purple"),
  ])
  let output = stylesheet([style])
  assert_false(output.contains("color:red"))
  assert_true(output.contains("color:blue"))
  assert_true(output.contains(":hover{color:green}"))
  assert_true(output.contains(":hover{color:purple}"))
  assert_true(output.contains("@media(min-width:768px)"))
}

///|
test "pseudo elements have separate property namespaces" {
  let base = create([rule("color", "red"), rule_on("::before", "color", "pink")])
  let output = stylesheet([compose([base, create([rule("color", "blue")])])])
  assert_true(output.contains("::before{color:pink}"))
  assert_true(output.contains("color:blue"))
  assert_false(output.contains("color:red"))
}

///|
test "unset removes all conditions and remains effective through composition" {
  let base = create([rule("color", "red"), rule_on(":hover", "color", "green")])
  let removed = compose([
    create([rule("display", "flex")]),
    create([unset("color")]),
  ])
  let result = compose([base, removed])
  assert_eq(
    attrs([result]).class_name,
    attrs([create([rule("display", "flex")])]).class_name,
  )
  assert_eq(stylesheet([create([unset("color")])]), "")
  assert_eq(
    stylesheet([create([rule_on(":hover", "color", "green"), unset("color")])]),
    "",
  )
}

///|
test "responsive CSS orders numeric breakpoints and max queries deterministically" {
  let style = create([
    rule_media("min-width:1024px", "color", "blue"),
    rule_media("min-width:768px", "color", "red"),
    rule_media("max-width:768px", "display", "block"),
    rule_media("max-width:1024px", "display", "flex"),
  ])
  let output = stylesheet([style])
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
  let style = create([rule_on("::before", "content", "\"</style>\"")])
  assert_false(stylesheet([style]).contains("</style>"))
  assert_true(stylesheet([style]).contains("\\3c /style>"))
}

///|
test "conditional style and empty composition" {
  let base = create([rule("color", "red")])
  let active = create([rule("color", "blue")])
  assert_eq(attrs([base, active.when(false)]), attrs([base]))
  assert_eq(attrs([base, active.when(true)]), attrs([active]))
  assert_eq(attrs([]).class_name, "")
  assert_eq(attrs([]).style, "")
}

///|
test "styles do not depend on global registries or caller mutation" {
  reset_all()
  let declarations = [rule("display", "flex")]
  let style = create(declarations)
  let before = attrs([style])
  let css_before = stylesheet([style])
  declarations.push(rule("color", "red"))
  ignore(css("color", "green"))
  reset_all()
  assert_eq(attrs([style]), before)
  assert_eq(stylesheet([style]), css_before)
  assert_eq(registry_size(), 0)
}

///|
test "stylesheets deduplicate and have stable order independent of collection" {
  let a = create([
    rule("color", "red"),
    rule_media("min-width:768px", "width", "10px"),
  ])
  let b = create([rule("display", "flex"), rule("color", "red")])
  assert_eq(stylesheet([a, b, a]), stylesheet([b, a]))
  assert_eq(attrs([compose([a, b])]), attrs([compose([b, a])]))
}

///|
test "themes compose while dynamic values stay out of generated CSS" {
  let light = create_theme([("--surface", "white"), ("--text", "black")])
  let dark = create_theme([("--surface", "black")])
  let component = create([
    rule("background-color", "var(--surface)"),
    rule("width", "var(--width)"),
  ])
  let small = component.with_vars([("--width", "12px")])
  let large = component.with_vars([("--width", "24px")])
  assert_eq(attrs([small]).class_name, attrs([large]).class_name)
  assert_eq(stylesheet([small]), stylesheet([large]))
  assert_eq(attrs([small, large]).style, "--width:24px")
  assert_eq(attrs([component]).style, "")
  let themed = stylesheet([compose([light, dark])])
  assert_true(themed.contains("--surface:black"))
  assert_true(themed.contains("--text:black"))
  assert_false(themed.contains("--surface:white"))
}

///|
test "custom property APIs reject ordinary properties" {
  assert_true((try? create_theme([("color", "red")])) is Err(_))
  assert_true((try? create([]).with_vars([("width", "12px")])) is Err(_))
  assert_true((try? create_theme([("--bad;name", "red")])) is Err(_))
}
