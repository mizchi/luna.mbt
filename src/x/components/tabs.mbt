///|
/// APG Tabs Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/tabs/
///
/// Tabs are a set of layered sections of content that display one panel at a time.
/// Each tab panel has an associated tab element that controls its visibility.
///
/// Keyboard Interaction:
/// - Tab: Move focus into/out of tab list
/// - Left/Right Arrow: Move between tabs (horizontal)
/// - Up/Down Arrow: Move between tabs (vertical)
/// - Space/Enter: Activate tab (manual activation mode)
/// - Home: Move to first tab (optional)
/// - End: Move to last tab (optional)
///
/// ARIA:
/// - tablist: Container for tabs
/// - tab: Each tab button with aria-selected, aria-controls
/// - tabpanel: Content panel with aria-labelledby

///|
/// Tabs orientation
pub(all) enum TabsOrientation {
  Horizontal // Default, use Left/Right arrows
  Vertical // Use Up/Down arrows
}

///|
/// Tab item data for building tabs
pub(all) struct TabItem[E] {
  id : String // Unique tab ID
  label : String // Tab label text
  panel : Array[@luna.Node[E]] // Panel content
}

///|
/// Create a tab item
pub fn[E] tab_item(
  id : String,
  label : String,
  panel : Array[@luna.Node[E]],
) -> TabItem[E] {
  { id, label, panel }
}

///|
/// Create a complete tablist container.
///
/// Parameters:
/// - aria_label: Accessible label for the tab list
/// - orientation: Horizontal or Vertical (default: Horizontal)
/// - children: Tab buttons (use `tab()` to create)
pub fn[E] tablist(
  aria_label? : String,
  orientation? : TabsOrientation,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("tablist")),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if orientation is Some(Vertical) {
    attrs.push(("aria-orientation", @luna.attr_static("vertical")))
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a single tab button.
///
/// Parameters:
/// - id: Tab ID (used for aria-controls on the tab and id on the panel)
/// - selected: Whether this tab is currently selected
/// - controls: ID of the associated tabpanel
/// - on_click: Click handler to activate the tab
/// - on_keydown: Keydown handler (for arrow key navigation)
/// - children: Tab label content
pub fn[E] tab(
  id : String,
  selected : Bool,
  controls : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("tab")),
    ("id", @luna.attr_static(id)),
    (
      "aria-selected",
      @luna.attr_static(if selected { "true" } else { "false" }),
    ),
    ("aria-controls", @luna.attr_static(controls)),
    ("tabindex", @luna.attr_static(if selected { "0" } else { "-1" })),
  ]
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a dynamic tab with signal-based selected state.
pub fn[E] tab_dyn(
  id : String,
  selected : @resource.Signal[Bool],
  controls : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("tab")),
    ("id", @luna.attr_static(id)),
    (
      "aria-selected",
      @luna.attr_dynamic(fn() { if selected.get() { "true" } else { "false" } }),
    ),
    ("aria-controls", @luna.attr_static(controls)),
    (
      "tabindex",
      @luna.attr_dynamic(fn() { if selected.get() { "0" } else { "-1" } }),
    ),
  ]
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a tabpanel.
///
/// Parameters:
/// - id: Panel ID (referenced by tab's aria-controls)
/// - labelledby: ID of the associated tab (for aria-labelledby)
/// - hidden: Whether the panel is hidden
/// - children: Panel content
pub fn[E] tabpanel(
  id : String,
  labelledby : String,
  hidden : Bool,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("tabpanel")),
    ("id", @luna.attr_static(id)),
    ("aria-labelledby", @luna.attr_static(labelledby)),
    ("tabindex", @luna.attr_static("0")),
  ]
  if hidden {
    attrs.push(("hidden", @luna.attr_static("")))
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a dynamic tabpanel with signal-based visibility.
pub fn[E] tabpanel_dyn(
  id : String,
  labelledby : String,
  visible : @resource.Signal[Bool],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("tabpanel")),
    ("id", @luna.attr_static(id)),
    ("aria-labelledby", @luna.attr_static(labelledby)),
    ("tabindex", @luna.attr_static("0")),
  ]
  @luna.show(fn() { visible.get() }, fn() { @luna.h("div", attrs, children) })
}

///|
/// Create a tab with computed selected state (accepts getter function).
/// This is useful when the selected state is derived from another signal.
/// Example: `tab_computed(id, fn() { active_tab.get() == 0 }, controls, children)`
pub fn[E] tab_computed(
  id : String,
  selected : () -> Bool,
  controls : String,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("tab")),
    ("id", @luna.attr_static(id)),
    ("aria-selected", @luna.attr_dynamic(fn() { bool_to_aria(selected()) })),
    ("aria-controls", @luna.attr_static(controls)),
    (
      "tabindex",
      @luna.attr_dynamic(fn() { if selected() { "0" } else { "-1" } }),
    ),
  ]
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a tabpanel with computed visibility (accepts getter function).
/// Uses style display instead of hidden attribute for proper visibility control.
pub fn[E] tabpanel_computed(
  id : String,
  labelledby : String,
  visible : () -> Bool,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("tabpanel")),
    ("id", @luna.attr_static(id)),
    ("aria-labelledby", @luna.attr_static(labelledby)),
    ("tabindex", @luna.attr_static("0")),
    (
      "style",
      @luna.attr_dynamic(fn() { if visible() { "" } else { "display:none" } }),
    ),
  ]
  @luna.h("div", attrs, children)
}

///|
/// Build a complete tabs component from tab items.
/// This is a convenience function that creates the full structure.
///
/// Parameters:
/// - items: Array of TabItem containing tab data
/// - selected_index: Index of the currently selected tab
/// - aria_label: Accessible label for the tabs
/// - orientation: Tabs orientation
pub fn[E] tabs(
  items : Array[TabItem[E]],
  selected_index : Int,
  aria_label? : String,
  orientation? : TabsOrientation,
) -> @luna.Node[E] {
  let tab_buttons : Array[@luna.Node[E]] = []
  let panels : Array[@luna.Node[E]] = []
  for i, item in items {
    let is_selected = i == selected_index
    let tab_id = "tab-" + item.id
    let panel_id = "panel-" + item.id
    tab_buttons.push(
      tab(tab_id, is_selected, panel_id, [@luna.text(item.label)]),
    )
    panels.push(tabpanel(panel_id, tab_id, not(is_selected), item.panel))
  }
  let list = tablist(aria_label?, orientation?, tab_buttons)
  let children : Array[@luna.Node[E]] = [list]
  for p in panels {
    children.push(p)
  }
  @luna.fragment(children)
}

///|
/// Build a dynamic tabs component with signal-based selection.
/// This is the recommended way to create tabs with reactive state.
///
/// Parameters:
/// - items: Array of TabItem containing tab data
/// - selected_index: Signal containing the currently selected tab index
/// - aria_label: Accessible label for the tabs
/// - orientation: Tabs orientation
pub fn[E] tabs_dyn(
  items : Array[TabItem[E]],
  selected_index : @resource.Signal[Int],
  aria_label? : String,
  orientation? : TabsOrientation,
) -> @luna.Node[E] {
  let tab_buttons : Array[@luna.Node[E]] = []
  let panels : Array[@luna.Node[E]] = []
  for i, item in items {
    let index = i // capture index
    let tab_id = "tab-" + item.id
    let panel_id = "panel-" + item.id
    tab_buttons.push(
      tab_computed(
        tab_id,
        fn() { selected_index.get() == index },
        panel_id,
        on_click=@luna.handler(fn(_) { selected_index.set(index) }),
        [@luna.text(item.label)],
      ),
    )
    panels.push(
      tabpanel_computed(
        panel_id,
        tab_id,
        fn() { selected_index.get() == index },
        item.panel,
      ),
    )
  }
  let list = tablist(aria_label?, orientation?, tab_buttons)
  let children : Array[@luna.Node[E]] = [list]
  for p in panels {
    children.push(p)
  }
  @luna.fragment(children)
}

///|
/// Build a dynamic tabs component with full keyboard support.
/// Includes arrow key navigation, Home/End support.
///
/// Parameters:
/// - items: Array of TabItem containing tab data
/// - selected_index: Signal containing the currently selected tab index
/// - aria_label: Accessible label for the tabs
/// - orientation: Tabs orientation (affects which arrow keys to use)
pub fn tabs_interactive(
  items : Array[TabItem[@js.Any]],
  selected_index : @resource.Signal[Int],
  aria_label? : String,
  orientation? : TabsOrientation,
) -> @luna.Node[@js.Any] {
  let is_vertical = match orientation {
    Some(Vertical) => true
    _ => false
  }
  let length = items.length()
  let keydown_handler = if is_vertical {
    make_vertical_nav_handler(fn() { selected_index.get() }, length, fn(i) {
      selected_index.set(i)
    })
  } else {
    make_horizontal_nav_handler(fn() { selected_index.get() }, length, fn(i) {
      selected_index.set(i)
    })
  }
  let tab_buttons : Array[@luna.Node[@js.Any]] = []
  let panels : Array[@luna.Node[@js.Any]] = []
  for i, item in items {
    let index = i // capture index
    let tab_id = "tab-" + item.id
    let panel_id = "panel-" + item.id
    tab_buttons.push(
      tab_computed(
        tab_id,
        fn() { selected_index.get() == index },
        panel_id,
        on_click=@luna.handler(fn(_) { selected_index.set(index) }),
        on_keydown=keydown_handler,
        [@luna.text(item.label)],
      ),
    )
    panels.push(
      tabpanel_computed(
        panel_id,
        tab_id,
        fn() { selected_index.get() == index },
        item.panel,
      ),
    )
  }
  let list = tablist(aria_label?, orientation?, tab_buttons)
  let children : Array[@luna.Node[@js.Any]] = [list]
  for p in panels {
    children.push(p)
  }
  @luna.fragment(children)
}
