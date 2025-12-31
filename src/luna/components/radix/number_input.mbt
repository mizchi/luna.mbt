///|
/// NumberInput component for Luna (Headless)
/// Number input with increment/decrement buttons

///|
/// NumberInput size enum
pub enum NumberInputSize {
  Sm
  Md
  Lg
}

///|
/// Create a headless number input root
/// Outputs: <div class="radix-number-input">children</div>
pub fn radix_number_input(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-number-input")),
  ]
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless number input field
/// Outputs: <input class="radix-number-input-field" type="number" />
pub fn radix_number_input_field(
  value? : String,
  min? : String,
  max? : String,
  step? : String,
  placeholder? : String,
  disabled? : Bool,
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-number-input-field")),
    ("type", @luna.attr_static("number")),
  ]
  match value {
    Some(v) => attrs.push(("value", @luna.attr_static(v)))
    None => ()
  }
  match min {
    Some(m) => attrs.push(("min", @luna.attr_static(m)))
    None => ()
  }
  match max {
    Some(m) => attrs.push(("max", @luna.attr_static(m)))
    None => ()
  }
  match step {
    Some(s) => attrs.push(("step", @luna.attr_static(s)))
    None => ()
  }
  match placeholder {
    Some(p) => attrs.push(("placeholder", @luna.attr_static(p)))
    None => ()
  }
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("input", attrs, [])
}

///|
/// Create a headless number input increment button
/// Outputs: <button class="radix-number-input-increment">children</button>
pub fn radix_number_input_increment(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-number-input-increment")),
    ("type", @luna.attr_static("button")),
    ("aria-label", @luna.attr_static("Increment")),
  ]
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a headless number input decrement button
/// Outputs: <button class="radix-number-input-decrement">children</button>
pub fn radix_number_input_decrement(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-number-input-decrement")),
    ("type", @luna.attr_static("button")),
    ("aria-label", @luna.attr_static("Decrement")),
  ]
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("button", attrs, children)
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the number input component
fn number_input_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-flex;
    #|}
    #|
    #|.number-input {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  overflow: hidden;
    #|}
    #|
    #|.number-input[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.number-input-field {
    #|  width: 4rem;
    #|  padding: 0.5rem;
    #|  border: none;
    #|  text-align: center;
    #|  font-size: 0.875rem;
    #|  background: transparent;
    #|  -moz-appearance: textfield;
    #|}
    #|
    #|.number-input-field::-webkit-outer-spin-button,
    #|.number-input-field::-webkit-inner-spin-button {
    #|  -webkit-appearance: none;
    #|  margin: 0;
    #|}
    #|
    #|.number-input-field:focus {
    #|  outline: none;
    #|}
    #|
    #|.number-input-increment,
    #|.number-input-decrement {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 2rem;
    #|  height: 2.25rem;
    #|  padding: 0;
    #|  background: #f4f4f5;
    #|  border: none;
    #|  cursor: pointer;
    #|  color: #71717a;
    #|  transition: background 0.15s ease, color 0.15s ease;
    #|}
    #|
    #|.number-input-increment:hover:not(:disabled),
    #|.number-input-decrement:hover:not(:disabled) {
    #|  background: #e4e4e7;
    #|  color: #18181b;
    #|}
    #|
    #|.number-input-increment:disabled,
    #|.number-input-decrement:disabled {
    #|  cursor: not-allowed;
    #|  opacity: 0.5;
    #|}
  css
}

///|
/// Create a styled number input with Declarative Shadow DOM
pub fn radix_number_input_styled(
  disabled? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => number_input_styles()
  }
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("slot", [], []),
  ]
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
  let attrs : Array[(String, @luna.Attr[Unit])] = []
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("radix-number-input", attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a number input with luna/css atomic styles
pub fn radix_number_input_ucss(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = number_input_base_styles()
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
  ]
  match disabled {
    Some(true) => attrs.push(("data-disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a number input field with luna/css atomic styles
pub fn radix_number_input_field_ucss(
  value? : String,
  min? : String,
  max? : String,
  step? : String,
  placeholder? : String,
  disabled? : Bool,
) -> @luna.Node[Unit] {
  let class_names = number_input_field_styles()
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("type", @luna.attr_static("number")),
  ]
  match value {
    Some(v) => attrs.push(("value", @luna.attr_static(v)))
    None => ()
  }
  match min {
    Some(m) => attrs.push(("min", @luna.attr_static(m)))
    None => ()
  }
  match max {
    Some(m) => attrs.push(("max", @luna.attr_static(m)))
    None => ()
  }
  match step {
    Some(s) => attrs.push(("step", @luna.attr_static(s)))
    None => ()
  }
  match placeholder {
    Some(p) => attrs.push(("placeholder", @luna.attr_static(p)))
    None => ()
  }
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("input", attrs, [])
}

///|
/// Create a number input button with luna/css atomic styles
pub fn radix_number_input_button_ucss(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = number_input_button_styles()
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("type", @luna.attr_static("button")),
  ]
  match disabled {
    Some(true) => attrs.push(("disabled", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("button", attrs, children)
}
