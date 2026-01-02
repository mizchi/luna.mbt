// Popover Component - SSR + Hydration
//
// HTML Convention:
//   <div luna:url="@luna_ui/components/hydrate/popover.js" luna:trigger="load">
//     <div data-popover>
//       <button data-popover-trigger aria-haspopup="dialog" aria-expanded="false">
//         Open
//       </button>
//       <div data-popover-content role="dialog" aria-hidden="true">
//         <button data-popover-close>×</button>
//         <!-- content -->
//       </div>
//     </div>
//   </div>

///|
/// Popover props
pub(all) struct PopoverProps {
  id : String
  trigger_label : String
  content : @luna.Node[Unit]
  hydration_url : String
}

///|
/// Create a popover component
fn popover_inner(
  trigger_label : String,
  content : @luna.Node[Unit]
) -> @luna.Node[Unit] {
  @element.div(
    attrs=[("data-popover", @luna.attr_static(""))],
    [
      @element.button(
        attrs=[
          ("data-popover-trigger", @luna.attr_static("")),
          ("aria-haspopup", @luna.attr_static("dialog")),
          ("aria-expanded", @luna.attr_static("false")),
        ],
        [@element.text(trigger_label)],
      ),
      @element.div(
        attrs=[
          ("data-popover-content", @luna.attr_static("")),
          ("role", @luna.attr_static("dialog")),
          ("aria-hidden", @luna.attr_static("true")),
        ],
        [
          @element.button(
            attrs=[("data-popover-close", @luna.attr_static(""))],
            [@element.text("×")],
          ),
          content,
        ],
      ),
    ],
  )
}

///|
/// Create a popover component with hydration
pub fn popover(props : PopoverProps) -> @luna.Node[Unit] {
  @luna.island(
    props.id,
    props.hydration_url,
    "{}",
    [popover_inner(props.trigger_label, props.content)],
    trigger=@luna.Load,
  )
}

///|
/// Create a popover without island wrapper
pub fn popover_static(
  trigger_label : String,
  content : @luna.Node[Unit]
) -> @luna.Node[Unit] {
  popover_inner(trigger_label, content)
}
