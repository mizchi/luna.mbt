///|
/// Shoelace Input component for Luna
/// Generates sl-input custom element for both CSR and SSR

///|
/// Input type variants
pub(all) enum SlInputType {
  Text
  Email
  Password
  Number
  Tel
  Url
  Search
  Date
}

///|
pub fn SlInputType::to_string(self : SlInputType) -> String {
  match self {
    Text => "text"
    Email => "email"
    Password => "password"
    Number => "number"
    Tel => "tel"
    Url => "url"
    Search => "search"
    Date => "date"
  }
}

///|
/// Create an sl-input element
/// Returns a VNode that renders to <sl-input> custom element
pub fn sl_input(
  type_? : SlInputType,
  label? : String,
  placeholder? : String,
  value? : String,
  size? : SlSize,
  disabled? : Bool,
  readonly_? : Bool,
  required? : Bool,
  clearable? : Bool,
  password_toggle? : Bool,
  help_text? : String,
  minlength? : Int,
  maxlength? : Int,
  pattern? : String,
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = []

  // Set type attribute (default: text)
  match type_ {
    Some(t) => attrs.push(("type", @luna.attr_static(t.to_string())))
    None => attrs.push(("type", @luna.attr_static("text")))
  }

  // String attributes
  match label {
    Some(l) => attrs.push(("label", @luna.attr_static(l)))
    None => ()
  }

  match placeholder {
    Some(p) => attrs.push(("placeholder", @luna.attr_static(p)))
    None => ()
  }

  match value {
    Some(v) => attrs.push(("value", @luna.attr_static(v)))
    None => ()
  }

  match size {
    Some(s) => attrs.push(("size", @luna.attr_static(s.to_string())))
    None => ()
  }

  match help_text {
    Some(h) => attrs.push(("help-text", @luna.attr_static(h)))
    None => ()
  }

  match pattern {
    Some(p) => attrs.push(("pattern", @luna.attr_static(p)))
    None => ()
  }

  // Boolean attributes
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }

  match readonly_ {
    Some(true) => attrs.push(("readonly", @luna.attr_static("")))
    _ => ()
  }

  match required {
    Some(true) => attrs.push(("required", @luna.attr_static("")))
    _ => ()
  }

  match clearable {
    Some(true) => attrs.push(("clearable", @luna.attr_static("")))
    _ => ()
  }

  match password_toggle {
    Some(true) => attrs.push(("password-toggle", @luna.attr_static("")))
    _ => ()
  }

  // Number attributes
  match minlength {
    Some(n) => attrs.push(("minlength", @luna.attr_static(n.to_string())))
    None => ()
  }

  match maxlength {
    Some(n) => attrs.push(("maxlength", @luna.attr_static(n.to_string())))
    None => ()
  }

  @luna.h("sl-input", attrs, [])
}
