///|
test "tab_computed creates tab with computed selected" {
  let selected_index = @resource.signal(0)
  let node : @luna.Node[@js.Any, String] = tab_computed(
    "tab-0",
    fn() { selected_index.get() == 0 },
    "panel-0",
    [@luna.text("Tab 1")],
  )
  match node {
    @core.Element({ tag, attrs, .. }) => {
      assert_eq(tag, "button")
      assert_true(attrs.length() >= 4)
    }
    _ => panic()
  }
}

///|
test "tabpanel_computed creates panel with computed visibility" {
  let visible = @resource.signal(true)
  let node : @luna.Node[@js.Any, String] = tabpanel_computed(
    "panel-0",
    "tab-0",
    fn() { visible.get() },
    [@luna.text("Content")],
  )
  match node {
    @core.Element({ tag, attrs, .. }) => {
      assert_eq(tag, "div")
      // Should have role, id, aria-labelledby, tabindex, style attributes
      assert_true(attrs.length() >= 5)
    }
    _ => panic()
  }
}

///|
test "checkbox_computed creates checkbox with computed state" {
  let checked = @resource.signal(@components.Checked)
  let node : @luna.Node[@js.Any, String] = checkbox_computed(
    fn() { checked.get() },
    aria_label="Test checkbox",
    [@luna.text("Check me")],
  )
  match node {
    @core.Element({ tag, attrs, .. }) => {
      assert_eq(tag, "div")
      assert_true(attrs.length() >= 3)
    }
    _ => panic()
  }
}

///|
test "switch_computed creates switch with computed state" {
  let on = @resource.signal(false)
  let node : @luna.Node[@js.Any, String] = switch_computed(
    fn() { on.get() },
    aria_label="Toggle",
    [@luna.text("Switch")],
  )
  match node {
    @core.Element({ tag, attrs, .. }) => {
      assert_eq(tag, "button")
      assert_true(attrs.length() >= 3)
    }
    _ => panic()
  }
}

///|
test "radio_computed creates radio with computed checked" {
  let selected = @resource.signal("option1")
  let node : @luna.Node[@js.Any, String] = radio_computed(
    "option1",
    fn() { selected.get() == "option1" },
    [@luna.text("Option 1")],
  )
  match node {
    @core.Element({ tag, attrs, .. }) => {
      assert_eq(tag, "div")
      assert_true(attrs.length() >= 3)
    }
    _ => panic()
  }
}

///|
test "accordion_header_computed creates header with computed expanded" {
  let expanded = @resource.signal(0)
  let node : @luna.Node[@js.Any, String] = accordion_header_computed(
    "header-0",
    fn() { expanded.get() == 0 },
    "panel-0",
    [@luna.text("Section 1")],
  )
  match node {
    @core.Element({ tag, .. }) => assert_eq(tag, "h3")
    _ => panic()
  }
}

///|
test "disclosure_button_computed creates button with computed expanded" {
  let expanded = @resource.signal(false)
  let node : @luna.Node[@js.Any, String] = disclosure_button_computed(
    fn() { expanded.get() },
    "content-0",
    [@luna.text("Show")],
  )
  match node {
    @core.Element({ tag, attrs, .. }) => {
      assert_eq(tag, "button")
      assert_true(attrs.length() >= 3)
    }
    _ => panic()
  }
}

///|
test "tabs_dyn creates complete tabs with signal" {
  let selected = @resource.signal(0)
  let items : Array[TabItem[@js.Any]] = [
    tab_item("t1", "Tab 1", [@luna.text("Content 1")]),
    tab_item("t2", "Tab 2", [@luna.text("Content 2")]),
  ]
  let node = tabs_dyn(items, selected, aria_label="Test tabs")
  match node {
    @core.Fragment(_) => ()
    _ => panic()
  }
}

///|
test "accordion_dyn creates complete accordion with signal" {
  let expanded = @resource.signal(-1)
  let items : Array[AccordionItem[@js.Any]] = [
    accordion_item("a1", "Section 1", [@luna.text("Content 1")]),
    accordion_item("a2", "Section 2", [@luna.text("Content 2")]),
  ]
  let node = accordion_dyn(items, expanded)
  match node {
    @core.Element({ tag, .. }) => assert_eq(tag, "div")
    _ => panic()
  }
}

///|
test "disclosure_dyn creates complete disclosure with signal" {
  let expanded = @resource.signal(false)
  let node : @luna.Node[@js.Any, String] = disclosure_dyn(
    "disc",
    expanded,
    [@luna.text("Show more")],
    [@luna.text("Hidden content")],
  )
  match node {
    @core.Fragment(_) => ()
    _ => panic()
  }
}
