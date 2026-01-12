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
// Checkbox Demo (Styled)
// =============================================================================

///|
fn checkbox_demo() -> @luna.Node[@js.Any] {
  let terms = @signal.signal(true)
  let newsletter = @signal.signal(false)
  let select_all = @signal.signal(false) // Will be shown as indeterminate
  div([
    h2([@luna.text("Checkbox")]),
    p([@luna.text("Accessible checkbox with native input and custom styling")]),
    @checkbox.checkbox_group(aria_label="Agreement options", [
      @checkbox.checkbox(terms, [@luna.text("I agree to the terms and conditions")]),
      @checkbox.checkbox(newsletter, [@luna.text("Subscribe to newsletter")]),
      @checkbox.checkbox(
        select_all,
        indeterminate=true,
        [@luna.text("Select all items")],
      ),
      @checkbox.checkbox(
        @signal.signal(false),
        disabled=true,
        [@luna.text("Unavailable option (disabled)")],
      ),
    ]),
  ])
}

// =============================================================================
// Switch Demo (Styled)
// =============================================================================

///|
fn switch_demo() -> @luna.Node[@js.Any] {
  let wifi = @signal.signal(false)
  let bluetooth = @signal.signal(true)
  @switch.switch_group(aria_label="Settings", [
    @switch.switch(wifi, aria_label="Wi-Fi", [@luna.text("Wi-Fi")]),
    @switch.switch(bluetooth, aria_label="Bluetooth", [@luna.text("Bluetooth")]),
    @switch.switch_static(
      false,
      disabled=true,
      aria_label="Airplane Mode",
      [@luna.text("Airplane Mode (disabled)")],
    ),
  ])
}

// =============================================================================
// Radio Group Demo (Styled)
// =============================================================================

///|
fn radio_demo() -> @luna.Node[@js.Any] {
  let selected = @signal.signal("option1")
  let items = [
    @radio.radio_item("option1", "Option 1"),
    @radio.radio_item("option2", "Option 2"),
    @radio.radio_item("option3", "Option 3"),
    @radio.radio_item("option4", "Disabled Option", disabled=true),
  ]
  div([
    h2([@luna.text("Radio Group")]),
    p([@luna.text("Select one option from the group")]),
    @radio.radio_group("demo-radio", items, selected, aria_label="Choose an option"),
    p([@luna.text_dyn(fn() { "Selected: " + selected.get() })]),
  ])
}

// =============================================================================
// Tabs Demo (Styled)
// =============================================================================

///|
fn tabs_demo() -> @luna.Node[@js.Any] {
  let active_tab = @signal.signal(0)
  let items : Array[@tabs.TabItem] = [
    @tabs.tab_item("0", "Tab 1", [@luna.text("Content for Tab 1")]),
    @tabs.tab_item("1", "Tab 2", [@luna.text("Content for Tab 2")]),
    @tabs.tab_item("2", "Tab 3", [@luna.text("Content for Tab 3")]),
  ]
  div([
    h2([@luna.text("Tabs")]),
    p([
      @luna.text(
        "Tabbed interface with keyboard navigation (use ←/→ arrows)",
      ),
    ]),
    @tabs.tabs(items, active_tab, aria_label="Demo tabs"),
  ])
}

// =============================================================================
// Accordion Demo (Styled)
// =============================================================================

///|
fn accordion_demo() -> @luna.Node[@js.Any] {
  let expanded = @signal.signal(-1) // -1 = all collapsed
  let items : Array[@accordion.AccordionItemData] = [
    @accordion.accordion_item("0", "Section 1", [@luna.text("Content for section 1")]),
    @accordion.accordion_item("1", "Section 2", [@luna.text("Content for section 2")]),
    @accordion.accordion_item("2", "Section 3", [@luna.text("Content for section 3")]),
  ]
  div([
    h2([@luna.text("Accordion")]),
    p([@luna.text("Expandable sections")]),
    @accordion.accordion(items, expanded),
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
// Spinbutton Demo (Styled)
// =============================================================================

///|
fn spinbutton_demo() -> @luna.Node[@js.Any] {
  let value = @signal.signal(5.0)
  div([
    h2([@luna.text("Spinbutton")]),
    p([@luna.text("Number input with keyboard support (↑/↓, Home/End, PageUp/PageDown)")]),
    @spinbutton.spinbutton(
      value,
      min=0.0,
      max=100.0,
      step=1.0,
      large_step=10.0,
      aria_label="Quantity",
      aria_valuetext_fn=fn(v) { v.to_string() + " items" },
      label="Quantity",
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
        ("class", @luna.attr_static("tooltip-wrapper")),
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

// =============================================================================
// Demo Section
// =============================================================================

///|
fn demo_section(
  id : String,
  title : String,
  description : String,
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
      // TODO: Add tabbed code display (MoonBit / TypeScript)
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
fn accent_controls(accent : @signal.Signal[String]) -> @luna.Node[@js.Any] {
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
    [("class", @luna.attr_static("accent-controls"))],
    [
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

///|
fn sidebar(
  current_section : @signal.Signal[Section],
  _is_dark : @signal.Signal[Bool],
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
      accent_controls(accent),
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
fn theme_switch(is_dark : @signal.Signal[Bool]) -> @luna.Node[@js.Any] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("theme-switch"))],
    [
      @luna.h(
        "span",
        [("class", @luna.attr_static("theme-switch-icon"))],
        [@luna.text("\u{2600}")], // ☀
      ),
      @switch.switch(
        is_dark,
        aria_label="Dark mode",
        [],
      ),
      @luna.h(
        "span",
        [("class", @luna.attr_static("theme-switch-icon"))],
        [@luna.text("\u{1F319}")], // 🌙
      ),
    ],
  )
}

///|
fn main_content(
  current_section : @signal.Signal[Section],
  is_dark : @signal.Signal[Bool],
) -> @luna.Node[@js.Any] {
  let _ = current_section // Future: could filter to show only current section
  @luna.h(
    "main",
    [("class", @luna.attr_static("main-content"))],
    [
      div_class("main-header", [
        @luna.h(
          "div",
          [("class", @luna.attr_static("main-header-top"))],
          [
            h1([@luna.text("APG Components Playground")]),
            theme_switch(is_dark),
          ],
        ),
        p([@luna.text("Interactive demos for WAI-ARIA Authoring Practices Guide compliant components")]),
      ]),
      demo_section(
        "button",
        "Button",
        "A button is a widget that enables users to trigger an action or event, such as submitting a form or opening a dialog.",
        button_demo(),
      ),
      demo_section(
        "checkbox",
        "Checkbox",
        "A checkbox is a widget that allows users to select one or more items from a set. Supports tri-state (mixed) for parent checkboxes.",
        checkbox_demo(),
      ),
      demo_section(
        "switch",
        "Switch",
        "A switch is an input widget that allows users to choose one of two binary states: on or off.",
        switch_demo(),
      ),
      demo_section(
        "radio",
        "Radio Group",
        "A radio group is a set of checkable buttons where only one can be checked at a time. Uses arrow keys for navigation.",
        radio_demo(),
      ),
      demo_section(
        "tabs",
        "Tabs",
        "Tabs organize content into separate views that users can switch between. Arrow keys navigate between tabs.",
        tabs_demo(),
      ),
      demo_section(
        "accordion",
        "Accordion",
        "An accordion is a vertically stacked set of interactive headings with associated content sections.",
        accordion_demo(),
      ),
      demo_section(
        "slider",
        "Slider",
        "A slider allows users to select a value within a given range. Supports keyboard (arrows, Home/End, PageUp/PageDown) and mouse drag.",
        slider_demo(),
      ),
      demo_section(
        "dialog",
        "Dialog (Modal)",
        "A dialog is a window overlaid on the primary window. Focus is trapped inside the dialog until dismissed.",
        dialog_demo(),
      ),
      demo_section(
        "disclosure",
        "Disclosure (Show/Hide)",
        "A disclosure widget shows and hides additional content. The button controls the visibility of a content section.",
        disclosure_demo(),
      ),
      demo_section(
        "breadcrumb",
        "Breadcrumb",
        "A breadcrumb trail provides a visual representation of the user's location within a website hierarchy.",
        breadcrumb_demo(),
      ),
      demo_section(
        "listbox",
        "Listbox",
        "A listbox presents a list of options and allows users to select one or more of them.",
        listbox_demo(),
      ),
      demo_section(
        "spinbutton",
        "Spinbutton",
        "A spinbutton is an input widget for numeric values with increment/decrement buttons and keyboard support.",
        spinbutton_demo(),
      ),
      demo_section(
        "combobox",
        "Combobox",
        "A combobox combines a text input with a listbox, allowing users to type to filter or select from options.",
        combobox_demo(),
      ),
      demo_section(
        "treeview",
        "Tree View",
        "A tree view presents a hierarchical list that can be expanded and collapsed.",
        treeview_demo(),
      ),
      demo_section(
        "toolbar",
        "Toolbar",
        "A toolbar groups a set of controls like buttons and toggle buttons with keyboard navigation.",
        toolbar_demo(),
      ),
      demo_section(
        "menu-button",
        "Menu Button",
        "A menu button opens a dropdown menu when activated, with keyboard navigation support.",
        menu_button_demo(),
      ),
      demo_section(
        "alert-dialog",
        "Alert Dialog",
        "An alert dialog interrupts the user's workflow to communicate an important message and require a response.",
        alert_dialog_demo(),
      ),
      demo_section(
        "tooltip",
        "Tooltip",
        "A tooltip displays brief, informational content when a user hovers over or focuses on an element.",
        tooltip_demo(),
      ),
      demo_section(
        "alert",
        "Alert",
        "An alert displays an important message that attracts the user's attention without interrupting their task.",
        alert_demo(),
      ),
      demo_section(
        "meter",
        "Meter",
        "A meter displays a scalar measurement within a known range, such as disk usage or progress.",
        meter_demo(),
      ),
      demo_section(
        "link",
        "Link",
        "A link provides an accessible hyperlink using native anchor elements.",
        link_demo(),
      ),
      demo_section(
        "landmarks",
        "Landmarks",
        "Landmarks identify major sections of a page for assistive technology navigation.",
        landmarks_demo(),
      ),
      demo_section(
        "table",
        "Table",
        "A data table with sortable columns, selectable rows, and keyboard navigation.",
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
  // Check system preference for initial dark mode
  let window = @js.global_this()
  let media_query = window._call("matchMedia", [@js.any("(prefers-color-scheme: dark)")])
  let prefers_dark : Bool = media_query._get("matches").cast()
  let is_dark = @signal.signal(prefers_dark)
  let accent = @signal.signal("amber")
  let current_section = @signal.signal(Button)
  // Set up effect to apply theme when is_dark changes
  let _ = @signal.render_effect(fn() {
    let dark = is_dark.get()
    if dark {
      set_theme(Dark)
    } else {
      set_theme(Light)
    }
  })
  @luna.fragment([
    sidebar(current_section, is_dark, accent),
    main_content(current_section, is_dark),
  ])
}

///|
fn apg_components_css() -> String {
  // CSS for APG headless components that don't have styled versions yet
  let css =
    #|/* =============================================================================
    #|   COMBOBOX COMPONENT STYLES
    #|   ============================================================================= */
    #|.combobox-container {
    #|  position: relative;
    #|  display: inline-block;
    #|  width: 100%;
    #|  max-width: 300px;
    #|}
    #|.combobox-input-wrapper {
    #|  position: relative;
    #|}
    #|.combobox-container [role="combobox"] {
    #|  display: block;
    #|  width: 100%;
    #|  padding: 0.5rem 2rem 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  border: 1px solid var(--border, #d1d5db);
    #|  border-radius: 0.375rem;
    #|  background: var(--background, white);
    #|  color: var(--foreground, inherit);
    #|}
    #|.combobox-container [role="combobox"]:focus {
    #|  outline: 2px solid var(--accent, #3b82f6);
    #|  outline-offset: 2px;
    #|}
    #|.combobox-container [role="combobox"][aria-expanded="true"] {
    #|  border-bottom-left-radius: 0;
    #|  border-bottom-right-radius: 0;
    #|}
    #|.combobox-caret {
    #|  position: absolute;
    #|  right: 0.75rem;
    #|  top: 50%;
    #|  transform: translateY(-50%);
    #|  pointer-events: none;
    #|  border-left: 4px solid transparent;
    #|  border-right: 4px solid transparent;
    #|  border-top: 5px solid var(--foreground, #374151);
    #|}
    #|.combobox-listbox {
    #|  position: absolute;
    #|  top: 100%;
    #|  left: 0;
    #|  right: 0;
    #|  z-index: 50;
    #|  max-height: 15rem;
    #|  overflow-y: auto;
    #|  margin: 0;
    #|  padding: 0.25rem 0;
    #|  list-style: none;
    #|  border: 1px solid var(--border, #d1d5db);
    #|  border-top: none;
    #|  border-bottom-left-radius: 0.375rem;
    #|  border-bottom-right-radius: 0.375rem;
    #|  background: var(--background, white);
    #|  box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1);
    #|}
    #|.combobox-listbox [role="option"] {
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  cursor: pointer;
    #|  list-style: none;
    #|}
    #|.combobox-listbox [role="option"]:hover {
    #|  background: var(--muted, #f3f4f6);
    #|}
    #|.combobox-listbox [role="option"][aria-selected="true"] {
    #|  background: var(--accent, #dbeafe);
    #|}
    #|
    #|/* =============================================================================
    #|   TREE VIEW COMPONENT STYLES
    #|   ============================================================================= */
    #|[role="tree"] {
    #|  list-style: none;
    #|  margin: 0;
    #|  padding: 0;
    #|  border: 1px solid var(--border, #d1d5db);
    #|  border-radius: 0.375rem;
    #|  background: var(--background, white);
    #|  min-width: 200px;
    #|  max-width: 400px;
    #|}
    #|[role="treeitem"] {
    #|  list-style: none;
    #|  padding: 0.5rem 0.75rem;
    #|  cursor: pointer;
    #|  border-bottom: 1px solid var(--border, #e5e7eb);
    #|}
    #|[role="treeitem"]:last-child {
    #|  border-bottom: none;
    #|}
    #|[role="treeitem"]:hover {
    #|  background: var(--muted, #f3f4f6);
    #|}
    #|[role="treeitem"]:focus {
    #|  outline: none;
    #|  box-shadow: inset 0 0 0 2px var(--accent, #3b82f6);
    #|}
    #|[role="treeitem"][aria-selected="true"] {
    #|  background: var(--accent, #dbeafe);
    #|}
    #|[role="treeitem"][aria-expanded]::before {
    #|  content: "▶";
    #|  display: inline-block;
    #|  margin-right: 0.5rem;
    #|  font-size: 0.625rem;
    #|  transition: transform 0.15s;
    #|}
    #|[role="treeitem"][aria-expanded="true"]::before {
    #|  transform: rotate(90deg);
    #|}
    #|[role="group"] {
    #|  list-style: none;
    #|  margin: 0;
    #|  padding: 0;
    #|  padding-left: 1.25rem;
    #|}
    #|[role="group"][hidden] {
    #|  display: none;
    #|}
    #|
    #|/* =============================================================================
    #|   MENU BUTTON COMPONENT STYLES
    #|   ============================================================================= */
    #|.menu-button-wrapper {
    #|  position: relative;
    #|  display: inline-block;
    #|}
    #|[role="menu"] {
    #|  position: absolute;
    #|  top: calc(100% + 0.25rem);
    #|  left: 0;
    #|  z-index: 50;
    #|  min-width: 160px;
    #|  max-height: 20rem;
    #|  overflow-y: auto;
    #|  margin: 0;
    #|  padding: 0.25rem 0;
    #|  list-style: none;
    #|  border: 1px solid var(--border, #d1d5db);
    #|  border-radius: 0.375rem;
    #|  background: var(--background, white);
    #|  box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1);
    #|}
    #|[role="menuitem"] {
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.875rem;
    #|  cursor: pointer;
    #|}
    #|[role="menuitem"]:hover {
    #|  background: var(--muted, #f3f4f6);
    #|}
    #|[role="menuitem"]:focus {
    #|  outline: 2px solid var(--accent, #3b82f6);
    #|  outline-offset: -2px;
    #|  background: var(--accent, #dbeafe);
    #|}
    #|[role="menuitem"][aria-disabled="true"] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|/* =============================================================================
    #|   TOOLTIP COMPONENT STYLES
    #|   ============================================================================= */
    #|.tooltip-wrapper {
    #|  position: relative;
    #|  display: inline-block;
    #|}
    #|[role="tooltip"] {
    #|  position: absolute;
    #|  z-index: 1000;
    #|  bottom: 100%;
    #|  left: 50%;
    #|  transform: translateX(-50%);
    #|  margin-bottom: 0.5rem;
    #|  padding: 0.5rem 0.75rem;
    #|  font-size: 0.75rem;
    #|  background: var(--foreground, #1f2937);
    #|  color: var(--background, white);
    #|  border-radius: 0.375rem;
    #|  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
    #|  white-space: nowrap;
    #|  pointer-events: none;
    #|}
    #|[role="tooltip"]::after {
    #|  content: "";
    #|  position: absolute;
    #|  top: 100%;
    #|  left: 50%;
    #|  transform: translateX(-50%);
    #|  border-width: 4px;
    #|  border-style: solid;
    #|  border-color: var(--foreground, #1f2937) transparent transparent transparent;
    #|}
    #|
    #|/* =============================================================================
    #|   LINK COMPONENT STYLES
    #|   ============================================================================= */
    #|a[role="link"], a:not([role]) {
    #|  color: var(--link-color, #2563eb);
    #|  text-decoration: underline;
    #|  text-underline-offset: 2px;
    #|  cursor: pointer;
    #|  transition: color 0.15s;
    #|}
    #|a[role="link"]:hover, a:not([role]):hover {
    #|  color: var(--link-hover, #1d4ed8);
    #|}
    #|a[role="link"]:focus-visible, a:not([role]):focus-visible {
    #|  outline: 2px solid var(--accent, #3b82f6);
    #|  outline-offset: 2px;
    #|  border-radius: 2px;
    #|}
    #|a[aria-disabled="true"] {
    #|  color: var(--muted-foreground, #9ca3af);
    #|  cursor: not-allowed;
    #|  text-decoration: none;
    #|  opacity: 0.6;
    #|}
    #|
    #|/* =============================================================================
    #|   TABLE COMPONENT STYLES
    #|   ============================================================================= */
    #|[role="table"] {
    #|  display: table;
    #|  width: 100%;
    #|  border-collapse: collapse;
    #|  border: 1px solid var(--border, #d1d5db);
    #|  border-radius: 0.375rem;
    #|  overflow: hidden;
    #|}
    #|[role="rowgroup"] {
    #|  display: table-row-group;
    #|}
    #|[role="row"] {
    #|  display: table-row;
    #|}
    #|[role="columnheader"], [role="rowheader"], [role="cell"] {
    #|  display: table-cell;
    #|  padding: 0.75rem 1rem;
    #|  text-align: left;
    #|  border-bottom: 1px solid var(--border, #e5e7eb);
    #|}
    #|[role="columnheader"] {
    #|  font-weight: 600;
    #|  background: var(--muted, #f3f4f6);
    #|}
    #|[role="rowheader"] {
    #|  font-weight: 500;
    #|}
    #|[role="row"]:last-child [role="cell"],
    #|[role="row"]:last-child [role="rowheader"] {
    #|  border-bottom: none;
    #|}
    #|[role="row"]:hover [role="cell"] {
    #|  background: var(--muted, #f9fafb);
    #|}
    #|[role="row"][aria-selected="true"] [role="cell"] {
    #|  background: var(--accent, #dbeafe);
    #|}
    #|
    #|/* =============================================================================
    #|   ALERT DIALOG COMPONENT STYLES
    #|   ============================================================================= */
    #|[role="alertdialog"],
    #|.alert-dialog {
    #|  position: fixed;
    #|  top: 50%;
    #|  left: 50%;
    #|  transform: translate(-50%, -50%);
    #|  z-index: 9999;
    #|  background: var(--background, white);
    #|  border: 1px solid var(--border, #d1d5db);
    #|  border-radius: 0.5rem;
    #|  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
    #|  max-width: 28rem;
    #|  width: calc(100% - 2rem);
    #|  padding: 1.5rem;
    #|  text-align: center;
    #|}
    #|[role="alertdialog"] h2,
    #|[role="alertdialog"] h3,
    #|.alert-dialog h2 {
    #|  font-size: 1.125rem;
    #|  font-weight: 600;
    #|  margin: 0 0 0.75rem;
    #|  color: var(--foreground, inherit);
    #|}
    #|[role="alertdialog"] p,
    #|.alert-dialog p {
    #|  margin: 0 0 1.5rem;
    #|  color: var(--muted-foreground, #6b7280);
    #|  font-size: 0.875rem;
    #|}
    #|[role="alertdialog"] .dialog-actions,
    #|.alert-dialog .dialog-actions {
    #|  display: flex;
    #|  gap: 0.75rem;
    #|  justify-content: center;
    #|}
    #|.alert-dialog button {
    #|  padding: 0.5rem 1rem;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  border-radius: 0.375rem;
    #|  cursor: pointer;
    #|  border: 1px solid var(--border, #d1d5db);
    #|  background: var(--background, white);
    #|  color: var(--foreground, inherit);
    #|}
    #|.alert-dialog button:hover {
    #|  background: var(--muted, #f3f4f6);
    #|}
    #|.alert-dialog button:focus {
    #|  outline: 2px solid var(--accent, #3b82f6);
    #|  outline-offset: 2px;
    #|}
    #|
    #|/* Dialog backdrop */
    #|.dialog-backdrop {
    #|  position: fixed;
    #|  inset: 0;
    #|  z-index: 9998;
    #|  background: rgba(0, 0, 0, 0.5);
    #|}
    #|
    #|/* =============================================================================
    #|   DIALOG (MODAL) COMPONENT STYLES
    #|   ============================================================================= */
    #|[role="dialog"] {
    #|  position: fixed;
    #|  top: 50%;
    #|  left: 50%;
    #|  transform: translate(-50%, -50%);
    #|  z-index: 9999;
    #|  background: var(--background, white);
    #|  border: 1px solid var(--border, #d1d5db);
    #|  border-radius: 0.5rem;
    #|  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
    #|  max-width: 32rem;
    #|  width: calc(100% - 2rem);
    #|  max-height: calc(100vh - 4rem);
    #|  overflow: auto;
    #|  padding: 1.5rem;
    #|}
    #|[role="dialog"] h3 {
    #|  font-size: 1.125rem;
    #|  font-weight: 600;
    #|  margin: 0 0 1rem;
    #|}
    #|[role="dialog"]:focus {
    #|  outline: none;
    #|}
    #|
    #|/* Dark mode is handled by CSS variables in theme_variables() */
    #|
    #|/* =============================================================================
    #|   REDUCED MOTION
    #|   ============================================================================= */
    #|@media (prefers-reduced-motion: reduce) {
    #|  [role="treeitem"][aria-expanded]::before,
    #|  [role="tooltip"],
    #|  a[role="link"], a:not([role]) {
    #|    transition: none;
    #|  }
    #|}
  css
}

///|
fn inject_styled_css() -> Unit {
  // Build CSS from individually imported styled components
  let buf = StringBuilder::new()
  buf.write_string("/* Luna Styled Components */\n\n")
  buf.write_string(@styled.theme_variables())
  buf.write_string("\n\n")
  buf.write_string(@switch.switch_css())
  buf.write_string("\n\n")
  buf.write_string(@tabs.tabs_css())
  buf.write_string("\n\n")
  buf.write_string(@accordion.accordion_css())
  buf.write_string("\n\n")
  buf.write_string(@checkbox.checkbox_css())
  buf.write_string("\n\n")
  buf.write_string(@radio.radio_css())
  buf.write_string("\n\n")
  buf.write_string(@spinbutton.spinbutton_css())
  buf.write_string("\n\n")
  buf.write_string(apg_components_css())
  let css = buf.to_string()

  // Inject CSS into head
  let doc = @js.global_this()._get("document")
  let style = doc._call("createElement", [@js.any("style")])
  let _ = style._call("setAttribute", [@js.any("data-styled"), @js.any("luna")])
  style._set("textContent", @js.any(css))
  let head = doc._get("head")
  let _ = head._call("appendChild", [style])

  // Log which CSS was injected
  let console = @js.global_this()._get("console")
  console._call("log", [@js.any("[Luna] Injected styled CSS for all components")]) |> ignore
  console._call("log", [@js.any("[Luna] CSS size: " + css.length().to_string() + " chars")]) |> ignore
}

///|
fn main {
  // Inject styled component CSS first
  inject_styled_css()

  let doc = @dom.document()
  match doc.getElementById("app") {
    Some(el) => @client.render_vnode(el, app())
    None => println("Error: #app element not found")
  }
}
