///|
/// APG Components Playground
///
/// Interactive demos for WAI-ARIA APG compliant components

// =============================================================================
// Helper elements
// =============================================================================

///|
fn div(children : Array[@luna.Node[@js.Any]]) -> @luna.Node[@js.Any] {
  @luna.h("div", [], children)
}

///|
fn div_class(
  class : String,
  children : Array[@luna.Node[@js.Any]],
) -> @luna.Node[@js.Any] {
  @luna.h("div", [("class", @luna.attr_static(class))], children)
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
fn p_class(
  class : String,
  children : Array[@luna.Node[@js.Any]],
) -> @luna.Node[@js.Any] {
  @luna.h("p", [("class", @luna.attr_static(class))], children)
}

///|
fn span(children : Array[@luna.Node[@js.Any]]) -> @luna.Node[@js.Any] {
  @luna.h("span", [], children)
}

///|
fn pre(children : Array[@luna.Node[@js.Any]]) -> @luna.Node[@js.Any] {
  @luna.h("pre", [], children)
}

///|
fn code_block(text : String) -> @luna.Node[@js.Any] {
  @luna.h("code", [], [@luna.text(text)])
}

///|
fn btn(
  on_click : @luna.EventHandler[@js.Any],
  children : Array[@luna.Node[@js.Any]],
) -> @luna.Node[@js.Any] {
  @luna.h("button", [("click", @luna.attr_handler(on_click))], children)
}

// =============================================================================
// Section identifiers
// =============================================================================

///|
pub(all) enum Section {
  // Input Components
  Button
  Checkbox
  Switch
  Radio
  Slider
  Spinbutton
  // Selection Components
  Listbox
  Combobox
  // Navigation Components
  Tabs
  Accordion
  Breadcrumb
  TreeView
  Toolbar
  MenuButton
  // Overlay Components
  Dialog
  AlertDialog
  Disclosure
  Tooltip
  // Status Components
  Alert
  Meter
  // Structure Components
  Link
  Landmarks
  Table
} derive(Eq, Show)

///|
fn section_name(section : Section) -> String {
  match section {
    Button => "Button"
    Checkbox => "Checkbox"
    Switch => "Switch"
    Radio => "Radio Group"
    Slider => "Slider"
    Spinbutton => "Spinbutton"
    Listbox => "Listbox"
    Combobox => "Combobox"
    Tabs => "Tabs"
    Accordion => "Accordion"
    Breadcrumb => "Breadcrumb"
    TreeView => "Tree View"
    Toolbar => "Toolbar"
    MenuButton => "Menu Button"
    Dialog => "Dialog"
    AlertDialog => "Alert Dialog"
    Disclosure => "Disclosure"
    Tooltip => "Tooltip"
    Alert => "Alert"
    Meter => "Meter"
    Link => "Link"
    Landmarks => "Landmarks"
    Table => "Table"
  }
}

///|
fn section_id(section : Section) -> String {
  match section {
    Button => "button"
    Checkbox => "checkbox"
    Switch => "switch"
    Radio => "radio"
    Slider => "slider"
    Spinbutton => "spinbutton"
    Listbox => "listbox"
    Combobox => "combobox"
    Tabs => "tabs"
    Accordion => "accordion"
    Breadcrumb => "breadcrumb"
    TreeView => "treeview"
    Toolbar => "toolbar"
    MenuButton => "menu-button"
    Dialog => "dialog"
    AlertDialog => "alert-dialog"
    Disclosure => "disclosure"
    Tooltip => "tooltip"
    Alert => "alert"
    Meter => "meter"
    Link => "link"
    Landmarks => "landmarks"
    Table => "table"
  }
}

///|
fn all_sections() -> Array[Section] {
  [
    Button, Checkbox, Switch, Radio, Slider, Spinbutton,
    Listbox, Combobox,
    Tabs, Accordion, Breadcrumb, TreeView, Toolbar, MenuButton,
    Dialog, AlertDialog, Disclosure, Tooltip,
    Alert, Meter,
    Link, Landmarks, Table,
  ]
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
        @luna.text_dyn(fn() { " (pressed: " + pressed.get().to_string() + ")" }),
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
    @apg.radiogroup(aria_label="Choose an option", [
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
    ]),
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
    p([
      @luna.text(
        "Tabbed interface with keyboard navigation (use ←/→ arrows)",
      ),
    ]),
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
    p([
      @luna.text(
        "Accessible range input (use ←/→/↑/↓, Home/End, PageUp/PageDown)",
      ),
    ]),
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
    @apg.dialog_dyn(aria_label="Example Dialog", open, [
      @luna.h("h3", [], [@luna.text("Dialog Title")]),
      @luna.h("p", [], [@luna.text("This is a modal dialog.")]),
      @apg.button(on_click=@luna.handler(fn(_) { open.set(false) }), [
        @luna.text("Close"),
      ]),
    ]),
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
          if expanded.get() {
            "Hide Details"
          } else {
            "Show Details"
          }
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
    @apg.listbox(aria_label="Choose a fruit", [
      listbox_option(selected, "apple", "Apple"),
      listbox_option(selected, "banana", "Banana"),
      listbox_option(selected, "cherry", "Cherry"),
      listbox_option(selected, "date", "Date"),
    ]),
    p([@luna.text_dyn(fn() { "Selected: " + selected.get() })]),
  ])
}

///|
fn listbox_option(
  selected : @signal.Signal[String],
  value : String,
  label : String,
) -> @luna.Node[@js.Any] {
  let attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("role", @luna.attr_static("option")),
    (
      "aria-selected",
      @luna.attr_dynamic(fn() {
        if selected.get() == value {
          "true"
        } else {
          "false"
        }
      }),
    ),
    ("data-value", @luna.attr_static(value)),
    ("click", @luna.attr_handler(@luna.handler(fn(_) { selected.set(value) }))),
  ]
  @luna.h("div", attrs, [@luna.text(label)])
}

// =============================================================================
// Spinbutton Demo
// =============================================================================

///|
fn spinbutton_demo() -> @luna.Node[@js.Any] {
  let value = @signal.signal(5.0)
  div([
    h2([@luna.text("Spinbutton")]),
    p([@luna.text("Number input with keyboard support (↑/↓, Home/End, PageUp/PageDown)")]),
    @apg.spinbutton_interactive(
      value,
      min=0.0,
      max=100.0,
      step=1.0,
      large_step=10.0,
      aria_label="Quantity",
      aria_valuetext_fn=fn(v) { v.to_string() + " items" },
    ),
    p([@luna.text_dyn(fn() { "Value: " + value.get().to_string() })]),
  ])
}

// =============================================================================
// Combobox Demo
// =============================================================================

///|
fn combobox_demo() -> @luna.Node[@js.Any] {
  let selected_fruit = @signal.signal("")
  let options = [
    @apg.combobox_option("apple", "Apple"),
    @apg.combobox_option("banana", "Banana"),
    @apg.combobox_option("cherry", "Cherry"),
    @apg.combobox_option("date", "Date"),
    @apg.combobox_option("elderberry", "Elderberry"),
    @apg.combobox_option("fig", "Fig"),
    @apg.combobox_option("grape", "Grape"),
  ]
  div([
    h2([@luna.text("Combobox")]),
    p([@luna.text("Text input with autocomplete dropdown (↑/↓, Enter, Escape)")]),
    @apg.combobox_interactive(
      "fruit-combo",
      options,
      placeholder="Search fruits...",
      aria_label="Select a fruit",
      fn(opt) { selected_fruit.set(opt.label) },
    ),
    p([@luna.text_dyn(fn() { "Selected: " + selected_fruit.get() })]),
  ])
}

// =============================================================================
// Tree View Demo
// =============================================================================

///|
fn treeview_demo() -> @luna.Node[@js.Any] {
  let selected_node = @signal.signal("")
  let nodes = [
    @apg.tree_node(
      "documents",
      "Documents",
      children=[
        @apg.tree_node("work", "Work", children=[
          @apg.tree_node("report", "Annual Report"),
          @apg.tree_node("budget", "Budget 2024"),
        ]),
        @apg.tree_node("personal", "Personal", children=[
          @apg.tree_node("photos", "Photos"),
          @apg.tree_node("notes", "Notes"),
        ]),
      ],
    ),
    @apg.tree_node(
      "downloads",
      "Downloads",
      children=[
        @apg.tree_node("file1", "file1.zip"),
        @apg.tree_node("file2", "file2.pdf"),
      ],
    ),
  ]
  div([
    h2([@luna.text("Tree View")]),
    p([@luna.text("Hierarchical list (↑/↓/←/→ arrows, Home/End, Enter/Space)")]),
    @apg.tree_interactive("file-tree", nodes, aria_label="File browser", fn(id) {
      selected_node.set(id)
    }),
    p([@luna.text_dyn(fn() { "Selected: " + selected_node.get() })]),
  ])
}

// =============================================================================
// Toolbar Demo
// =============================================================================

///|
fn toolbar_demo() -> @luna.Node[@js.Any] {
  let pressed_states : @signal.Signal[Map[String, Bool]] = @signal.signal({  })
  let items = [
    @apg.toolbar_item_def("bold", "Bold", toggle=true),
    @apg.toolbar_item_def("italic", "Italic", toggle=true),
    @apg.toolbar_item_def("underline", "Underline", toggle=true),
    @apg.toolbar_item_def("cut", "Cut"),
    @apg.toolbar_item_def("copy", "Copy"),
    @apg.toolbar_item_def("paste", "Paste"),
  ]
  div([
    h2([@luna.text("Toolbar")]),
    p([@luna.text("Button group with keyboard navigation (←/→ arrows)")]),
    @apg.toolbar_interactive(
      "editor-toolbar",
      items,
      pressed_states,
      aria_label="Text formatting",
      fn(id, is_toggle) {
        if is_toggle {
          let states = pressed_states.get()
          let new_states = states.copy()
          let current = states.get(id).unwrap_or(false)
          new_states.set(id, not(current))
          pressed_states.set(new_states)
        }
      },
    ),
  ])
}

// =============================================================================
// Menu Button Demo
// =============================================================================

///|
fn menu_button_demo() -> @luna.Node[@js.Any] {
  let selected_action = @signal.signal("")
  let items = [
    @apg.menu_item("new", "New File"),
    @apg.menu_item("open", "Open..."),
    @apg.menu_item("save", "Save"),
    @apg.menu_item("save-as", "Save As..."),
    @apg.menu_item("export", "Export", disabled=true),
  ]
  div([
    h2([@luna.text("Menu Button")]),
    p([@luna.text("Button that opens a menu dropdown (↑/↓, Enter/Space, Escape)")]),
    @apg.menu_button_interactive("file-menu", items, fn(id) {
      selected_action.set(id)
    }, [@luna.text("File ▾")]),
    p([@luna.text_dyn(fn() { "Last action: " + selected_action.get() })]),
  ])
}

// =============================================================================
// Alert Dialog Demo
// =============================================================================

///|
fn alert_dialog_demo() -> @luna.Node[@js.Any] {
  let open = @signal.signal(false)
  let result = @signal.signal("")
  div([
    h2([@luna.text("Alert Dialog")]),
    p([@luna.text("Confirmation dialog with required user action")]),
    btn(@luna.handler(fn(_) { open.set(true) }), [@luna.text("Delete Item")]),
    @apg.confirm_dialog(
      "confirm-delete",
      "Confirm Delete",
      "Are you sure you want to delete this item? This action cannot be undone.",
      confirm_label="Delete",
      cancel_label="Cancel",
      open,
      fn() { result.set("Confirmed") },
      fn() { result.set("Cancelled") },
    ),
    p([@luna.text_dyn(fn() { "Result: " + result.get() })]),
  ])
}

// =============================================================================
// Tooltip Demo
// =============================================================================

///|
fn tooltip_demo() -> @luna.Node[@js.Any] {
  let visible = @signal.signal(false)
  div([
    h2([@luna.text("Tooltip")]),
    p([@luna.text("Informational popup on hover/focus")]),
    @luna.h(
      "span",
      [
        ("mouseenter", @luna.attr_handler(@luna.handler(fn(_) { visible.set(true) }))),
        ("mouseleave", @luna.attr_handler(@luna.handler(fn(_) { visible.set(false) }))),
        ("focus", @luna.attr_handler(@luna.handler(fn(_) { visible.set(true) }))),
        ("blur", @luna.attr_handler(@luna.handler(fn(_) { visible.set(false) }))),
      ],
      [
        @apg.tooltip_trigger("demo-tooltip", [@luna.text("Hover me")]),
        @apg.tooltip_dyn("demo-tooltip", visible, [
          @luna.text("This is helpful tooltip text"),
        ]),
      ],
    ),
  ])
}

// =============================================================================
// Alert Demo
// =============================================================================

///|
fn alert_demo() -> @luna.Node[@js.Any] {
  div([
    h2([@luna.text("Alert")]),
    p([@luna.text("Live region for important messages")]),
    @apg.alert(type_=@apg.Error, [@luna.text("Error: Something went wrong!")]),
    @apg.alert(type_=@apg.Warning, [@luna.text("Warning: Please check your input.")]),
    @apg.alert(type_=@apg.Success, [@luna.text("Success: Your changes have been saved.")]),
    @apg.status([@luna.text("Status: Processing your request...")]),
  ])
}

// =============================================================================
// Meter Demo
// =============================================================================

///|
fn meter_demo() -> @luna.Node[@js.Any] {
  let value = @signal.signal(65.0)
  div([
    h2([@luna.text("Meter")]),
    p([@luna.text("Visual representation of a value within a known range")]),
    @apg.meter_dyn(
      value,
      min=0.0,
      max=100.0,
      aria_label="Disk usage",
      aria_valuetext_fn=fn(v) { v.to_string() + "% used" },
      [],
    ),
    p([@luna.text_dyn(fn() { "Value: " + value.get().to_string() + "%" })]),
    div([
      btn(@luna.handler(fn(_) { value.set(value.get() - 10.0) }), [@luna.text("-10")]),
      btn(@luna.handler(fn(_) { value.set(value.get() + 10.0) }), [@luna.text("+10")]),
    ]),
  ])
}

// =============================================================================
// Link Demo
// =============================================================================

///|
fn link_demo() -> @luna.Node[@js.Any] {
  div([
    h2([@luna.text("Link")]),
    p([@luna.text("Accessible hyperlinks")]),
    @apg.link("https://www.w3.org/WAI/ARIA/apg/", [@luna.text("WAI-ARIA APG")]),
    @luna.text(" | "),
    @apg.link(
      "https://moonbitlang.com",
      target=@apg.Blank,
      [@luna.text("MoonBit (opens in new tab)")],
    ),
    @luna.text(" | "),
    @apg.link("#", disabled=true, [@luna.text("Disabled Link")]),
  ])
}

// =============================================================================
// Landmarks Demo
// =============================================================================

///|
fn landmarks_demo() -> @luna.Node[@js.Any] {
  div([
    h2([@luna.text("Landmarks")]),
    p([@luna.text("ARIA landmark roles for page structure")]),
    div_class("landmarks-example", [
      @apg.main_content([@luna.h("p", [], [@luna.text("Main content area (role=main)")])]),
      @apg.region(
        aria_label="Example Section",
        [@luna.h("p", [], [@luna.text("A named region")])],
      ),
      @apg.aside(
        aria_label="Related Info",
        [@luna.h("p", [], [@luna.text("Complementary content (aside)")])],
      ),
    ]),
  ])
}

// =============================================================================
// Table Demo
// =============================================================================

///|
fn table_demo() -> @luna.Node[@js.Any] {
  let columns = [
    @apg.table_column("name", "Name", sortable=true),
    @apg.table_column("role", "Role", sortable=true),
    @apg.table_column("email", "Email"),
  ]
  let rows = [
    @apg.table_row("1", ["Alice", "Developer", "alice@example.com"]),
    @apg.table_row("2", ["Bob", "Designer", "bob@example.com"]),
    @apg.table_row("3", ["Charlie", "Manager", "charlie@example.com"]),
    @apg.table_row("4", ["Diana", "QA Engineer", "diana@example.com"]),
  ]
  div([
    h2([@luna.text("Table")]),
    p([@luna.text("Data table with sortable columns and keyboard navigation")]),
    @apg.table_interactive(
      "team-table",
      columns,
      rows,
      aria_label="Team members",
      selectable=true,
      on_row_select=fn(id) {
        let console = @js.global_this()._get("console")
        console._call("log", [@js.any("Selected row: " + id)]) |> ignore
      },
    ),
  ])
}

// =============================================================================
// Theme Controls
// =============================================================================

///|
/// Theme mode
pub(all) enum ThemeMode {
  System
  Light
  Dark
}

///|
fn log(msg : String) -> Unit {
  let console = @js.global_this()._get("console")
  console._call("log", [@js.any(msg)]) |> ignore
}

///|
fn set_theme(mode : ThemeMode) -> Unit {
  let doc = @js.global_this()._get("document")
  let root = doc._get("documentElement")
  match mode {
    System => {
      log("Setting theme: system")
      let _ = root._call("removeAttribute", [@js.any("data-theme")])
    }
    Light => {
      log("Setting theme: light")
      let _ = root._call("setAttribute", [@js.any("data-theme"), @js.any("light")])
    }
    Dark => {
      log("Setting theme: dark")
      let _ = root._call("setAttribute", [@js.any("data-theme"), @js.any("dark")])
    }
  }
}

///|
fn set_accent(color : String) -> Unit {
  log("Setting accent: " + color)
  let doc = @js.global_this()._get("document")
  let root = doc._get("documentElement")
  let _ = root._call("setAttribute", [@js.any("data-accent"), @js.any(color)])
}

///|
fn theme_btn(
  label : String,
  icon : String,
  is_active : () -> Bool,
  on_click : @luna.EventHandler[@js.Any],
) -> @luna.Node[@js.Any] {
  @luna.h(
    "button",
    [
      ("class", @luna.attr_static("theme-toggle")),
      (
        "aria-pressed",
        @luna.attr_dynamic(fn() { if is_active() { "true" } else { "false" } }),
      ),
      ("click", @luna.attr_handler(on_click)),
    ],
    [
      @luna.h(
        "span",
        [("class", @luna.attr_static("theme-toggle-icon"))],
        [@luna.text(icon)],
      ),
      @luna.text(label),
    ],
  )
}

///|
fn color_swatch_btn(
  color : String,
  is_active : () -> Bool,
  on_click : @luna.EventHandler[@js.Any],
) -> @luna.Node[@js.Any] {
  @luna.h(
    "button",
    [
      ("class", @luna.attr_static("color-swatch")),
      ("data-color", @luna.attr_static(color)),
      (
        "aria-pressed",
        @luna.attr_dynamic(fn() { if is_active() { "true" } else { "false" } }),
      ),
      ("aria-label", @luna.attr_static(color + " accent color")),
      ("click", @luna.attr_handler(on_click)),
    ],
    [],
  )
}

///|
fn theme_controls(
  theme : @signal.Signal[ThemeMode],
  accent : @signal.Signal[String],
) -> @luna.Node[@js.Any] {
  let colors = ["amber", "blue", "green", "purple", "rose", "teal"]
  let color_swatches : Array[@luna.Node[@js.Any]] = []
  for color in colors {
    let c = color
    color_swatches.push(
      color_swatch_btn(
        c,
        fn() { accent.get() == c },
        @luna.handler(fn(_) {
          accent.set(c)
          set_accent(c)
        }),
      ),
    )
  }
  @luna.h(
    "div",
    [("class", @luna.attr_static("theme-controls"))],
    [
      @luna.h(
        "span",
        [("class", @luna.attr_static("theme-controls-label"))],
        [@luna.text("Theme")],
      ),
      theme_btn(
        "Light",
        "\u{2600}",
        fn() {
          match theme.get() {
            Light => true
            _ => false
          }
        },
        @luna.handler(fn(_) {
          theme.set(Light)
          set_theme(Light)
        }),
      ),
      theme_btn(
        "Dark",
        "\u{1F319}",
        fn() {
          match theme.get() {
            Dark => true
            _ => false
          }
        },
        @luna.handler(fn(_) {
          theme.set(Dark)
          set_theme(Dark)
        }),
      ),
      theme_btn(
        "System",
        "\u{1F4BB}",
        fn() {
          match theme.get() {
            System => true
            _ => false
          }
        },
        @luna.handler(fn(_) {
          theme.set(System)
          set_theme(System)
        }),
      ),
      @luna.h(
        "span",
        [("class", @luna.attr_static("theme-controls-label"))],
        [@luna.text("Accent")],
      ),
      @luna.h(
        "div",
        [("class", @luna.attr_static("color-swatches"))],
        color_swatches,
      ),
    ],
  )
}

// =============================================================================
// Demo Section with Code Display
// =============================================================================

///|
fn demo_section(
  id : String,
  title : String,
  description : String,
  code : String,
  show_code : @signal.Signal[Bool],
  preview : @luna.Node[@js.Any],
) -> @luna.Node[@js.Any] {
  @luna.h(
    "section",
    [
      ("class", @luna.attr_static("demo-section")),
      ("id", @luna.attr_static(id)),
    ],
    [
      @luna.h("h2", [], [
        @luna.text(title),
        @luna.h(
          "a",
          [("href", @luna.attr_static("#" + id)), ("aria-label", @luna.attr_static("Link to " + title))],
          [@luna.text("#")],
        ),
      ]),
      p_class("demo-description", [@luna.text(description)]),
      div_class("demo-preview", [preview]),
      div_class("demo-code", [
        div_class("demo-code-header", [
          @luna.h(
            "span",
            [("class", @luna.attr_static("demo-code-title"))],
            [@luna.text("MoonBit Code")],
          ),
          @luna.h(
            "button",
            [
              ("class", @luna.attr_static("demo-code-toggle")),
              ("click", @luna.attr_handler(@luna.handler(fn(_) {
                show_code.set(not(show_code.get()))
              }))),
            ],
            [@luna.text_dyn(fn() {
              if show_code.get() { "Hide Code" } else { "Show Code" }
            })],
          ),
        ]),
        @luna.show(
          fn() { show_code.get() },
          fn() { pre([code_block(code)]) },
        ),
      ]),
    ],
  )
}

// =============================================================================
// Sidebar
// =============================================================================

///|
fn sidebar_nav_item(
  section : Section,
  current : @signal.Signal[Section],
) -> @luna.Node[@js.Any] {
  let s = section
  @luna.h(
    "li",
    [],
    [
      @luna.h(
        "button",
        [
          (
            "aria-current",
            @luna.attr_dynamic(fn() {
              if current.get() == s { "true" } else { "false" }
            }),
          ),
          ("click", @luna.attr_handler(@luna.handler(fn(_) {
            current.set(s)
            // Scroll to section
            let doc = @js.global_this()._get("document")
            let el = doc._call("getElementById", [@js.any(section_id(s))])
            let _ = el._call("scrollIntoView", [@js.any({ "behavior": "smooth" })])
          }))),
        ],
        [@luna.text(section_name(s))],
      ),
    ],
  )
}

///|
fn sidebar(
  current_section : @signal.Signal[Section],
  theme : @signal.Signal[ThemeMode],
  accent : @signal.Signal[String],
) -> @luna.Node[@js.Any] {
  let sections = all_sections()
  let nav_items : Array[@luna.Node[@js.Any]] = []
  for s in sections {
    nav_items.push(sidebar_nav_item(s, current_section))
  }
  @luna.h(
    "aside",
    [("class", @luna.attr_static("sidebar"))],
    [
      @luna.h("h1", [("class", @luna.attr_static("sidebar-title"))], [
        @luna.text("Component Catalog"),
      ]),
      @luna.h("p", [("class", @luna.attr_static("sidebar-subtitle"))], [
        @luna.text("WAI-ARIA APG Patterns"),
      ]),
      @luna.h("ul", [("class", @luna.attr_static("sidebar-nav"))], nav_items),
      theme_controls(theme, accent),
      @luna.h("a", [("href", @luna.attr_static("../")), ("class", @luna.attr_static("back-link"))], [
        @luna.text("\u{2190} Back to Demos"),
      ]),
    ],
  )
}

// =============================================================================
// Main Content
// =============================================================================

///|
fn main_content(current_section : @signal.Signal[Section]) -> @luna.Node[@js.Any] {
  // Code show/hide signals for each section
  let show_button_code = @signal.signal(false)
  let show_checkbox_code = @signal.signal(false)
  let show_switch_code = @signal.signal(false)
  let show_radio_code = @signal.signal(false)
  let show_slider_code = @signal.signal(false)
  let show_spinbutton_code = @signal.signal(false)
  let show_listbox_code = @signal.signal(false)
  let show_combobox_code = @signal.signal(false)
  let show_tabs_code = @signal.signal(false)
  let show_accordion_code = @signal.signal(false)
  let show_breadcrumb_code = @signal.signal(false)
  let show_treeview_code = @signal.signal(false)
  let show_toolbar_code = @signal.signal(false)
  let show_menu_button_code = @signal.signal(false)
  let show_dialog_code = @signal.signal(false)
  let show_alert_dialog_code = @signal.signal(false)
  let show_disclosure_code = @signal.signal(false)
  let show_tooltip_code = @signal.signal(false)
  let show_alert_code = @signal.signal(false)
  let show_meter_code = @signal.signal(false)
  let show_link_code = @signal.signal(false)
  let show_landmarks_code = @signal.signal(false)
  let show_table_code = @signal.signal(false)
  let _ = current_section // Future: could filter to show only current section
  @luna.h(
    "main",
    [("class", @luna.attr_static("main-content"))],
    [
      div_class("main-header", [
        h1([@luna.text("APG Components Playground")]),
        p([@luna.text("Interactive demos for WAI-ARIA Authoring Practices Guide compliant components")]),
      ]),
      demo_section(
        "button",
        "Button",
        "A button is a widget that enables users to trigger an action or event, such as submitting a form or opening a dialog.",
        (
          #|let pressed = @signal.signal(false)
          #|@apg.button([@luna.text("Click me")])
          #|@apg.button(disabled=true, [@luna.text("Disabled")])
          #|@apg.toggle_button_dyn(
          #|  pressed,
          #|  on_click=@luna.handler(fn(_) { pressed.set(not(pressed.get())) }),
          #|  [@luna.text("Mute")],
          #|)
        ),
        show_button_code,
        button_demo(),
      ),
      demo_section(
        "checkbox",
        "Checkbox",
        "A checkbox is a widget that allows users to select one or more items from a set. Supports tri-state (mixed) for parent checkboxes.",
        (
          #|let checked = @signal.signal(@apg.Unchecked)
          #|@apg.checkbox_dyn(
          #|  checked,
          #|  on_click=@luna.handler(fn(_) {
          #|    let next = match checked.get() {
          #|      @apg.Unchecked => @apg.Checked
          #|      @apg.Checked => @apg.Unchecked
          #|      @apg.Mixed => @apg.Checked
          #|    }
          #|    checked.set(next)
          #|  }),
          #|  [@luna.text("I agree to the terms")],
          #|)
        ),
        show_checkbox_code,
        checkbox_demo(),
      ),
      demo_section(
        "switch",
        "Switch",
        "A switch is an input widget that allows users to choose one of two binary states: on or off.",
        (
          #|let on = @signal.signal(false)
          #|@apg.switch_dyn(
          #|  on,
          #|  aria_label="Enable notifications",
          #|  on_click=@luna.handler(fn(_) { on.set(not(on.get())) }),
          #|  [@luna.text("Notifications")],
          #|)
        ),
        show_switch_code,
        switch_demo(),
      ),
      demo_section(
        "radio",
        "Radio Group",
        "A radio group is a set of checkable buttons where only one can be checked at a time. Uses arrow keys for navigation.",
        (
          #|let selected = @signal.signal("option1")
          #|@apg.radiogroup(aria_label="Choose an option", [
          #|  @apg.radio_dyn("option1", selected,
          #|    on_click=@luna.handler(fn(_) { selected.set("option1") }),
          #|    [@luna.text("Option 1")]),
          #|  @apg.radio_dyn("option2", selected,
          #|    on_click=@luna.handler(fn(_) { selected.set("option2") }),
          #|    [@luna.text("Option 2")]),
          #|])
        ),
        show_radio_code,
        radio_demo(),
      ),
      demo_section(
        "tabs",
        "Tabs",
        "Tabs organize content into separate views that users can switch between. Arrow keys navigate between tabs.",
        (
          #|let active_tab = @signal.signal(0)
          #|let items = [
          #|  @apg.tab_item("0", "Tab 1", [@luna.text("Content for Tab 1")]),
          #|  @apg.tab_item("1", "Tab 2", [@luna.text("Content for Tab 2")]),
          #|  @apg.tab_item("2", "Tab 3", [@luna.text("Content for Tab 3")]),
          #|]
          #|@apg.tabs_interactive(items, active_tab, aria_label="Demo tabs")
        ),
        show_tabs_code,
        tabs_demo(),
      ),
      demo_section(
        "accordion",
        "Accordion",
        "An accordion is a vertically stacked set of interactive headings with associated content sections.",
        (
          #|let expanded = @signal.signal(-1)
          #|let items = [
          #|  @apg.accordion_item("0", "Section 1", [@luna.text("Content 1")]),
          #|  @apg.accordion_item("1", "Section 2", [@luna.text("Content 2")]),
          #|  @apg.accordion_item("2", "Section 3", [@luna.text("Content 3")]),
          #|]
          #|@apg.accordion_dyn(items, expanded)
        ),
        show_accordion_code,
        accordion_demo(),
      ),
      demo_section(
        "slider",
        "Slider",
        "A slider allows users to select a value within a given range. Supports keyboard (arrows, Home/End, PageUp/PageDown) and mouse drag.",
        (
          #|let value = @signal.signal(50.0)
          #|@apg.slider_interactive(
          #|  value,
          #|  min=0.0, max=100.0, step=1.0, large_step=10.0,
          #|  aria_label="Volume",
          #|  aria_valuetext_fn=fn(v) { v.to_string() + "%" },
          #|  [@luna.text_dyn(fn() { value.get().to_string() })],
          #|)
        ),
        show_slider_code,
        slider_demo(),
      ),
      demo_section(
        "dialog",
        "Dialog (Modal)",
        "A dialog is a window overlaid on the primary window. Focus is trapped inside the dialog until dismissed.",
        (
          #|let open = @signal.signal(false)
          #|btn(@luna.handler(fn(_) { open.set(true) }), [@luna.text("Open")])
          #|@apg.dialog_dyn(aria_label="Example Dialog", open, [
          #|  @luna.h("h3", [], [@luna.text("Dialog Title")]),
          #|  @luna.h("p", [], [@luna.text("This is a modal dialog.")]),
          #|  @apg.button(on_click=@luna.handler(fn(_) { open.set(false) }),
          #|    [@luna.text("Close")]),
          #|])
        ),
        show_dialog_code,
        dialog_demo(),
      ),
      demo_section(
        "disclosure",
        "Disclosure (Show/Hide)",
        "A disclosure widget shows and hides additional content. The button controls the visibility of a content section.",
        (
          #|let expanded = @signal.signal(false)
          #|@apg.disclosure_dyn(
          #|  "demo-disclosure",
          #|  expanded,
          #|  [@luna.text_dyn(fn() {
          #|    if expanded.get() { "Hide Details" } else { "Show Details" }
          #|  })],
          #|  [@luna.h("p", [], [@luna.text("Hidden content here.")])],
          #|)
        ),
        show_disclosure_code,
        disclosure_demo(),
      ),
      demo_section(
        "breadcrumb",
        "Breadcrumb",
        "A breadcrumb trail provides a visual representation of the user's location within a website hierarchy.",
        (
          #|let items = [
          #|  @apg.breadcrumb_item("/", "Home"),
          #|  @apg.breadcrumb_item("/products", "Products"),
          #|  @apg.breadcrumb_item("/products/electronics", "Electronics"),
          #|  @apg.breadcrumb_item("#", "Laptops", current=true),
          #|]
          #|@apg.breadcrumb(items)
        ),
        show_breadcrumb_code,
        breadcrumb_demo(),
      ),
      demo_section(
        "listbox",
        "Listbox",
        "A listbox presents a list of options and allows users to select one or more of them.",
        (
          #|let selected = @signal.signal("apple")
          #|@apg.listbox(aria_label="Choose a fruit", [
          #|  listbox_option(selected, "apple", "Apple"),
          #|  listbox_option(selected, "banana", "Banana"),
          #|  listbox_option(selected, "cherry", "Cherry"),
          #|])
        ),
        show_listbox_code,
        listbox_demo(),
      ),
      // New components
      demo_section(
        "spinbutton",
        "Spinbutton",
        "A spinbutton is an input widget for numeric values with increment/decrement buttons and keyboard support.",
        (
          #|let value = @signal.signal(5.0)
          #|@apg.spinbutton_interactive(value, min=0.0, max=100.0, step=1.0)
        ),
        show_spinbutton_code,
        spinbutton_demo(),
      ),
      demo_section(
        "combobox",
        "Combobox",
        "A combobox combines a text input with a listbox, allowing users to type to filter or select from options.",
        (
          #|let options = [
          #|  @apg.combobox_option("apple", "Apple"),
          #|  @apg.combobox_option("banana", "Banana"),
          #|]
          #|@apg.combobox_interactive("combo", options, fn(opt) { ... })
        ),
        show_combobox_code,
        combobox_demo(),
      ),
      demo_section(
        "treeview",
        "Tree View",
        "A tree view presents a hierarchical list that can be expanded and collapsed.",
        (
          #|let nodes = [
          #|  @apg.tree_node("folder", "Documents", children=[
          #|    @apg.tree_node("file1", "Report.pdf"),
          #|  ]),
          #|]
          #|@apg.tree_interactive("tree", nodes, fn(id) { ... })
        ),
        show_treeview_code,
        treeview_demo(),
      ),
      demo_section(
        "toolbar",
        "Toolbar",
        "A toolbar groups a set of controls like buttons and toggle buttons with keyboard navigation.",
        (
          #|let items = [
          #|  @apg.toolbar_item_def("bold", "Bold", toggle=true),
          #|  @apg.toolbar_item_def("copy", "Copy"),
          #|]
          #|@apg.toolbar_interactive("toolbar", items, pressed, fn(id, _) { ... })
        ),
        show_toolbar_code,
        toolbar_demo(),
      ),
      demo_section(
        "menu-button",
        "Menu Button",
        "A menu button opens a dropdown menu when activated, with keyboard navigation support.",
        (
          #|let items = [
          #|  @apg.menu_item("new", "New File"),
          #|  @apg.menu_item("save", "Save"),
          #|]
          #|@apg.menu_button_interactive("menu", items, fn(id) { ... }, [...])
        ),
        show_menu_button_code,
        menu_button_demo(),
      ),
      demo_section(
        "alert-dialog",
        "Alert Dialog",
        "An alert dialog interrupts the user's workflow to communicate an important message and require a response.",
        (
          #|let open = @signal.signal(false)
          #|@apg.confirm_dialog("dialog", "Title", "Message?", open,
          #|  fn() { /* confirm */ }, fn() { /* cancel */ })
        ),
        show_alert_dialog_code,
        alert_dialog_demo(),
      ),
      demo_section(
        "tooltip",
        "Tooltip",
        "A tooltip displays brief, informational content when a user hovers over or focuses on an element.",
        (
          #|let visible = @signal.signal(false)
          #|@apg.tooltip_trigger("tip-id", [@luna.text("Hover me")])
          #|@apg.tooltip_dyn("tip-id", visible, [@luna.text("Tip text")])
        ),
        show_tooltip_code,
        tooltip_demo(),
      ),
      demo_section(
        "alert",
        "Alert",
        "An alert displays an important message that attracts the user's attention without interrupting their task.",
        (
          #|@apg.alert(type_=@apg.Error, [@luna.text("Error message")])
          #|@apg.status([@luna.text("Status message")])
        ),
        show_alert_code,
        alert_demo(),
      ),
      demo_section(
        "meter",
        "Meter",
        "A meter displays a scalar measurement within a known range, such as disk usage or progress.",
        (
          #|let value = @signal.signal(65.0)
          #|@apg.meter_dyn(value, min=0.0, max=100.0, aria_label="Usage", [])
        ),
        show_meter_code,
        meter_demo(),
      ),
      demo_section(
        "link",
        "Link",
        "A link provides an accessible hyperlink using native anchor elements.",
        (
          #|@apg.link("https://example.com", [@luna.text("Example")])
          #|@apg.link("url", target=@apg.Blank, [@luna.text("New tab")])
        ),
        show_link_code,
        link_demo(),
      ),
      demo_section(
        "landmarks",
        "Landmarks",
        "Landmarks identify major sections of a page for assistive technology navigation.",
        (
          #|@apg.main_content([...])
          #|@apg.region(aria_label="Section", [...])
          #|@apg.aside(aria_label="Sidebar", [...])
        ),
        show_landmarks_code,
        landmarks_demo(),
      ),
      demo_section(
        "table",
        "Table",
        "A data table with sortable columns, selectable rows, and keyboard navigation.",
        (
          #|let columns = [@apg.table_column("name", "Name", sortable=true)]
          #|let rows = [@apg.table_row("1", ["Alice"])]
          #|@apg.table_interactive("table", columns, rows, selectable=true)
        ),
        show_table_code,
        table_demo(),
      ),
    ],
  )
}

// =============================================================================
// Main Application
// =============================================================================

///|
fn app() -> @luna.Node[@js.Any] {
  let theme = @signal.signal(System)
  let accent = @signal.signal("amber")
  let current_section = @signal.signal(Button)
  @luna.fragment([
    sidebar(current_section, theme, accent),
    main_content(current_section),
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
