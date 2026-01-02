// RadioGroup Component - SSR + Hydration
//
// HTML Convention:
//   <div luna:url="@luna_ui/components/hydrate/radio-group.js" luna:trigger="load">
//     <div data-radio-group role="radiogroup">
//       <div data-radio-item data-value="opt1" role="radio" aria-checked="true" tabindex="0">
//         <span data-radio-indicator></span>
//         <span>Option 1</span>
//       </div>
//       <div data-radio-item data-value="opt2" role="radio" aria-checked="false" tabindex="-1">
//         <span data-radio-indicator></span>
//         <span>Option 2</span>
//       </div>
//     </div>
//   </div>

///|
/// Radio item
pub(all) struct RadioItem {
  value : String
  label : String
}

///|
/// RadioGroup props
pub(all) struct RadioGroupProps {
  id : String
  default_value : String
  items : Array[RadioItem]
  hydration_url : String
}

///|
/// Create a radio item
fn radio_item_node(
  item : RadioItem,
  selected_value : String,
) -> @luna.Node[Unit] {
  let is_selected = item.value == selected_value
  let aria_checked = if is_selected { "true" } else { "false" }
  let tabindex = if is_selected { "0" } else { "-1" }
  let indicator_style = if is_selected {
    "display: block"
  } else {
    "display: none"
  }
  @element.div(
    attrs=[
      ("data-radio-item", @luna.attr_static("")),
      ("data-value", @luna.attr_static(item.value)),
      ("role", @luna.attr_static("radio")),
      ("aria-checked", @luna.attr_static(aria_checked)),
      ("tabindex", @luna.attr_static(tabindex)),
    ],
    [
      @element.span(
        attrs=[
          ("data-radio-indicator", @luna.attr_static("")),
          ("style", @luna.attr_static(indicator_style)),
        ],
        [],
      ),
      @element.span([@element.text(item.label)]),
    ],
  )
}

///|
/// Create a radio group component
fn radio_group_inner(
  default_value : String,
  items : Array[RadioItem],
) -> @luna.Node[Unit] {
  @element.div(
    attrs=[
      ("data-radio-group", @luna.attr_static("")),
      ("role", @luna.attr_static("radiogroup")),
    ],
    items.map(fn(item) { radio_item_node(item, default_value) }),
  )
}

///|
/// Create a radio group component with hydration
pub fn radio_group(props : RadioGroupProps) -> @luna.Node[Unit] {
  @luna.island(
    props.id,
    props.hydration_url,
    "{}",
    [radio_group_inner(props.default_value, props.items)],
    trigger=@luna.Load,
  )
}

///|
/// Create a radio group without island wrapper
pub fn radio_group_static(
  default_value : String,
  items : Array[RadioItem],
) -> @luna.Node[Unit] {
  radio_group_inner(default_value, items)
}
