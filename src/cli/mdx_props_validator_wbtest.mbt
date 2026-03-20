// MDX Props Validator Tests

// =============================================================================
// check_literal_compat Tests
// =============================================================================

///|
test "check_literal_compat: String value for String field" {
  assert_true!(check_literal_compat("hello", "String") is None)
}

///|
test "check_literal_compat: valid Int literal" {
  assert_true!(check_literal_compat("42", "Int") is None)
}

///|
test "check_literal_compat: negative Int literal" {
  assert_true!(check_literal_compat("-5", "Int") is None)
}

///|
test "check_literal_compat: invalid Int literal" {
  match check_literal_compat("hello", "Int") {
    Some(msg) => assert_true!(msg.contains("expected Int"))
    None => fail("expected error")
  }
}

///|
test "check_literal_compat: valid Double literal" {
  assert_true!(check_literal_compat("3.14", "Double") is None)
}

///|
test "check_literal_compat: invalid Double literal" {
  match check_literal_compat("abc", "Double") {
    Some(msg) => assert_true!(msg.contains("expected Double"))
    None => fail("expected error")
  }
}

///|
test "check_literal_compat: valid Bool literal true" {
  assert_true!(check_literal_compat("true", "Bool") is None)
}

///|
test "check_literal_compat: valid Bool literal false" {
  assert_true!(check_literal_compat("false", "Bool") is None)
}

///|
test "check_literal_compat: invalid Bool literal" {
  match check_literal_compat("yes", "Bool") {
    Some(msg) => assert_true!(msg.contains("expected Bool"))
    None => fail("expected error")
  }
}

///|
test "check_literal_compat: optional Int accepts valid" {
  assert_true!(check_literal_compat("10", "Int?") is None)
}

///|
test "check_literal_compat: unknown type is always ok" {
  assert_true!(check_literal_compat("anything", "MyCustomType") is None)
}

// =============================================================================
// build_props_schema Tests
// =============================================================================

///|
test "build_props_schema: basic struct" {
  let s : StructExport = {
    name: "CounterProps",
    raw_definition: "pub struct CounterProps {\n  count : Int\n  label : String\n}",
    package_path: "app/client/counter",
    import_alias: "counter",
  }
  let fields = build_props_schema(s)
  assert_eq!(fields.length(), 2)
  assert_eq!(fields[0].name, "count")
  assert_eq!(fields[0].type_str, "Int")
  assert_false!(fields[0].optional)
  assert_eq!(fields[1].name, "label")
  assert_eq!(fields[1].type_str, "String")
}

///|
test "build_props_schema: optional fields" {
  let s : StructExport = {
    name: "WidgetProps",
    raw_definition: "pub struct WidgetProps {\n  title : String\n  count : Int?\n}",
    package_path: "app/client/widget",
    import_alias: "widget",
  }
  let fields = build_props_schema(s)
  assert_eq!(fields.length(), 2)
  assert_false!(fields[0].optional)
  assert_true!(fields[1].optional)
}

// =============================================================================
// ComponentPropsRegistry Tests
// =============================================================================

///|
test "ComponentPropsRegistry: lookup by JSX tag" {
  let structs : Array[StructExport] = [
    {
      name: "CounterProps",
      raw_definition: "pub struct CounterProps {\n  count : Int\n}",
      package_path: "app/client/counter",
      import_alias: "counter",
    },
  ]
  let registry = ComponentPropsRegistry::from_structs(structs)
  // "Counter" (PascalCase) → "counter" (lowercase) lookup
  match registry.lookup("Counter") {
    Some(fields) => {
      assert_eq!(fields.length(), 1)
      assert_eq!(fields[0].name, "count")
    }
    None => fail("expected fields for Counter")
  }
}

///|
test "ComponentPropsRegistry: lookup unknown returns None" {
  let registry = ComponentPropsRegistry::from_structs([])
  assert_true!(registry.lookup("Unknown") is None)
}

// =============================================================================
// validate_jsx_embed Tests
// =============================================================================

fn make_registry() -> ComponentPropsRegistry {
  ComponentPropsRegistry::from_structs([
    {
      name: "CounterProps",
      raw_definition: "pub struct CounterProps {\n  count : Int\n  label : String\n}",
      package_path: "app/client/counter",
      import_alias: "counter",
    },
    {
      name: "ToggleProps",
      raw_definition: "pub struct ToggleProps {\n  enabled : Bool\n  text : String?\n}",
      package_path: "app/client/toggle",
      import_alias: "toggle",
    },
  ])
}

///|
test "validate_jsx_embed: all required fields provided with correct types" {
  let registry = make_registry()
  let embed : @ssg.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @ssg.MdxAttrValue::StringLiteral("10")),
      ("label", @ssg.MdxAttrValue::StringLiteral("Click")),
    ],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq!(diags.length(), 0)
}

///|
test "validate_jsx_embed: missing required field" {
  let registry = make_registry()
  let embed : @ssg.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [("count", @ssg.MdxAttrValue::StringLiteral("5"))],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq!(diags.length(), 1)
  assert_true!(diags[0].message.contains("missing required prop \"label\""))
  assert_true!(diags[0].severity is Error)
}

///|
test "validate_jsx_embed: type mismatch - string for Int field" {
  let registry = make_registry()
  let embed : @ssg.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @ssg.MdxAttrValue::StringLiteral("not_a_number")),
      ("label", @ssg.MdxAttrValue::StringLiteral("ok")),
    ],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq!(diags.length(), 1)
  assert_true!(diags[0].message.contains("expected Int"))
}

///|
test "validate_jsx_embed: unknown prop produces warning" {
  let registry = make_registry()
  let embed : @ssg.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @ssg.MdxAttrValue::StringLiteral("1")),
      ("label", @ssg.MdxAttrValue::StringLiteral("ok")),
      ("unknown_prop", @ssg.MdxAttrValue::StringLiteral("val")),
    ],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq!(diags.length(), 1)
  assert_true!(diags[0].message.contains("unknown prop"))
  assert_true!(diags[0].severity is Warning)
}

///|
test "validate_jsx_embed: expression values are skipped" {
  let registry = make_registry()
  let embed : @ssg.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @ssg.MdxAttrValue::Expression("state.count")),
      ("label", @ssg.MdxAttrValue::StringLiteral("ok")),
    ],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq!(diags.length(), 0)
}

///|
test "validate_jsx_embed: optional field not required" {
  let registry = make_registry()
  let embed : @ssg.JsxComponentEmbed = {
    tag: "Toggle",
    attrs: [("enabled", @ssg.MdxAttrValue::Boolean)],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  // "text" is optional (String?) so not an error
  let diags = validate_jsx_embed(embed, registry)
  assert_eq!(diags.length(), 0)
}

///|
test "validate_jsx_embed: Boolean attr for Bool field is fine" {
  let registry = make_registry()
  let embed : @ssg.JsxComponentEmbed = {
    tag: "Toggle",
    attrs: [("enabled", @ssg.MdxAttrValue::Boolean)],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq!(diags.length(), 0)
}

///|
test "validate_jsx_embed: Boolean attr for non-Bool field warns" {
  let registry = make_registry()
  let embed : @ssg.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @ssg.MdxAttrValue::Boolean), // Bool for Int field
      ("label", @ssg.MdxAttrValue::StringLiteral("ok")),
    ],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq!(diags.length(), 1)
  assert_true!(diags[0].message.contains("bare attribute"))
}

///|
test "validate_jsx_embed: unknown component is silently skipped" {
  let registry = make_registry()
  let embed : @ssg.JsxComponentEmbed = {
    tag: "ExternalWidget",
    attrs: [("anything", @ssg.MdxAttrValue::StringLiteral("val"))],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq!(diags.length(), 0)
}

///|
test "validate_jsx_embed: cls and trigger attrs ignored" {
  let registry = make_registry()
  let embed : @ssg.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @ssg.MdxAttrValue::StringLiteral("1")),
      ("label", @ssg.MdxAttrValue::StringLiteral("ok")),
      ("cls:width", @ssg.MdxAttrValue::StringLiteral("200px")),
      ("trigger", @ssg.MdxAttrValue::StringLiteral("visible")),
    ],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq!(diags.length(), 0)
}

// =============================================================================
// PropsDiagnostic::to_string Tests
// =============================================================================

///|
test "PropsDiagnostic::to_string error format" {
  let d : PropsDiagnostic = {
    component: "Counter",
    severity: Error,
    message: "missing required prop \"count\"",
  }
  assert_eq!(d.to_string(), "error: <Counter> missing required prop \"count\"")
}

///|
test "PropsDiagnostic::to_string warning format" {
  let d : PropsDiagnostic = {
    component: "Counter",
    severity: Warning,
    message: "unknown prop \"foo\"",
  }
  assert_eq!(d.to_string(), "warning: <Counter> unknown prop \"foo\"")
}
