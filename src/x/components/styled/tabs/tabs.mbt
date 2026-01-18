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

// Helper: Focus a tab element by ID
fn focus_tab_element(tab_id : String) -> Unit {
  let doc = @js.global_this()._get("document")
  let el = doc._call("getElementById", [@js.any(tab_id)])
  let _ = el._call("focus", [])
}

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

  // Generate tab IDs for focus management
  let tab_ids : Array[String] = []
  for item in items {
    tab_ids.push("tab-" + item.id)
  }
  let count = items.length()

  // Build tab list
  let tab_buttons : Array[@luna.Node[@js.Any]] = []
  for i, item in items {
    let tab_id = "tab-" + item.id
    let panel_id = "panel-" + item.id
    let index = i
    let props = @headless.use_tab(tab_id, panel_id, selected, i)

    // Add keyboard handler for APG navigation
    let keyboard_handler : (String, @luna.Attr[@js.Any]) = (
      "keydown",
      @luna.attr_handler(
        @luna.handler(fn(evt) {
          let key = evt._get("key").to_string()
          match key {
            "ArrowLeft" => {
              let _ = evt._call("preventDefault", [])
              // Move to previous tab (wraps)
              let prev_idx = if index == 0 { count - 1 } else { index - 1 }
              selected.set(prev_idx)
              focus_tab_element(tab_ids[prev_idx])
            }
            "ArrowRight" => {
              let _ = evt._call("preventDefault", [])
              // Move to next tab (wraps)
              let next_idx = (index + 1) % count
              selected.set(next_idx)
              focus_tab_element(tab_ids[next_idx])
            }
            "Home" => {
              let _ = evt._call("preventDefault", [])
              selected.set(0)
              focus_tab_element(tab_ids[0])
            }
            "End" => {
              let _ = evt._call("preventDefault", [])
              selected.set(count - 1)
              focus_tab_element(tab_ids[count - 1])
            }
            _ => ()
          }
        }),
      ),
    )

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
          keyboard_handler,
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
