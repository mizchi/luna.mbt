///|
/// Styled Tabs Component
///
/// Class names (BEM):
/// - .tabs           - Root container
/// - .tabs__list     - Tab list
/// - .tabs__tab      - Individual tab
/// - .tabs__panel    - Tab panel
///
/// Data attributes:
/// - [data-state="active"|"inactive"]
///
/// Keyboard:
/// - ArrowLeft: Move to previous tab (wraps)
/// - ArrowRight: Move to next tab (wraps)
/// - Home: Move to first tab
/// - End: Move to last tab

///|
pub(all) struct TabsSlots {
  root : String
  list : String
  tab : String
  panel : String
}

///|
pub fn tabs_slots() -> TabsSlots {
  { root: "tabs", list: "tabs__list", tab: "tabs__tab", panel: "tabs__panel" }
}

///|
pub(all) struct TabItem {
  id : String
  label : String
  content : Array[@luna.Node[@js.Any, String]]
}

///|
pub fn tab_item(
  id : String,
  label : String,
  content : Array[@luna.Node[@js.Any, String]],
) -> TabItem {
  { id, label, content }
}

///|
pub fn tabs(
  items : Array[TabItem],
  selected : @resource.Signal[Int],
  aria_label? : String,
  class? : String,
) -> @luna.Node[@js.Any, String] {
  let slots = tabs_slots()
  let root_class = match class {
    Some(c) => slots.root + " " + c
    None => slots.root
  }

  // Generate tab IDs for focus management
  let tab_ids : Array[String] = []
  let panel_ids : Array[String] = []
  for item in items {
    tab_ids.push("tab-" + item.id)
    panel_ids.push("panel-" + item.id)
  }

  // Build tab list
  let tab_buttons : Array[@luna.Node[@js.Any, String]] = []
  for i, item in items {
    let tab_id = tab_ids[i]
    let panel_id = panel_ids[i]

    // Get headless props with keyboard navigation
    let props = @headless.use_tab_nav(tab_id, panel_id, tab_ids, i, selected)

    // Build tab attrs from headless + styling
    let tab_attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
      ("class", @luna.attr_static(slots.tab)),
      (
        "data-state",
        @luna.attr_dynamic(fn() {
          if selected.get() == i {
            "active"
          } else {
            "inactive"
          }
        }),
      ),
    ]
    for attr in props.attrs {
      tab_attrs.push(attr)
    }
    tab_buttons.push(@luna.h("button", tab_attrs, [@luna.text(item.label)]))
  }

  // Build panels
  let panels : Array[@luna.Node[@js.Any, String]] = []
  for i, item in items {
    let tab_id = tab_ids[i]
    let panel_id = panel_ids[i]

    // Get headless panel props
    let panel_props = @headless.use_tabpanel_nav(panel_id, tab_id)

    // Build panel attrs from headless + styling
    let panel_attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
      ("class", @luna.attr_static(slots.panel)),
    ]
    for attr in panel_props.attrs {
      panel_attrs.push(attr)
    }
    panels.push(
      @luna.show(fn() { selected.get() == i }, fn() {
        @luna.h("div", panel_attrs, item.content)
      }),
    )
  }
  let tablist_attrs : Array[(String, @luna.Attr[@js.Any, String])] = @headless.tablist_attrs(
    aria_label?,
  )
  @luna.h("div", [("class", @luna.attr_static(root_class))], [
    @luna.h(
      "div",
      tablist_attrs + [("class", @luna.attr_static(slots.list))],
      tab_buttons,
    ),
    @luna.fragment(panels),
  ])
}

///|
pub fn tabs_css() -> String {
  let css =
    #|/* Tabs - Default Theme */
    #|.tabs {
    #|  display: flex;
    #|  flex-direction: column;
    #|}
    #|
    #|.tabs__list {
    #|  display: flex;
    #|  gap: 0.25rem;
    #|  border-bottom: 1px solid var(--border);
    #|  position: relative;
    #|}
    #|
    #|.tabs__tab {
    #|  position: relative;
    #|  padding: 0.5rem 1rem;
    #|  border: 1px solid transparent;
    #|  border-bottom: none;
    #|  border-radius: 0.375rem 0.375rem 0 0;
    #|  background: transparent;
    #|  cursor: pointer;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  color: var(--muted-foreground);
    #|  margin: 0;
    #|  margin-bottom: -1px;
    #|  transition: color 0.15s, background-color 0.15s, border-color 0.15s;
    #|}
    #|
    #|.tabs__tab:hover {
    #|  color: var(--foreground);
    #|  background: var(--background);
    #|}
    #|
    #|.tabs__tab[data-state="active"] {
    #|  color: var(--foreground);
    #|  background: var(--background);
    #|  border-color: var(--border);
    #|}
    #|
    #|.tabs__tab:focus-visible {
    #|  outline: 2px solid var(--accent);
    #|  outline-offset: -2px;
    #|}
    #|
    #|.tabs__panel {
    #|  padding: 1rem;
    #|  color: var(--foreground);
    #|  border: 1px solid var(--border);
    #|  border-top: none;
    #|  border-radius: 0 0 0.375rem 0.375rem;
    #|}
    #|
    #|/* Reduced motion */
    #|@media (prefers-reduced-motion: reduce) {
    #|  .tabs__tab {
    #|    transition: none;
    #|  }
    #|}
  css
}
