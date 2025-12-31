///|
/// Radix-style Alert component for Luna (Headless)
/// Outputs semantic HTML with data-* attributes for external CSS styling

///|
/// Alert variant
pub(all) enum AlertVariant {
  Default
  Destructive
  Warning
  Success
}

///|
pub fn AlertVariant::to_string(self : AlertVariant) -> String {
  match self {
    Default => "default"
    Destructive => "destructive"
    Warning => "warning"
    Success => "success"
  }
}

///|
/// Create a headless alert container
/// Outputs: <div class="radix-alert" role="alert" data-variant="...">children</div>
pub fn radix_alert(
  variant? : AlertVariant,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let variant_val = match variant {
    Some(v) => v
    None => Default
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-alert")),
    ("role", @luna.attr_static("alert")),
    ("data-variant", @luna.attr_static(variant_val.to_string())),
  ]

  @luna.h("div", attrs, children)
}

///|
/// Create a headless alert title
/// Outputs: <h5 class="radix-alert-title">children</h5>
pub fn radix_alert_title(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("h5", [("class", @luna.attr_static("radix-alert-title"))], children)
}

///|
/// Create a headless alert description
/// Outputs: <div class="radix-alert-description">children</div>
pub fn radix_alert_description(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-alert-description"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the alert component
fn alert_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.alert {
    #|  position: relative;
    #|  padding: 1rem;
    #|  border-radius: 8px;
    #|  border: 1px solid;
    #|}
    #|
    #|.alert[data-variant="default"] {
    #|  background: #fafafa;
    #|  border-color: #e4e4e7;
    #|  color: #18181b;
    #|}
    #|
    #|.alert[data-variant="destructive"] {
    #|  background: #fef2f2;
    #|  border-color: #fecaca;
    #|  color: #991b1b;
    #|}
    #|
    #|.alert[data-variant="warning"] {
    #|  background: #fffbeb;
    #|  border-color: #fde68a;
    #|  color: #92400e;
    #|}
    #|
    #|.alert[data-variant="success"] {
    #|  background: #f0fdf4;
    #|  border-color: #bbf7d0;
    #|  color: #166534;
    #|}
    #|
    #|.alert-title {
    #|  margin: 0 0 0.25rem 0;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  line-height: 1.4;
    #|}
    #|
    #|.alert-description {
    #|  font-size: 0.875rem;
    #|  line-height: 1.5;
    #|  opacity: 0.9;
    #|}
  css
}

///|
/// Create a styled alert with Declarative Shadow DOM
pub fn radix_alert_styled(
  variant? : AlertVariant,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let variant_val = match variant {
    Some(v) => v
    None => Default
  }

  let css = match styles {
    Some(s) => s
    None => alert_styles()
  }

  // Build alert attributes
  let alert_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("alert")),
    ("role", @luna.attr_static("alert")),
    ("data-variant", @luna.attr_static(variant_val.to_string())),
  ]

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("div", alert_attrs, [@luna.h("slot", [], [])]),
  ]

  // Create DSD structure
  let all_children : Array[@luna.Node[Unit]] = [
    @luna.h(
      "template",
      [("shadowrootmode", @luna.attr_static("open"))],
      template_children,
    ),
  ]

  for child in children {
    all_children.push(child)
  }

  // Host attributes
  let host_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("data-variant", @luna.attr_static(variant_val.to_string())),
  ]

  @luna.h("radix-alert", host_attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create an alert with luna/css atomic styles
pub fn radix_alert_ucss(
  variant? : AlertVariant,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let variant_val = match variant {
    Some(v) => v
    None => Default
  }

  let class_names = alert_base_styles() + " " + alert_variant_styles(variant_val)

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("role", @luna.attr_static("alert")),
  ]

  @luna.h("div", attrs, children)
}

///|
/// Create an alert title with luna/css atomic styles
pub fn radix_alert_title_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = alert_title_styles()
  @luna.h("h5", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create an alert description with luna/css atomic styles
pub fn radix_alert_description_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = alert_description_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
