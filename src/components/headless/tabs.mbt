///|
/// Headless Tabs Component
///
/// Provides accessibility (ARIA) and behavior without DOM structure or styling.
///
/// APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/tabs/

///|
/// Tab props
pub(all) struct TabProps {
  attrs : Array[(String, @luna.Attr[@js.Any])]
  select : () -> Unit
  is_selected : Bool
}

///|
/// Create headless tab.
pub fn use_tab(
  id : String,
  controls : String,
  selected : @signal.Signal[Int],
  index : Int,
) -> TabProps {
  let is_selected = selected.get() == index
  let aria_attrs = tab_aria(id, is_selected, controls)
  let attrs : Array[(String, @luna.Attr[@js.Any])] = aria_attrs.map(fn(pair) {
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
pub fn[E] tablist_attrs(aria_label? : String) -> Array[(String, @luna.Attr[E])] {
  let aria_attrs = tablist_aria(aria_label?)
  aria_attrs.map(fn(pair) { (pair.0, @luna.attr_static(pair.1)) })
}

///|
/// Tab attrs (static version).
pub fn[E] tab_attrs(
  id : String,
  controls : String,
  selected : Bool,
) -> Array[(String, @luna.Attr[E])] {
  let aria_attrs = tab_aria(id, selected, controls)
  aria_attrs.map(fn(pair) { (pair.0, @luna.attr_static(pair.1)) })
}

///|
/// Tabpanel attrs.
pub fn[E] tabpanel_attrs(
  id : String,
  labelledby : String,
) -> Array[(String, @luna.Attr[E])] {
  let aria_attrs = tabpanel_aria(id, labelledby)
  aria_attrs.map(fn(pair) { (pair.0, @luna.attr_static(pair.1)) })
}
