// Tests for Web Component code generation (whitebox)

test "tag_to_class_name" {
  // x-counter -> XCounter
  let result = tag_to_class_name("x-counter")
  assert_eq(result, "XCounter")
}

test "tag_to_class_name with multiple hyphens" {
  // my-custom-element -> MyCustomElement
  let result = tag_to_class_name("my-custom-element")
  assert_eq(result, "MyCustomElement")
}

test "attr_to_js_key" {
  // initial-count -> initialCount
  let result = attr_to_js_key("initial-count")
  assert_eq(result, "initialCount")
}

test "attr_to_js_key simple" {
  // count -> count
  let result = attr_to_js_key("count")
  assert_eq(result, "count")
}

test "generate simple component" {
  let meta = ComponentMeta::new("x-counter")
    .with_attr(attr_int("initial", default=0))
    .with_attr(attr_string("label", default="Count"))
    .with_attr(attr_bool("disabled", default=false))
    .with_styles(":host { display: block; }")

  let js = generate_component_js(meta, "./counter.mbt.js")

  // Check basic structure
  assert_true(js.contains("class XCounter extends HTMLElement"))
  assert_true(js.contains("static observedAttributes = ['initial', 'label', 'disabled']"))
  assert_true(js.contains("customElements.define('x-counter', XCounter)"))

  // Check props initialization
  assert_true(js.contains("initial: new Signal(0)"))
  assert_true(js.contains("label: new Signal('Count')"))
  assert_true(js.contains("disabled: new Signal(false)"))

  // Check stylesheet
  assert_true(js.contains("const sheet = new CSSStyleSheet()"))
  assert_true(js.contains(":host { display: block; }"))
}

test "generate component without shadow dom" {
  let meta = ComponentMeta::new("x-light")
    .with_attr(attr_string("name", default=""))
    .with_shadow(ShadowMode::None)

  let js = generate_component_js(meta, "./light.mbt.js")

  // Should use light DOM
  assert_true(js.contains("const shadow = this;"))
  // Should not have stylesheet
  assert_false(js.contains("CSSStyleSheet"))
}

test "escape_js_string" {
  let result = escape_js_string("hello'world")
  assert_eq(result, "hello\\'world")
}

test "escape_template_literal" {
  let result = escape_template_literal("${foo}`bar")
  assert_eq(result, "\\${foo}\\`bar")
}
