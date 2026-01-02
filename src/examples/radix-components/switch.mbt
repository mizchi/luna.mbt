// Switch Component - SSR + Hydration
//
// Universal component pattern:
// - SSR: Render static HTML with aria-* attributes
// - Client: Hydration JS adds event handlers
//
// HTML Convention:
//   <div luna:url="/components/switch.js" luna:trigger="load">
//     <button data-switch-toggle aria-checked="true|false">
//       <span data-switch-thumb></span>
//     </button>
//   </div>
//
// CSS handles visual changes via [aria-checked] selector:
//   [data-switch-toggle][aria-checked="true"] { background: var(--primary); }
//   [data-switch-toggle][aria-checked="false"] { background: var(--muted); }
//   [aria-checked="true"] [data-switch-thumb] { transform: translateX(20px); }

///|
/// Switch component props
pub(all) struct SwitchProps {
  id : String
  default_checked : Bool
  label : String?
  hydration_url : String
}

///|
/// Create a switch toggle button
fn switch_button(checked : Bool) -> @luna.Node[Unit] {
  let checked_str = if checked { "true" } else { "false" }
  @element.button(
    attrs=[
      ("data-switch-toggle", @luna.attr_static("")),
      ("aria-checked", @luna.attr_static(checked_str)),
      ("role", @luna.attr_static("switch")),
    ],
    [@element.span(attrs=[("data-switch-thumb", @luna.attr_static(""))], [])],
  )
}

///|
/// Create a switch component with hydration
pub fn switch(props : SwitchProps) -> @luna.Node[Unit] {
  let button = switch_button(props.default_checked)
  let content = match props.label {
    Some(label_text) =>
      @element.label(attrs=[("data-switch-label", @luna.attr_static(""))], [
        @element.text(label_text),
        button,
      ])
    None => button
  }
  @luna.island(
    props.id,
    props.hydration_url,
    "{}",
    [content],
    trigger=@luna.Load,
  )
}

///|
/// Create a switch without island wrapper (for testing SSR output)
pub fn switch_static(checked : Bool, label : String?) -> @luna.Node[Unit] {
  let button = switch_button(checked)
  match label {
    Some(label_text) =>
      @element.label(attrs=[("data-switch-label", @luna.attr_static(""))], [
        @element.text(label_text),
        button,
      ])
    None => button
  }
}
