///|
/// APG Components Playground
///
/// Interactive demos for WAI-ARIA APG compliant components

///|
fn div(children : Array[@luna.Node[@js.Any]]) -> @luna.Node[@js.Any] {
  @luna.h("div", [], children)
}

///|
fn h1(children : Array[@luna.Node[@js.Any]]) -> @luna.Node[@js.Any] {
  @luna.h("h1", [], children)
}

///|
fn h2(children : Array[@luna.Node[@js.Any]]) -> @luna.Node[@js.Any] {
  @luna.h("h2", [], children)
}

///|
fn p(children : Array[@luna.Node[@js.Any]]) -> @luna.Node[@js.Any] {
  @luna.h("p", [], children)
}

///|
fn span(children : Array[@luna.Node[@js.Any]]) -> @luna.Node[@js.Any] {
  @luna.h("span", [], children)
}

///|
fn hr() -> @luna.Node[@js.Any] {
  @luna.h("hr", [], [])
}

///|
fn btn(
  on_click : @luna.EventHandler[@js.Any],
  children : Array[@luna.Node[@js.Any]]
) -> @luna.Node[@js.Any] {
  @luna.h("button", [("click", @luna.attr_handler(on_click))], children)
}

// =============================================================================
// Button Demo
// =============================================================================

///|
fn button_demo() -> @luna.Node[@js.Any] {
  let pressed = @signal.signal(false)
  div([
    h2([@luna.text("Button")]),
    p([@luna.text("Basic button and toggle button examples")]),
    div([
      @apg.button([@luna.text("Click me")]),
      @apg.button(disabled=true, [@luna.text("Disabled")]),
    ]),
    p([@luna.text("Toggle Button:")]),
    div([
      @apg.toggle_button_dyn(
        pressed,
        on_click=@luna.handler(fn(_) { pressed.set(not(pressed.get())) }),
        [@luna.text("Mute")],
      ),
      span([
        @luna.text_dyn(fn() {
          " (pressed: " + pressed.get().to_string() + ")"
        }),
      ]),
    ]),
  ])
}

// =============================================================================
// Checkbox Demo
// =============================================================================

///|
fn checkbox_demo() -> @luna.Node[@js.Any] {
  let checked = @signal.signal(@apg.Unchecked)
  div([
    h2([@luna.text("Checkbox")]),
    p([@luna.text("Accessible checkbox with tri-state support")]),
    @apg.checkbox_dyn(
      checked,
      on_click=@luna.handler(fn(_) {
        let next = match checked.get() {
          @apg.Unchecked => @apg.Checked
          @apg.Checked => @apg.Unchecked
          @apg.Mixed => @apg.Checked
        }
        checked.set(next)
      }),
      [@luna.text("I agree to the terms")],
    ),
    p([
      @luna.text_dyn(fn() { "State: " + checkbox_state_string(checked.get()) }),
    ]),
  ])
}

///|
fn checkbox_state_string(state : @apg.CheckboxState) -> String {
  match state {
    @apg.Checked => "Checked"
    @apg.Unchecked => "Unchecked"
    @apg.Mixed => "Mixed"
  }
}

// =============================================================================
// Switch Demo
// =============================================================================

///|
fn switch_demo() -> @luna.Node[@js.Any] {
  let on = @signal.signal(false)
  div([
    h2([@luna.text("Switch")]),
    p([@luna.text("On/Off toggle switch")]),
    @apg.switch_dyn(
      on,
      aria_label="Enable notifications",
      on_click=@luna.handler(fn(_) { on.set(not(on.get())) }),
      [@luna.text("Notifications")],
    ),
    p([
      @luna.text_dyn(fn() {
        let status = if on.get() { "ON" } else { "OFF" }
        "Status: " + status
      }),
    ]),
  ])
}

// =============================================================================
// Radio Group Demo
// =============================================================================

///|
fn radio_demo() -> @luna.Node[@js.Any] {
  let selected = @signal.signal("option1")
  div([
    h2([@luna.text("Radio Group")]),
    p([@luna.text("Select one option from the group")]),
    @apg.radiogroup(
      aria_label="Choose an option",
      [
        @apg.radio_dyn(
          "option1",
          selected,
          on_click=@luna.handler(fn(_) { selected.set("option1") }),
          [@luna.text("Option 1")],
        ),
        @apg.radio_dyn(
          "option2",
          selected,
          on_click=@luna.handler(fn(_) { selected.set("option2") }),
          [@luna.text("Option 2")],
        ),
        @apg.radio_dyn(
          "option3",
          selected,
          on_click=@luna.handler(fn(_) { selected.set("option3") }),
          [@luna.text("Option 3")],
        ),
      ],
    ),
    p([@luna.text_dyn(fn() { "Selected: " + selected.get() })]),
  ])
}

// =============================================================================
// Tabs Demo
// =============================================================================

///|
fn tabs_demo() -> @luna.Node[@js.Any] {
  let active_tab = @signal.signal(0)
  let items : Array[@apg.TabItem[@js.Any]] = [
    @apg.tab_item("0", "Tab 1", [@luna.text("Content for Tab 1")]),
    @apg.tab_item("1", "Tab 2", [@luna.text("Content for Tab 2")]),
    @apg.tab_item("2", "Tab 3", [@luna.text("Content for Tab 3")]),
  ]
  div([
    h2([@luna.text("Tabs")]),
    p([@luna.text("Tabbed interface with keyboard navigation (use ←/→ arrows)")]),
    // Using tabs_interactive for full keyboard support
    @apg.tabs_interactive(items, active_tab, aria_label="Demo tabs"),
  ])
}

// =============================================================================
// Accordion Demo
// =============================================================================

///|
fn accordion_demo() -> @luna.Node[@js.Any] {
  let expanded = @signal.signal(-1) // -1 = all collapsed
  let items : Array[@apg.AccordionItem[@js.Any]] = [
    @apg.accordion_item("0", "Section 1", [@luna.text("Content for section 1")]),
    @apg.accordion_item("1", "Section 2", [@luna.text("Content for section 2")]),
    @apg.accordion_item("2", "Section 3", [@luna.text("Content for section 3")]),
  ]
  div([
    h2([@luna.text("Accordion")]),
    p([@luna.text("Expandable sections")]),
    @apg.accordion_dyn(items, expanded),
  ])
}

// =============================================================================
// Slider Demo
// =============================================================================

///|
fn slider_demo() -> @luna.Node[@js.Any] {
  let value = @signal.signal(50.0)
  div([
    h2([@luna.text("Slider")]),
    p([@luna.text("Accessible range input (use ←/→/↑/↓, Home/End, PageUp/PageDown)")]),
    @apg.slider_interactive(
      value,
      min=0.0,
      max=100.0,
      step=1.0,
      large_step=10.0,
      aria_label="Volume",
      aria_valuetext_fn=fn(v) { v.to_string() + "%" },
      [@luna.text_dyn(fn() { value.get().to_string() })],
    ),
    p([@luna.text_dyn(fn() { "Value: " + value.get().to_string() })]),
    div([
      btn(
        @luna.handler(fn(_) {
          let v = value.get() - 10.0
          value.set(if v < 0.0 { 0.0 } else { v })
        }),
        [@luna.text("-10")],
      ),
      btn(
        @luna.handler(fn(_) {
          let v = value.get() + 10.0
          value.set(if v > 100.0 { 100.0 } else { v })
        }),
        [@luna.text("+10")],
      ),
    ]),
  ])
}

// =============================================================================
// Dialog Demo
// =============================================================================

///|
fn dialog_demo() -> @luna.Node[@js.Any] {
  let open = @signal.signal(false)
  div([
    h2([@luna.text("Dialog")]),
    p([@luna.text("Modal dialog example")]),
    btn(@luna.handler(fn(_) { open.set(true) }), [@luna.text("Open Dialog")]),
    @apg.dialog_dyn(
      aria_label="Example Dialog",
      open,
      [
        @luna.h("h3", [], [@luna.text("Dialog Title")]),
        @luna.h("p", [], [@luna.text("This is a modal dialog.")]),
        @apg.button(
          on_click=@luna.handler(fn(_) { open.set(false) }),
          [@luna.text("Close")],
        ),
      ],
    ),
  ])
}

// =============================================================================
// Disclosure Demo
// =============================================================================

///|
fn disclosure_demo() -> @luna.Node[@js.Any] {
  let expanded = @signal.signal(false)
  div([
    h2([@luna.text("Disclosure")]),
    p([@luna.text("Show/hide content toggle")]),
    // Using the simplified disclosure_dyn API
    @apg.disclosure_dyn(
      "demo-disclosure",
      expanded,
      [
        @luna.text_dyn(fn() {
          if expanded.get() { "Hide Details" } else { "Show Details" }
        }),
      ],
      [
        @luna.h("p", [], [
          @luna.text("This is the hidden content that appears when expanded."),
        ]),
      ],
    ),
  ])
}

// =============================================================================
// Breadcrumb Demo
// =============================================================================

///|
fn breadcrumb_demo() -> @luna.Node[@js.Any] {
  let items : Array[@apg.BreadcrumbItem] = [
    @apg.breadcrumb_item("/", "Home"),
    @apg.breadcrumb_item("/products", "Products"),
    @apg.breadcrumb_item("/products/electronics", "Electronics"),
    @apg.breadcrumb_item("#", "Laptops", current=true),
  ]
  div([
    h2([@luna.text("Breadcrumb")]),
    p([@luna.text("Navigation trail")]),
    @apg.breadcrumb(items),
  ])
}

// =============================================================================
// Listbox Demo
// =============================================================================

///|
fn listbox_demo() -> @luna.Node[@js.Any] {
  let selected = @signal.signal("apple")
  div([
    h2([@luna.text("Listbox")]),
    p([@luna.text("Selection list")]),
    @apg.listbox(
      aria_label="Choose a fruit",
      [
        listbox_option(selected, "apple", "Apple"),
        listbox_option(selected, "banana", "Banana"),
        listbox_option(selected, "cherry", "Cherry"),
        listbox_option(selected, "date", "Date"),
      ],
    ),
    p([@luna.text_dyn(fn() { "Selected: " + selected.get() })]),
  ])
}

///|
fn listbox_option(
  selected : @signal.Signal[String],
  value : String,
  label : String
) -> @luna.Node[@js.Any] {
  let attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("role", @luna.attr_static("option")),
    (
      "aria-selected",
      @luna.attr_dynamic(fn() {
        if selected.get() == value { "true" } else { "false" }
      }),
    ),
    ("data-value", @luna.attr_static(value)),
    ("click", @luna.attr_handler(@luna.handler(fn(_) { selected.set(value) }))),
  ]
  @luna.h("div", attrs, [@luna.text(label)])
}

// =============================================================================
// Main Application
// =============================================================================

///|
fn app() -> @luna.Node[@js.Any] {
  div([
    h1([@luna.text("APG Components Playground")]),
    p([@luna.text("WAI-ARIA Authoring Practices Guide compliant components")]),
    button_demo(),
    hr(),
    checkbox_demo(),
    hr(),
    switch_demo(),
    hr(),
    radio_demo(),
    hr(),
    tabs_demo(),
    hr(),
    accordion_demo(),
    hr(),
    slider_demo(),
    hr(),
    dialog_demo(),
    hr(),
    disclosure_demo(),
    hr(),
    breadcrumb_demo(),
    hr(),
    listbox_demo(),
  ])
}

///|
fn main {
  let doc = @dom.document()
  match doc.getElementById("app") {
    Some(el) => @client.render_vnode(el, app())
    None => println("Error: #app element not found")
  }
}
