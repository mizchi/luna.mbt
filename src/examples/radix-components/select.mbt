// Select Component - SSR + Hydration
//
// HTML Convention:
//   <div luna:url="@luna_ui/components/hydrate/select.js" luna:trigger="load">
//     <div data-select>
//       <button data-select-trigger aria-haspopup="listbox" aria-expanded="false">
//         <span data-select-value>Select an option</span>
//       </button>
//       <div data-select-content role="listbox" aria-hidden="true">
//         <div data-select-item data-value="v1" role="option">Option 1</div>
//       </div>
//     </div>
//   </div>
//
// CSS handles visual changes:
//   [data-select-content][aria-hidden="true"] { display: none; }
//   [data-select-item][data-state="selected"] { background: var(--primary); }

///|
/// Select item
pub(all) struct SelectItem {
  value : String
  label : String
  selected : Bool
}

///|
/// Select props
pub(all) struct SelectProps {
  id : String
  placeholder : String
  items : Array[SelectItem]
  hydration_url : String
}

///|
/// Create a select item
fn select_item_node(item : SelectItem) -> @luna.Node[Unit] {
  let state = if item.selected { "selected" } else { "" }
  let aria_selected = if item.selected { "true" } else { "false" }
  @element.div(
    attrs=[
      ("data-select-item", @luna.attr_static("")),
      ("data-value", @luna.attr_static(item.value)),
      ("data-state", @luna.attr_static(state)),
      ("role", @luna.attr_static("option")),
      ("aria-selected", @luna.attr_static(aria_selected)),
    ],
    [@element.text(item.label)],
  )
}

///|
/// Create a select component
fn select_inner(
  placeholder : String,
  items : Array[SelectItem]
) -> @luna.Node[Unit] {
  let selected = items.iter().find_first(fn(i) { i.selected })
  let display_text = match selected {
    Some(item) => item.label
    None => placeholder
  }
  @element.div(
    attrs=[("data-select", @luna.attr_static(""))],
    [
      @element.button(
        attrs=[
          ("data-select-trigger", @luna.attr_static("")),
          ("aria-haspopup", @luna.attr_static("listbox")),
          ("aria-expanded", @luna.attr_static("false")),
        ],
        [
          @element.span(
            attrs=[("data-select-value", @luna.attr_static(""))],
            [@element.text(display_text)],
          ),
        ],
      ),
      @element.div(
        attrs=[
          ("data-select-content", @luna.attr_static("")),
          ("role", @luna.attr_static("listbox")),
          ("aria-hidden", @luna.attr_static("true")),
        ],
        items.map(fn(item) { select_item_node(item) }),
      ),
    ],
  )
}

///|
/// Create a select component with hydration
pub fn select(props : SelectProps) -> @luna.Node[Unit] {
  @luna.island(
    props.id,
    props.hydration_url,
    "{}",
    [select_inner(props.placeholder, props.items)],
    trigger=@luna.Load,
  )
}

///|
/// Create a select without island wrapper
pub fn select_static(
  placeholder : String,
  items : Array[SelectItem]
) -> @luna.Node[Unit] {
  select_inner(placeholder, items)
}
