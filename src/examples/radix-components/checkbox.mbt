// Checkbox Component - SSR + Hydration
//
// Universal component pattern:
// - SSR: Render static HTML with aria-* and data-* attributes
// - Client: Hydration JS adds event handlers
//
// HTML Convention:
//   <div luna:url="/components/checkbox.js" luna:trigger="load">
//     <button data-checkbox aria-checked="true|false|mixed" data-state="checked|unchecked|indeterminate">
//       <span data-checkbox-indicator></span>
//     </button>
//   </div>
//
// CSS handles visual changes:
//   [aria-checked="true"] [data-checkbox-indicator] { opacity: 1; }
//   [aria-checked="false"] [data-checkbox-indicator] { opacity: 0; }

///|
/// Checkbox state
pub(all) enum CheckboxState {
  Checked
  Unchecked
  Indeterminate
} derive(Show)

///|
/// Checkbox props
pub(all) struct CheckboxProps {
  id : String
  default_state : CheckboxState
  label : String?
  hydration_url : String
}

///|
fn checkbox_state_to_aria(state : CheckboxState) -> String {
  match state {
    Checked => "true"
    Unchecked => "false"
    Indeterminate => "mixed"
  }
}

///|
fn checkbox_state_to_data(state : CheckboxState) -> String {
  match state {
    Checked => "checked"
    Unchecked => "unchecked"
    Indeterminate => "indeterminate"
  }
}

///|
/// Create a checkbox button
fn checkbox_button(state : CheckboxState) -> @luna.Node[Unit] {
  @element.button(
    attrs=[
      ("data-checkbox", @luna.attr_static("")),
      ("aria-checked", @luna.attr_static(checkbox_state_to_aria(state))),
      ("data-state", @luna.attr_static(checkbox_state_to_data(state))),
      ("role", @luna.attr_static("checkbox")),
    ],
    [
      @element.span(
        attrs=[("data-checkbox-indicator", @luna.attr_static(""))],
        [@element.text("✓")],
      ),
    ],
  )
}

///|
/// Create a checkbox component with hydration
pub fn checkbox(props : CheckboxProps) -> @luna.Node[Unit] {
  let button = checkbox_button(props.default_state)
  let content = match props.label {
    Some(label_text) =>
      @element.label(
        attrs=[("data-checkbox-label", @luna.attr_static(""))],
        [button, @element.text(" " + label_text)],
      )
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
/// Create a checkbox without island wrapper (for testing SSR output)
pub fn checkbox_static(
  state : CheckboxState,
  label : String?
) -> @luna.Node[Unit] {
  let button = checkbox_button(state)
  match label {
    Some(label_text) =>
      @element.label(
        attrs=[("data-checkbox-label", @luna.attr_static(""))],
        [button, @element.text(" " + label_text)],
      )
    None => button
  }
}
