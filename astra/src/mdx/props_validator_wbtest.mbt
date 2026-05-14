///|
using @test {assert_eq}

// MDX Props Validator Tests

// =============================================================================
// check_literal_compat Tests
// =============================================================================

///|
test "check_literal_compat: String value for String field" {
  assert_true(check_literal_compat("hello", "String") is None)
}

///|
test "check_literal_compat: valid Int literal" {
  assert_true(check_literal_compat("42", "Int") is None)
}

///|
test "check_literal_compat: negative Int literal" {
  assert_true(check_literal_compat("-5", "Int") is None)
}

///|
test "check_literal_compat: invalid Int literal" {
  match check_literal_compat("hello", "Int") {
    Some(msg) => assert_true(msg.contains("expected Int"))
    None => fail("expected error")
  }
}

///|
test "check_literal_compat: valid Double literal" {
  assert_true(check_literal_compat("3.14", "Double") is None)
}

///|
test "check_literal_compat: invalid Double literal" {
  match check_literal_compat("abc", "Double") {
    Some(msg) => assert_true(msg.contains("expected Double"))
    None => fail("expected error")
  }
}

///|
test "check_literal_compat: valid Bool literal true" {
  assert_true(check_literal_compat("true", "Bool") is None)
}

///|
test "check_literal_compat: valid Bool literal false" {
  assert_true(check_literal_compat("false", "Bool") is None)
}

///|
test "check_literal_compat: invalid Bool literal" {
  match check_literal_compat("yes", "Bool") {
    Some(msg) => assert_true(msg.contains("expected Bool"))
    None => fail("expected error")
  }
}

///|
test "check_literal_compat: optional Int accepts valid" {
  assert_true(check_literal_compat("10", "Int?") is None)
}

///|
test "check_literal_compat: unknown type is always ok" {
  assert_true(check_literal_compat("anything", "MyCustomType") is None)
}

// =============================================================================
// build_props_schema Tests
// =============================================================================

///|
test "build_props_schema: basic struct" {
  let s : PropsStructInput = {
    name: "CounterProps",
    raw_definition: "pub struct CounterProps {\n  count : Int\n  label : String\n}",
  }
  let fields = build_props_schema(s)
  assert_eq(fields.length(), 2)
  assert_eq(fields[0].name, "count")
  assert_eq(fields[0].type_str, "Int")
  assert_false(fields[0].optional)
  assert_eq(fields[1].name, "label")
  assert_eq(fields[1].type_str, "String")
}

///|
test "build_props_schema: optional fields" {
  let s : PropsStructInput = {
    name: "WidgetProps",
    raw_definition: "pub struct WidgetProps {\n  title : String\n  count : Int?\n}",
  }
  let fields = build_props_schema(s)
  assert_eq(fields.length(), 2)
  assert_false(fields[0].optional)
  assert_true(fields[1].optional)
}

// =============================================================================
// ComponentPropsRegistry Tests
// =============================================================================

///|
test "ComponentPropsRegistry: lookup by JSX tag" {
  let structs : Array[PropsStructInput] = [
    {
      name: "CounterProps",
      raw_definition: "pub struct CounterProps {\n  count : Int\n}",
    },
  ]
  let registry = ComponentPropsRegistry::from_structs(structs)
  // "Counter" (PascalCase) → "counter" (lowercase) lookup
  match registry.lookup("Counter") {
    Some(fields) => {
      assert_eq(fields.length(), 1)
      assert_eq(fields[0].name, "count")
    }
    None => fail("expected fields for Counter")
  }
}

///|
test "ComponentPropsRegistry: lookup unknown returns None" {
  let registry = ComponentPropsRegistry::from_structs([])
  assert_true(registry.lookup("Unknown") is None)
}

// =============================================================================
// validate_jsx_embed Tests
// =============================================================================

///|
fn make_registry() -> ComponentPropsRegistry {
  ComponentPropsRegistry::from_structs([
    {
      name: "CounterProps",
      raw_definition: "pub struct CounterProps {\n  count : Int\n  label : String\n}",
    },
    {
      name: "ToggleProps",
      raw_definition: "pub struct ToggleProps {\n  enabled : Bool\n  text : String?\n}",
    },
  ])
}

///|
test "validate_jsx_embed: all required fields provided with correct types" {
  let registry = make_registry()
  let embed : @astra.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @astra.MdxAttrValue::StringLiteral("10")),
      ("label", @astra.MdxAttrValue::StringLiteral("Click")),
    ],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq(diags.length(), 0)
}

///|
test "validate_jsx_embed: missing required field" {
  let registry = make_registry()
  let embed : @astra.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [("count", @astra.MdxAttrValue::StringLiteral("5"))],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq(diags.length(), 1)
  assert_true(diags[0].message.contains("missing required prop \"label\""))
  assert_true(diags[0].severity is Error)
}

///|
test "validate_jsx_embed: type mismatch - string for Int field" {
  let registry = make_registry()
  let embed : @astra.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @astra.MdxAttrValue::StringLiteral("not_a_number")),
      ("label", @astra.MdxAttrValue::StringLiteral("ok")),
    ],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq(diags.length(), 1)
  assert_true(diags[0].message.contains("expected Int"))
}

///|
test "validate_jsx_embed: unknown prop produces warning" {
  let registry = make_registry()
  let embed : @astra.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @astra.MdxAttrValue::StringLiteral("1")),
      ("label", @astra.MdxAttrValue::StringLiteral("ok")),
      ("unknown_prop", @astra.MdxAttrValue::StringLiteral("val")),
    ],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq(diags.length(), 1)
  assert_true(diags[0].message.contains("unknown prop"))
  assert_true(diags[0].severity is Warning)
}

///|
test "validate_jsx_embed: expression values are skipped" {
  let registry = make_registry()
  let embed : @astra.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @astra.MdxAttrValue::Expression("state.count")),
      ("label", @astra.MdxAttrValue::StringLiteral("ok")),
    ],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq(diags.length(), 0)
}

///|
test "validate_jsx_embed: optional field not required" {
  let registry = make_registry()
  let embed : @astra.JsxComponentEmbed = {
    tag: "Toggle",
    attrs: [("enabled", @astra.MdxAttrValue::Boolean)],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  // "text" is optional (String?) so not an error
  let diags = validate_jsx_embed(embed, registry)
  assert_eq(diags.length(), 0)
}

///|
test "validate_jsx_embed: Boolean attr for Bool field is fine" {
  let registry = make_registry()
  let embed : @astra.JsxComponentEmbed = {
    tag: "Toggle",
    attrs: [("enabled", @astra.MdxAttrValue::Boolean)],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq(diags.length(), 0)
}

///|
test "validate_jsx_embed: Boolean attr for non-Bool field warns" {
  let registry = make_registry()
  let embed : @astra.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @astra.MdxAttrValue::Boolean), // Bool for Int field
      ("label", @astra.MdxAttrValue::StringLiteral("ok")),
    ],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq(diags.length(), 1)
  assert_true(diags[0].message.contains("bare attribute"))
}

///|
test "validate_jsx_embed: unknown component is silently skipped" {
  let registry = make_registry()
  let embed : @astra.JsxComponentEmbed = {
    tag: "ExternalWidget",
    attrs: [("anything", @astra.MdxAttrValue::StringLiteral("val"))],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq(diags.length(), 0)
}

///|
test "validate_jsx_embed: cls and trigger attrs ignored" {
  let registry = make_registry()
  let embed : @astra.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @astra.MdxAttrValue::StringLiteral("1")),
      ("label", @astra.MdxAttrValue::StringLiteral("ok")),
      ("cls:width", @astra.MdxAttrValue::StringLiteral("200px")),
      ("trigger", @astra.MdxAttrValue::StringLiteral("visible")),
    ],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq(diags.length(), 0)
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
  assert_eq(d.to_string(), "error: <Counter> missing required prop \"count\"")
}

///|
test "PropsDiagnostic::to_string warning format" {
  let d : PropsDiagnostic = {
    component: "Counter",
    severity: Warning,
    message: "unknown prop \"foo\"",
  }
  assert_eq(d.to_string(), "warning: <Counter> unknown prop \"foo\"")
}

// =============================================================================
// check_literal_compat: edge cases
// =============================================================================

///|
test "check_literal_compat: zero is valid Int" {
  assert_true(check_literal_compat("0", "Int") is None)
}

///|
test "check_literal_compat: large Int" {
  assert_true(check_literal_compat("999999", "Int") is None)
}

///|
test "check_literal_compat: float string is invalid Int" {
  match check_literal_compat("3.14", "Int") {
    Some(msg) => assert_true(msg.contains("expected Int"))
    None => fail("expected error for float as Int")
  }
}

///|
test "check_literal_compat: empty string is invalid Int" {
  match check_literal_compat("", "Int") {
    Some(msg) => assert_true(msg.contains("expected Int"))
    None => fail("expected error for empty string as Int")
  }
}

///|
test "check_literal_compat: Float type alias works like Double" {
  assert_true(check_literal_compat("1.5", "Float") is None)
}

///|
test "check_literal_compat: Int valid for Double field" {
  assert_true(check_literal_compat("42", "Double") is None)
}

///|
test "check_literal_compat: negative Double" {
  assert_true(check_literal_compat("-0.5", "Double") is None)
}

///|
test "check_literal_compat: optional Bool accepts true" {
  assert_true(check_literal_compat("true", "Bool?") is None)
}

///|
test "check_literal_compat: optional Bool rejects garbage" {
  match check_literal_compat("maybe", "Bool?") {
    Some(msg) => assert_true(msg.contains("expected Bool"))
    None => fail("expected error")
  }
}

///|
test "check_literal_compat: Array type is unknown, always ok" {
  assert_true(check_literal_compat("anything", "Array[Int]") is None)
}

///|
test "check_literal_compat: empty string for String is ok" {
  assert_true(check_literal_compat("", "String") is None)
}

// =============================================================================
// build_props_schema: edge cases
// =============================================================================

///|
test "build_props_schema: empty struct" {
  let s : PropsStructInput = {
    name: "EmptyProps",
    raw_definition: "pub struct EmptyProps {}",
  }
  let fields = build_props_schema(s)
  assert_eq(fields.length(), 0)
}

///|
test "build_props_schema: struct with comments" {
  let s : PropsStructInput = {
    name: "Props",
    raw_definition: "pub struct Props {\n  // comment\n  name : String\n}",
  }
  let fields = build_props_schema(s)
  assert_eq(fields.length(), 1)
  assert_eq(fields[0].name, "name")
}

///|
test "build_props_schema: struct with trailing comma" {
  let s : PropsStructInput = {
    name: "Props",
    raw_definition: "pub struct Props {\n  x : Int,\n  y : Int,\n}",
  }
  let fields = build_props_schema(s)
  assert_eq(fields.length(), 2)
  assert_eq(fields[0].type_str, "Int")
  assert_eq(fields[1].type_str, "Int")
}

///|
test "build_props_schema: complex type field" {
  let s : PropsStructInput = {
    name: "Props",
    raw_definition: "pub struct Props {\n  items : Array[String]\n  cb : (Int) -> Bool\n}",
  }
  let fields = build_props_schema(s)
  assert_eq(fields.length(), 2)
  assert_eq(fields[0].type_str, "Array[String]")
  assert_false(fields[0].optional)
}

// =============================================================================
// ComponentPropsRegistry: edge cases
// =============================================================================

///|
test "ComponentPropsRegistry: multiple components" {
  let registry = ComponentPropsRegistry::from_structs([
    {
      name: "CounterProps",
      raw_definition: "pub struct CounterProps {\n  count : Int\n}",
    },
    {
      name: "ButtonProps",
      raw_definition: "pub struct ButtonProps {\n  label : String\n  disabled : Bool\n}",
    },
  ])
  assert_true(registry.lookup("Counter") is Some(_))
  assert_true(registry.lookup("Button") is Some(_))
  assert_true(registry.lookup("Nonexistent") is None)
}

///|
test "ComponentPropsRegistry: PascalCase multi-word lookup" {
  let registry = ComponentPropsRegistry::from_structs([
    {
      name: "MyWidgetProps",
      raw_definition: "pub struct MyWidgetProps {\n  value : Int\n}",
    },
  ])
  // "MyWidget" → "mywidget" via to_lower, but registry stores "my_widget"
  // This tests whether the lookup matches correctly
  match registry.lookup("my_widget") {
    Some(fields) => assert_eq(fields[0].name, "value")
    None => fail("expected fields")
  }
}

// =============================================================================
// validate_jsx_embed: more edge cases
// =============================================================================

///|
test "validate_jsx_embed: all fields missing" {
  let registry = make_registry()
  let embed : @astra.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  // count and label are both required
  assert_eq(diags.length(), 2)
  let messages = diags.map(fn(d) { d.message })
  assert_true(messages.iter().any(fn(m) { m.contains("\"count\"") }))
  assert_true(messages.iter().any(fn(m) { m.contains("\"label\"") }))
}

///|
test "validate_jsx_embed: multiple errors at once" {
  let registry = make_registry()
  let embed : @astra.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @astra.MdxAttrValue::StringLiteral("abc")), // type mismatch
      // label missing
      ("extra", @astra.MdxAttrValue::StringLiteral("x")), // unknown
    ],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  // type mismatch (count) + unknown (extra) + missing (label) = 3
  assert_eq(diags.length(), 3)
}

///|
test "validate_jsx_embed: luna:trigger attr ignored" {
  let registry = make_registry()
  let embed : @astra.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @astra.MdxAttrValue::StringLiteral("1")),
      ("label", @astra.MdxAttrValue::StringLiteral("ok")),
      ("luna:trigger", @astra.MdxAttrValue::StringLiteral("idle")),
    ],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq(diags.length(), 0)
}

///|
test "validate_jsx_embed: cls:height attr ignored" {
  let registry = make_registry()
  let embed : @astra.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @astra.MdxAttrValue::StringLiteral("1")),
      ("label", @astra.MdxAttrValue::StringLiteral("ok")),
      ("cls:height", @astra.MdxAttrValue::StringLiteral("100px")),
    ],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq(diags.length(), 0)
}

///|
test "validate_jsx_embed: all expressions skips all type checks" {
  let registry = make_registry()
  let embed : @astra.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @astra.MdxAttrValue::Expression("getCount()")),
      ("label", @astra.MdxAttrValue::Expression("getLabel()")),
    ],
    children: "",
    self_closing: true,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq(diags.length(), 0)
}

///|
test "validate_jsx_embed: non-self-closing with children" {
  let registry = make_registry()
  let embed : @astra.JsxComponentEmbed = {
    tag: "Counter",
    attrs: [
      ("count", @astra.MdxAttrValue::StringLiteral("5")),
      ("label", @astra.MdxAttrValue::StringLiteral("ok")),
    ],
    children: "<span>inner</span>",
    self_closing: false,
    cls_hints: None,
  }
  let diags = validate_jsx_embed(embed, registry)
  assert_eq(diags.length(), 0)
}

// =============================================================================
// validate_mdx_props: batch validation with MdNode tree
// =============================================================================

///|
test "validate_mdx_props: empty nodes" {
  let registry = make_registry()
  let diags = validate_mdx_props([], registry)
  assert_eq(diags.length(), 0)
}

///|
test "validate_mdx_props: text-only nodes produce no diagnostics" {
  let registry = make_registry()
  let nodes : Array[@astra.MdNode] = [
    @astra.MdNode::Text("hello"),
    @astra.MdNode::ThematicBreak,
    @astra.MdNode::CodeBlock(lang="moonbit", code="let x = 1"),
  ]
  let diags = validate_mdx_props(nodes, registry)
  assert_eq(diags.length(), 0)
}

///|
test "validate_mdx_props: finds JsxComponent at top level" {
  let registry = make_registry()
  let nodes : Array[@astra.MdNode] = [
    @astra.MdNode::JsxComponent({
      tag: "Counter",
      attrs: [], // missing both required fields
      children: "",
      self_closing: true,
      cls_hints: None,
    }),
  ]
  let diags = validate_mdx_props(nodes, registry)
  assert_eq(diags.length(), 2) // missing count + label
}

///|
test "validate_mdx_props: finds JsxComponent nested in Paragraph" {
  let registry = make_registry()
  let nodes : Array[@astra.MdNode] = [
    @astra.MdNode::Paragraph(children=[
      @astra.MdNode::Text("Before "),
      @astra.MdNode::JsxComponent({
        tag: "Counter",
        attrs: [("count", @astra.MdxAttrValue::StringLiteral("bad"))],
        children: "",
        self_closing: true,
        cls_hints: None,
      }),
    ]),
  ]
  let diags = validate_mdx_props(nodes, registry)
  // type mismatch on "count" + missing "label"
  assert_eq(diags.length(), 2)
}

///|
test "validate_mdx_props: finds JsxComponent nested in Heading" {
  let registry = make_registry()
  let nodes : Array[@astra.MdNode] = [
    @astra.MdNode::Heading(level=1, id="title", children=[
      @astra.MdNode::JsxComponent({
        tag: "Counter",
        attrs: [
          ("count", @astra.MdxAttrValue::StringLiteral("1")),
          ("label", @astra.MdxAttrValue::StringLiteral("ok")),
        ],
        children: "",
        self_closing: true,
        cls_hints: None,
      }),
    ]),
  ]
  let diags = validate_mdx_props(nodes, registry)
  assert_eq(diags.length(), 0)
}

///|
test "validate_mdx_props: finds JsxComponent in List items" {
  let registry = make_registry()
  let nodes : Array[@astra.MdNode] = [
    @astra.MdNode::List(ordered=false, items=[
      [
        @astra.MdNode::JsxComponent({
          tag: "Counter",
          attrs: [],
          children: "",
          self_closing: true,
          cls_hints: None,
        }),
      ],
    ]),
  ]
  let diags = validate_mdx_props(nodes, registry)
  assert_eq(diags.length(), 2) // missing count + label
}

///|
test "validate_mdx_props: multiple components across tree" {
  let registry = make_registry()
  let nodes : Array[@astra.MdNode] = [
    @astra.MdNode::JsxComponent({
      tag: "Counter",
      attrs: [
        ("count", @astra.MdxAttrValue::StringLiteral("1")),
        ("label", @astra.MdxAttrValue::StringLiteral("a")),
      ],
      children: "",
      self_closing: true,
      cls_hints: None,
    }),
    @astra.MdNode::Paragraph(children=[
      @astra.MdNode::JsxComponent({
        tag: "Toggle",
        attrs: [], // missing required "enabled"
        children: "",
        self_closing: true,
        cls_hints: None,
      }),
    ]),
  ]
  let diags = validate_mdx_props(nodes, registry)
  // Counter is valid, Toggle is missing "enabled"
  assert_eq(diags.length(), 1)
  assert_true(diags[0].component == "Toggle")
}

///|
test "validate_mdx_props: deeply nested Bold > Italic > JsxComponent" {
  let registry = make_registry()
  let nodes : Array[@astra.MdNode] = [
    @astra.MdNode::Bold(children=[
      @astra.MdNode::Italic(children=[
        @astra.MdNode::JsxComponent({
          tag: "Counter",
          attrs: [
            ("count", @astra.MdxAttrValue::StringLiteral("x")), // invalid Int
            ("label", @astra.MdxAttrValue::StringLiteral("ok")),
          ],
          children: "",
          self_closing: true,
          cls_hints: None,
        }),
      ]),
    ]),
  ]
  let diags = validate_mdx_props(nodes, registry)
  assert_eq(diags.length(), 1)
  assert_true(diags[0].message.contains("expected Int"))
}

///|
test "validate_mdx_props: ignores non-traversable nodes" {
  let registry = make_registry()
  let nodes : Array[@astra.MdNode] = [
    @astra.MdNode::Image(src="/img.png", alt="alt", title=""),
    @astra.MdNode::Html("<div>raw</div>"),
    @astra.MdNode::Code("inline code"),
    @astra.MdNode::LineBreak,
  ]
  let diags = validate_mdx_props(nodes, registry)
  assert_eq(diags.length(), 0)
}
