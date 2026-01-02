// Dialog Component - SSR + Hydration
//
// HTML Convention:
//   <div luna:url="@luna_ui/components/hydrate/dialog.js" luna:trigger="load">
//     <div data-dialog role="dialog" aria-modal="true" aria-hidden="true">
//       <div data-dialog-overlay></div>
//       <div data-dialog-content>
//         <button data-dialog-close>×</button>
//         <!-- content -->
//       </div>
//     </div>
//   </div>
//
// CSS handles visibility:
//   [data-dialog][aria-hidden="true"] { display: none; }
//   [data-dialog][aria-hidden="false"] { display: block; }

///|
/// Dialog props
pub(all) struct DialogProps {
  id : String
  title : String?
  content : @luna.Node[Unit]
  hydration_url : String
  open : Bool
}

///|
/// Create a dialog component
fn dialog_inner(
  title : String?,
  content : @luna.Node[Unit],
  open : Bool
) -> @luna.Node[Unit] {
  let aria_hidden = if open { "false" } else { "true" }
  let state = if open { "open" } else { "closed" }
  let title_node : @luna.Node[Unit] = match title {
    Some(t) =>
      @element.h2(
        attrs=[("data-dialog-title", @luna.attr_static(""))],
        [@element.text(t)],
      )
    None => @element.fragment([])
  }
  @element.div(
    attrs=[
      ("data-dialog", @luna.attr_static("")),
      ("role", @luna.attr_static("dialog")),
      ("aria-modal", @luna.attr_static("true")),
      ("aria-hidden", @luna.attr_static(aria_hidden)),
      ("data-state", @luna.attr_static(state)),
    ],
    [
      @element.div(attrs=[("data-dialog-overlay", @luna.attr_static(""))], []),
      @element.div(
        attrs=[("data-dialog-content", @luna.attr_static(""))],
        [
          @element.button(
            attrs=[("data-dialog-close", @luna.attr_static(""))],
            [@element.text("×")],
          ),
          title_node,
          content,
        ],
      ),
    ],
  )
}

///|
/// Create a dialog component with hydration
pub fn dialog(props : DialogProps) -> @luna.Node[Unit] {
  @luna.island(
    props.id,
    props.hydration_url,
    "{}",
    [dialog_inner(props.title, props.content, props.open)],
    trigger=@luna.Load,
  )
}

///|
/// Create a dialog without island wrapper
pub fn dialog_static(
  title : String?,
  content : @luna.Node[Unit],
  open : Bool
) -> @luna.Node[Unit] {
  dialog_inner(title, content, open)
}
