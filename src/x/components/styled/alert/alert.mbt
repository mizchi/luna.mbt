///|
/// Styled Alert Component
///
/// A styled alert for displaying important messages with different severity levels.
///
/// Class names (BEM):
/// - .alert           - Root container
/// - .alert__title    - Alert title
/// - .alert__description - Alert description
/// - .alert--error    - Error variant
/// - .alert--warning  - Warning variant
/// - .alert--success  - Success variant
/// - .alert--status   - Status/info variant
///
/// Data attributes:
/// - [data-variant="error"|"warning"|"success"|"status"]

///|
/// Alert variant types
pub(all) enum AlertVariant {
  Error
  Warning
  Success
  Status
}

///|
fn variant_to_string(variant : AlertVariant) -> String {
  match variant {
    Error => "error"
    Warning => "warning"
    Success => "success"
    Status => "status"
  }
}

///|
/// Slots for the alert component
pub(all) struct AlertSlots {
  root : String
  title : String
  description : String
}

///|
/// Default BEM class names for alert
pub fn alert_slots() -> AlertSlots {
  { root: "alert", title: "alert__title", description: "alert__description" }
}

///|
/// Create a styled alert component.
///
/// Parameters:
/// - title: Alert title text (optional)
/// - description: Alert description text (optional)
/// - variant: Alert variant (error, warning, success, status)
/// - class: Additional CSS class
/// - children: Child nodes (alternative to title/description)
pub fn alert(
  variant : AlertVariant,
  title? : String,
  description? : String,
  class? : String,
  children? : Array[@luna.Node[@js.Any]],
) -> @luna.Node[@js.Any] {
  let slots = alert_slots()
  let variant_str = variant_to_string(variant)
  let root_class = slots.root + " " + slots.root + "--" + variant_str
  let final_class = match class {
    Some(c) => root_class + " " + c
    None => root_class
  }
  let content : Array[@luna.Node[@js.Any]] = []

  // Add title if provided
  match title {
    Some(t) =>
      content.push(
        @luna.h(
          "div",
          [("class", @luna.attr_static(slots.title))],
          [@luna.text(t)],
        ),
      )
    None => ()
  }

  // Add description if provided
  match description {
    Some(d) =>
      content.push(
        @luna.h(
          "div",
          [("class", @luna.attr_static(slots.description))],
          [@luna.text(d)],
        ),
      )
    None => ()
  }

  // Add children if provided
  match children {
    Some(c) => content.append(c)
    None => ()
  }
  @luna.h(
    "div",
    [
      ("role", @luna.attr_static("alert")),
      ("aria-live", @luna.attr_static("polite")),
      ("data-variant", @luna.attr_static(variant_str)),
      ("class", @luna.attr_static(final_class)),
    ],
    content,
  )
}

///|
/// Get the CSS for the styled alert.
pub fn alert_css() -> String {
  let css =
    #|/* Alert - Default Theme */
    #|.alert {
    #|  position: relative;
    #|  padding: 0.75rem 1rem;
    #|  padding-left: 1.25rem;
    #|  border-radius: 0.375rem;
    #|  background: var(--muted);
    #|  color: var(--foreground);
    #|  margin-bottom: 0.75rem;
    #|}
    #|
    #|.alert:last-child {
    #|  margin-bottom: 0;
    #|}
    #|
    #|.alert::before {
    #|  content: "";
    #|  position: absolute;
    #|  left: 0;
    #|  top: 0;
    #|  bottom: 0;
    #|  width: 4px;
    #|  border-radius: 0.375rem 0 0 0.375rem;
    #|  background: var(--accent);
    #|}
    #|
    #|.alert__title {
    #|  font-weight: 600;
    #|  font-size: 1rem;
    #|  margin-bottom: 0.25rem;
    #|}
    #|
    #|.alert__description {
    #|  font-size: 0.875rem;
    #|  color: var(--muted-foreground);
    #|}
    #|
    #|/* Error variant */
    #|.alert--error::before {
    #|  background: var(--destructive);
    #|}
    #|
    #|.alert--error .alert__title {
    #|  color: var(--destructive);
    #|}
    #|
    #|/* Warning variant */
    #|.alert--warning::before {
    #|  background: var(--warning);
    #|}
    #|
    #|.alert--warning .alert__title {
    #|  color: var(--warning);
    #|}
    #|
    #|/* Success variant */
    #|.alert--success::before {
    #|  background: var(--success);
    #|}
    #|
    #|.alert--success .alert__title {
    #|  color: var(--success);
    #|}
    #|
    #|/* Status/Info variant */
    #|.alert--status::before {
    #|  background: var(--accent);
    #|}
    #|
    #|.alert--status .alert__title {
    #|  color: var(--accent);
    #|}
  css
}
