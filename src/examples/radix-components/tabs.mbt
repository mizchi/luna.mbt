// Tabs Component - SSR + Hydration
//
// HTML Convention:
//   <div luna:url="@luna_ui/components/hydrate/tabs.js" luna:trigger="load">
//     <div data-tabs data-value="tab1">
//       <div data-tablist role="tablist">
//         <button data-tab data-value="tab1" role="tab" aria-selected="true">Tab 1</button>
//         <button data-tab data-value="tab2" role="tab" aria-selected="false">Tab 2</button>
//       </div>
//       <div data-tabpanel data-value="tab1" role="tabpanel" data-state="active">Content 1</div>
//       <div data-tabpanel data-value="tab2" role="tabpanel" data-state="inactive">Content 2</div>
//     </div>
//   </div>

///|
/// Tab item
pub(all) struct TabItem {
  value : String
  label : String
  content : @luna.Node[Unit]
}

///|
/// Tabs props
pub(all) struct TabsProps {
  id : String
  default_value : String
  items : Array[TabItem]
  hydration_url : String
}

///|
/// Create a tab trigger
fn tab_trigger(item : TabItem, active_value : String) -> @luna.Node[Unit] {
  let is_active = item.value == active_value
  let aria_selected = if is_active { "true" } else { "false" }
  let tabindex = if is_active { "0" } else { "-1" }
  @element.button(
    attrs=[
      ("data-tab", @luna.attr_static("")),
      ("data-value", @luna.attr_static(item.value)),
      ("role", @luna.attr_static("tab")),
      ("aria-selected", @luna.attr_static(aria_selected)),
      ("tabindex", @luna.attr_static(tabindex)),
    ],
    [@element.text(item.label)],
  )
}

///|
/// Create a tab panel
fn tab_panel(item : TabItem, active_value : String) -> @luna.Node[Unit] {
  let is_active = item.value == active_value
  let state = if is_active { "active" } else { "inactive" }
  let hidden = if is_active { "false" } else { "true" }
  @element.div(
    attrs=[
      ("data-tabpanel", @luna.attr_static("")),
      ("data-value", @luna.attr_static(item.value)),
      ("role", @luna.attr_static("tabpanel")),
      ("data-state", @luna.attr_static(state)),
      ("aria-hidden", @luna.attr_static(hidden)),
    ],
    [item.content],
  )
}

///|
/// Create a tabs component
fn tabs_inner(default_value : String, items : Array[TabItem]) -> @luna.Node[Unit] {
  let triggers = items.map(fn(item) { tab_trigger(item, default_value) })
  let panels = items.map(fn(item) { tab_panel(item, default_value) })
  @element.div(
    attrs=[
      ("data-tabs", @luna.attr_static("")),
      ("data-value", @luna.attr_static(default_value)),
    ],
    [
      @element.div(
        attrs=[("data-tablist", @luna.attr_static("")), ("role", @luna.attr_static("tablist"))],
        triggers,
      ),
      @element.fragment(panels),
    ],
  )
}

///|
/// Create a tabs component with hydration
pub fn tabs(props : TabsProps) -> @luna.Node[Unit] {
  @luna.island(
    props.id,
    props.hydration_url,
    "{}",
    [tabs_inner(props.default_value, props.items)],
    trigger=@luna.Load,
  )
}

///|
/// Create tabs without island wrapper
pub fn tabs_static(
  default_value : String,
  items : Array[TabItem]
) -> @luna.Node[Unit] {
  tabs_inner(default_value, items)
}
