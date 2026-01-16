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
  content : Array[@luna.Node[@js.Any]]
}

///|
pub fn tab_item(
  id : String,
  label : String,
  content : Array[@luna.Node[@js.Any]],
) -> TabItem {
  { id, label, content }
}

///|
pub fn tabs(
  items : Array[TabItem],
  selected : @resource.Signal[Int],
  aria_label? : String,
  class? : String,
) -> @luna.Node[@js.Any] {
  let slots = tabs_slots()
  let root_class = match class {
    Some(c) => slots.root + " " + c
    None => slots.root
  }

  // Build tab list
  let tab_buttons : Array[@luna.Node[@js.Any]] = []
  for i, item in items {
    let tab_id = "tab-" + item.id
    let panel_id = "panel-" + item.id
    let props = @headless.use_tab(tab_id, panel_id, selected, i)
    tab_buttons.push(
      @luna.h(
        "button",
        props.attrs +
        [
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
        ],
        [@luna.text(item.label)],
      ),
    )
  }

  // Build panels
  let panels : Array[@luna.Node[@js.Any]] = []
  for i, item in items {
    let tab_id = "tab-" + item.id
    let panel_id = "panel-" + item.id
    let panel_attrs : Array[(String, @luna.Attr[@js.Any])] = @headless.tabpanel_attrs(
      panel_id, tab_id,
    )
    panels.push(
      @luna.show(fn() { selected.get() == i }, fn() {
        @luna.h(
          "div",
          panel_attrs + [("class", @luna.attr_static(slots.panel))],
          item.content,
        )
      }),
    )
  }
  let tablist_attrs : Array[(String, @luna.Attr[@js.Any])] = @headless.tablist_attrs(
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
    #|  border-bottom: 1px solid var(--border);
    #|  gap: 0;
    #|}
    #|
    #|.tabs__tab {
    #|  padding: 0.75rem 1rem;
    #|  border: none;
    #|  background: transparent;
    #|  cursor: pointer;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  color: var(--muted-foreground);
    #|  border-bottom: 2px solid transparent;
    #|  margin-bottom: -1px;
    #|  transition: color 0.2s, border-color 0.2s;
    #|}
    #|
    #|.tabs__tab:hover {
    #|  color: var(--foreground);
    #|}
    #|
    #|.tabs__tab[data-state="active"] {
    #|  color: var(--accent);
    #|  border-bottom-color: var(--accent);
    #|}
    #|
    #|.tabs__tab:focus-visible {
    #|  outline: 2px solid var(--accent);
    #|  outline-offset: -2px;
    #|}
    #|
    #|.tabs__panel {
    #|  padding: 1rem 0;
    #|  color: var(--foreground);
    #|}
  css
}
