// Tests for radix-components SSR output

///|
test "accordion_static renders with data-state" {
  let items : Array[AccordionItemProps] = [
    {
      id: "item-1",
      title: "Section 1",
      content: @element.text("Content 1"),
      default_open: true,
    },
    {
      id: "item-2",
      title: "Section 2",
      content: @element.text("Content 2"),
      default_open: false,
    },
  ]
  let node = accordion_static(items)
  let html = @static_dom.render(node)
  // Check data-accordion-item attributes
  assert_true(html.contains("data-accordion-item=\"item-1\""))
  assert_true(html.contains("data-accordion-item=\"item-2\""))
  // Check data-state for open/closed
  assert_true(html.contains("data-state=\"open\""))
  assert_true(html.contains("data-state=\"closed\""))
  // Check trigger elements
  assert_true(html.contains("data-accordion-trigger"))
  assert_true(html.contains("data-accordion-content"))
  assert_true(html.contains("data-chevron"))
}

///|
test "switch_static renders with aria-checked" {
  let node_checked = switch_static(true, Some("Enable feature"))
  let html_checked = @static_dom.render(node_checked)
  assert_true(html_checked.contains("aria-checked=\"true\""))
  assert_true(html_checked.contains("data-switch-toggle"))
  assert_true(html_checked.contains("data-switch-thumb"))
  assert_true(html_checked.contains("Enable feature"))
  let node_unchecked = switch_static(false, None)
  let html_unchecked = @static_dom.render(node_unchecked)
  assert_true(html_unchecked.contains("aria-checked=\"false\""))
}

///|
test "checkbox_static renders with aria-checked" {
  let node_checked = checkbox_static(Checked, Some("Accept terms"))
  let html_checked = @static_dom.render(node_checked)
  assert_true(html_checked.contains("aria-checked=\"true\""))
  assert_true(html_checked.contains("data-state=\"checked\""))
  assert_true(html_checked.contains("data-checkbox"))
  assert_true(html_checked.contains("Accept terms"))
  let node_unchecked = checkbox_static(Unchecked, None)
  let html_unchecked = @static_dom.render(node_unchecked)
  assert_true(html_unchecked.contains("aria-checked=\"false\""))
  assert_true(html_unchecked.contains("data-state=\"unchecked\""))
  let node_indeterminate = checkbox_static(Indeterminate, None)
  let html_indeterminate = @static_dom.render(node_indeterminate)
  assert_true(html_indeterminate.contains("aria-checked=\"mixed\""))
  assert_true(html_indeterminate.contains("data-state=\"indeterminate\""))
}

///|
test "accordion with island wrapper includes luna attributes" {
  let items : Array[AccordionItemProps] = [
    {
      id: "item-1",
      title: "Test",
      content: @element.text("Content"),
      default_open: false,
    },
  ]
  let node = accordion(
    { items, hydration_url: "/components/accordion.js" },
  )
  let html = @static_dom.render(node)
  assert_true(html.contains("luna:id=\"accordion\""))
  assert_true(html.contains("luna:url=\"/components/accordion.js\""))
  assert_true(html.contains("luna:client-trigger=\"visible\""))
}

///|
test "switch with island wrapper includes luna attributes" {
  let node = switch(
    {
      id: "switch-1",
      default_checked: true,
      label: Some("Test"),
      hydration_url: "/components/switch.js",
    },
  )
  let html = @static_dom.render(node)
  assert_true(html.contains("luna:id=\"switch-1\""))
  assert_true(html.contains("luna:url=\"/components/switch.js\""))
}

///|
test "checkbox with island wrapper includes luna attributes" {
  let node = checkbox(
    {
      id: "checkbox-1",
      default_state: Checked,
      label: Some("Test"),
      hydration_url: "/components/checkbox.js",
    },
  )
  let html = @static_dom.render(node)
  assert_true(html.contains("luna:id=\"checkbox-1\""))
  assert_true(html.contains("luna:url=\"/components/checkbox.js\""))
}
