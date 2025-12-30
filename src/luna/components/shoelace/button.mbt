///|
/// Shoelace Button component for Luna
/// Generates sl-button custom element for both CSR and SSR

///|
/// Button variant types
pub(all) enum SlButtonVariant {
  Default
  Primary
  Success
  Neutral
  Warning
  Danger
}

///|
pub fn SlButtonVariant::to_string(self : SlButtonVariant) -> String {
  match self {
    Default => "default"
    Primary => "primary"
    Success => "success"
    Neutral => "neutral"
    Warning => "warning"
    Danger => "danger"
  }
}

///|
/// Button size types
pub(all) enum SlSize {
  Small
  Medium
  Large
}

///|
pub fn SlSize::to_string(self : SlSize) -> String {
  match self {
    Small => "small"
    Medium => "medium"
    Large => "large"
  }
}

///|
/// Create an sl-button element
/// Returns a VNode that renders to <sl-button> custom element
pub fn sl_button(
  variant? : SlButtonVariant,
  size? : SlSize,
  disabled? : Bool,
  loading? : Bool,
  outline? : Bool,
  pill? : Bool,
  circle? : Bool,
  href? : String,
  target? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = []

  // Set variant attribute
  match variant {
    Some(v) => attrs.push(("variant", @luna.attr_static(v.to_string())))
    None => ()
  }

  // Set size attribute
  match size {
    Some(s) => attrs.push(("size", @luna.attr_static(s.to_string())))
    None => ()
  }

  // Boolean attributes
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }
  match loading {
    Some(true) => attrs.push(("loading", @luna.attr_static("")))
    _ => ()
  }
  match outline {
    Some(true) => attrs.push(("outline", @luna.attr_static("")))
    _ => ()
  }
  match pill {
    Some(true) => attrs.push(("pill", @luna.attr_static("")))
    _ => ()
  }
  match circle {
    Some(true) => attrs.push(("circle", @luna.attr_static("")))
    _ => ()
  }

  // Link attributes
  match href {
    Some(h) => attrs.push(("href", @luna.attr_static(h)))
    None => ()
  }
  match target {
    Some(t) => attrs.push(("target", @luna.attr_static(t)))
    None => ()
  }
  @luna.h("sl-button", attrs, children)
}
