///|
/// Headless Accordion Component
///
/// Provides accessibility (ARIA) and behavior without DOM structure or styling.
///
/// APG Reference: https://www.w3.org/WAI/ARIA/apg/patterns/accordion/

///|
/// Accordion header props
pub(all) struct AccordionHeaderProps {
  attrs : Array[(String, @luna.Attr[@js.Any])]
  toggle : () -> Unit
  is_expanded : Bool
}

///|
/// Create headless accordion header.
pub fn use_accordion_header(
  id : String,
  controls : String,
  expanded : @signal.Signal[Bool],
  index : Int,
  on_expand : (Int) -> Unit,
) -> AccordionHeaderProps {
  let is_expanded = expanded.get()
  let aria_attrs = @aria.accordion_header_aria(id, is_expanded, controls)
  let attrs : Array[(String, @luna.Attr[@js.Any])] = aria_attrs.map(fn(pair) {
    (pair.0, @luna.attr_static(pair.1))
  })

  // Update aria-expanded dynamically
  attrs.push(
    (
      "aria-expanded",
      @luna.attr_dynamic(fn() { if expanded.get() { "true" } else { "false" } }),
    ),
  )
  let toggle = fn() { on_expand(index) }
  attrs.push(("click", @luna.attr_handler(@luna.handler(fn(_) { toggle() }))))
  attrs.push(
    (
      "keydown",
      @luna.attr_handler(
        @luna.handler(fn(evt) {
          let key = get_event_key(evt)
          if @aria.is_toggle_key(key) {
            prevent_default(evt)
            toggle()
          }
        }),
      ),
    ),
  )
  { attrs, toggle, is_expanded }
}

///|
/// Accordion header attrs only (static version).
pub fn[E] accordion_header_attrs(
  id : String,
  controls : String,
  expanded : Bool,
) -> Array[(String, @luna.Attr[E])] {
  let aria_attrs = @aria.accordion_header_aria(id, expanded, controls)
  aria_attrs.map(fn(pair) { (pair.0, @luna.attr_static(pair.1)) })
}

///|
/// Accordion panel attrs.
pub fn[E] accordion_panel_attrs(
  id : String,
  labelledby : String,
  hidden : Bool,
  use_region : Bool,
) -> Array[(String, @luna.Attr[E])] {
  let aria_attrs = @aria.accordion_panel_aria(id, labelledby, hidden, use_region)
  aria_attrs.map(fn(pair) { (pair.0, @luna.attr_static(pair.1)) })
}
