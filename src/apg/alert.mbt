///|
/// APG Alert Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/alert/
///
/// An alert is an element that displays a brief, important message
/// in a way that attracts the user's attention without interrupting the user's task.
///
/// Important:
/// - Alerts are automatically announced by screen readers
/// - Alerts should NOT affect keyboard focus
/// - Alerts should NOT disappear automatically (accessibility requirement)
/// - For interrupting workflow, use Alert Dialog pattern instead
///
/// ARIA:
/// - role="alert"
/// - Implicitly sets aria-live="assertive" and aria-atomic="true"

///|
/// Alert severity levels
pub(all) enum AlertType {
  Info        // Informational message
  Success     // Success/confirmation message
  Warning     // Warning message
  Error       // Error message
}

///|
fn AlertType::to_string(self : AlertType) -> String {
  match self {
    Info => "info"
    Success => "success"
    Warning => "warning"
    Error => "error"
  }
}

///|
/// Create an accessible alert element.
/// Alerts are automatically announced by screen readers when they appear.
///
/// Parameters:
/// - type_: Alert severity type (optional, for styling)
/// - aria_label: Accessible label (optional)
/// - children: Alert content
///
/// Example:
/// ```
/// alert([@luna.text("Your changes have been saved.")])
/// alert(type_=Error, [@luna.text("Invalid email address.")])
/// ```
pub fn[E] alert(
  type_? : AlertType,
  aria_label? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("alert")),
  ]
  match type_ {
    Some(t) => attrs.push(("data-type", @luna.attr_static(t.to_string())))
    None => ()
  }
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create an alert with live region for dynamic updates.
/// Use when alert content will be updated dynamically.
///
/// Parameters:
/// - type_: Alert severity type
/// - aria_live: Live region politeness (default: "assertive")
/// - children: Alert content
pub fn[E] alert_live(
  type_? : AlertType,
  aria_live? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let live = match aria_live {
    Some(v) => v
    None => "assertive"
  }
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("alert")),
    ("aria-live", @luna.attr_static(live)),
    ("aria-atomic", @luna.attr_static("true")),
  ]
  match type_ {
    Some(t) => attrs.push(("data-type", @luna.attr_static(t.to_string())))
    None => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create an inline alert (status message).
/// Uses role="status" for less urgent messages that don't require immediate attention.
/// Screen readers announce these during a pause in user activity.
///
/// Parameters:
/// - type_: Alert type for styling
/// - children: Alert content
pub fn[E] status(
  type_? : AlertType,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("status")),
  ]
  match type_ {
    Some(t) => attrs.push(("data-type", @luna.attr_static(t.to_string())))
    None => ()
  }
  @luna.h("div", attrs, children)
}
