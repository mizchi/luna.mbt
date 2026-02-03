///|
/// Headless Tabs Component
///
/// Provides accessibility (ARIA) and behavior without DOM structure or styling.
///
/// APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/tabs/

///|
/// Tab props
pub(all) struct TabProps {
  attrs : Array[(String, @luna.Attr[@js.Any, String])]
  select : () -> Unit
  is_selected : Bool
}

///|
/// Create headless tab.
pub fn use_tab(
  id : String,
  controls : String,
  selected : @resource.Signal[Int],
  index : Int,
) -> TabProps {
  let is_selected = selected.get() == index
  let aria_attrs = @aria.tab_aria(id, is_selected, controls)
  let attrs : Array[(String, @luna.Attr[@js.Any, String])] = aria_attrs.map(fn(
    pair,
  ) {
    (pair.0, @luna.attr_static(pair.1))
  })

  // Dynamic aria-selected and tabindex
  attrs.push(
    (
      "aria-selected",
      @luna.attr_dynamic(fn() {
        if selected.get() == index {
          "true"
        } else {
          "false"
        }
      }),
    ),
  )
  attrs.push(
    (
      "tabindex",
      @luna.attr_dynamic(fn() {
        if selected.get() == index {
          "0"
        } else {
          "-1"
        }
      }),
    ),
  )
  let select = fn() { selected.set(index) }
  attrs.push(("click", @luna.attr_handler(@luna.handler(fn(_) { select() }))))
  { attrs, select, is_selected }
}

///|
/// Tablist attrs.
pub fn[E] tablist_attrs(
  aria_label? : String,
) -> Array[(String, @luna.Attr[E, String])] {
  let aria_attrs = @aria.tablist_aria(aria_label?)
  aria_attrs.map(fn(pair) { (pair.0, @luna.attr_static(pair.1)) })
}

///|
/// Tab attrs (static version).
pub fn[E] tab_attrs(
  id : String,
  controls : String,
  selected : Bool,
) -> Array[(String, @luna.Attr[E, String])] {
  let aria_attrs = @aria.tab_aria(id, selected, controls)
  aria_attrs.map(fn(pair) { (pair.0, @luna.attr_static(pair.1)) })
}

///|
/// Tabpanel attrs.
pub fn[E] tabpanel_attrs(
  id : String,
  labelledby : String,
) -> Array[(String, @luna.Attr[E, String])] {
  let aria_attrs = @aria.tabpanel_aria(id, labelledby)
  aria_attrs.map(fn(pair) { (pair.0, @luna.attr_static(pair.1)) })
}

// Helper: Focus a tab element by ID

///|
fn focus_tab_element(tab_id : String) -> Unit {
  let doc = @js.global_this()._get("document")
  let el = doc._call("getElementById", [@js.any(tab_id)])
  let _ = el._call("focus", [])

}

///|
/// Create keyboard handler for tabs navigation.
///
/// Keyboard:
/// - ArrowLeft: Move to previous tab (wraps)
/// - ArrowRight: Move to next tab (wraps)
/// - Home: Move to first tab
/// - End: Move to last tab
pub fn make_tabs_keydown_handler(
  tab_ids : Array[String],
  index : Int,
  selected : @resource.Signal[Int],
) -> @luna.EventHandler[@js.Any] {
  let count = tab_ids.length()
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
  })
}

///|
/// Generate tab and panel IDs.
pub fn generate_tab_ids(
  items_count : Int,
  prefix : String,
) -> (Array[String], Array[String]) {
  let tab_ids : Array[String] = []
  let panel_ids : Array[String] = []
  for i in 0..<items_count {
    tab_ids.push(prefix + "-tab-" + i.to_string())
    panel_ids.push(prefix + "-panel-" + i.to_string())
  }
  (tab_ids, panel_ids)
}

///|
/// Props for tab with full APG keyboard navigation.
pub(all) struct TabNavProps {
  attrs : Array[(String, @luna.Attr[@js.Any, String])]
  is_selected : Bool
}

///|
/// Create tab props with keyboard navigation.
pub fn use_tab_nav(
  tab_id : String,
  panel_id : String,
  tab_ids : Array[String],
  index : Int,
  selected : @resource.Signal[Int],
) -> TabNavProps {
  let is_selected = selected.get() == index
  let attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
    ("type", @luna.attr_static("button")),
    ("id", @luna.attr_static(tab_id)),
    ("role", @luna.attr_static("tab")),
    (
      "aria-selected",
      @luna.attr_dynamic(fn() {
        if selected.get() == index {
          "true"
        } else {
          "false"
        }
      }),
    ),
    (
      "tabindex",
      @luna.attr_dynamic(fn() {
        if selected.get() == index {
          "0"
        } else {
          "-1"
        }
      }),
    ),
    ("aria-controls", @luna.attr_static(panel_id)),
    ("click", @luna.attr_handler(@luna.handler(fn(_) { selected.set(index) }))),
    (
      "keydown",
      @luna.attr_handler(make_tabs_keydown_handler(tab_ids, index, selected)),
    ),
  ]
  { attrs, is_selected }
}

///|
/// Props for tabpanel.
pub(all) struct TabPanelNavProps {
  attrs : Array[(String, @luna.Attr[@js.Any, String])]
}

///|
/// Create tabpanel props.
pub fn use_tabpanel_nav(panel_id : String, tab_id : String) -> TabPanelNavProps {
  let attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
    ("id", @luna.attr_static(panel_id)),
    ("role", @luna.attr_static("tabpanel")),
    ("aria-labelledby", @luna.attr_static(tab_id)),
    ("tabindex", @luna.attr_static("0")),
  ]
  { attrs, }
}
