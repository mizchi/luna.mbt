///|
/// Shoelace Switch component for Luna
/// Generates sl-switch custom element for both CSR and SSR

///|
/// Create an sl-switch element
/// Returns a VNode that renders to <sl-switch> custom element
pub fn sl_switch(
  checked? : Bool,
  disabled? : Bool,
  required? : Bool,
  size? : SlSize,
  help_text? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = []

  // Boolean attributes
  match checked {
    Some(true) => attrs.push(("checked", @luna.attr_static("")))
    _ => ()
  }
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }
  match required {
    Some(true) => attrs.push(("required", @luna.attr_static("")))
    _ => ()
  }

  // Size attribute
  match size {
    Some(s) => attrs.push(("size", @luna.attr_static(s.to_string())))
    None => ()
  }

  // Help text
  match help_text {
    Some(h) => attrs.push(("help-text", @luna.attr_static(h)))
    None => ()
  }
  @luna.h("sl-switch", attrs, children)
}
