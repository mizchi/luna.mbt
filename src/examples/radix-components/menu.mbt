// Menu Component - SSR + Hydration
//
// HTML Convention:
//   <div luna:url="@luna_ui/components/hydrate/menu.js" luna:trigger="load">
//     <div data-menu>
//       <button data-menu-trigger aria-haspopup="menu" aria-expanded="false">
//         Menu
//       </button>
//       <div data-menu-content role="menu" aria-hidden="true">
//         <button data-menu-item data-value="edit" role="menuitem">Edit</button>
//         <div data-menu-separator role="separator"></div>
//         <button data-menu-item data-value="delete" role="menuitem">Delete</button>
//       </div>
//     </div>
//   </div>

///|
/// Menu item types
pub(all) enum MenuItem {
  Item(String, String) // (value, label)
  Separator
}

///|
/// Menu props
pub(all) struct MenuProps {
  id : String
  trigger_label : String
  items : Array[MenuItem]
  hydration_url : String
}

///|
/// Create a menu item node
fn menu_item_node(item : MenuItem) -> @luna.Node[Unit] {
  match item {
    Item(value, label) =>
      @element.button(
        attrs=[
          ("data-menu-item", @luna.attr_static("")),
          ("data-value", @luna.attr_static(value)),
          ("role", @luna.attr_static("menuitem")),
        ],
        [@element.text(label)],
      )
    Separator =>
      @element.div(
        attrs=[
          ("data-menu-separator", @luna.attr_static("")),
          ("role", @luna.attr_static("separator")),
        ],
        [],
      )
  }
}

///|
/// Create a menu component
fn menu_inner(
  trigger_label : String,
  items : Array[MenuItem],
) -> @luna.Node[Unit] {
  @element.div(attrs=[("data-menu", @luna.attr_static(""))], [
    @element.button(
      attrs=[
        ("data-menu-trigger", @luna.attr_static("")),
        ("aria-haspopup", @luna.attr_static("menu")),
        ("aria-expanded", @luna.attr_static("false")),
      ],
      [@element.text(trigger_label)],
    ),
    @element.div(
      attrs=[
        ("data-menu-content", @luna.attr_static("")),
        ("role", @luna.attr_static("menu")),
        ("aria-hidden", @luna.attr_static("true")),
      ],
      items.map(fn(item) { menu_item_node(item) }),
    ),
  ])
}

///|
/// Create a menu component with hydration
pub fn menu(props : MenuProps) -> @luna.Node[Unit] {
  @luna.island(
    props.id,
    props.hydration_url,
    "{}",
    [menu_inner(props.trigger_label, props.items)],
    trigger=@luna.Load,
  )
}

///|
/// Create a menu without island wrapper
pub fn menu_static(
  trigger_label : String,
  items : Array[MenuItem],
) -> @luna.Node[Unit] {
  menu_inner(trigger_label, items)
}
