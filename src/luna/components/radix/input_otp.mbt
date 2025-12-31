///|
/// Radix-style InputOTP component for Luna (Headless)
/// One-time password input with individual character boxes

///|
/// Create a headless input OTP root
/// Outputs: <div class="radix-input-otp" data-length="...">children</div>
pub fn radix_input_otp(
  length? : Int,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let len = match length {
    Some(l) => l
    None => 6
  }

  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-input-otp")),
      ("data-length", @luna.attr_static(len.to_string())),
    ],
    children,
  )
}

///|
/// Create a headless input OTP group
/// Outputs: <div class="radix-input-otp-group">children</div>
pub fn radix_input_otp_group(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-input-otp-group"))],
    children,
  )
}

///|
/// Create a headless input OTP slot
/// Outputs: <div class="radix-input-otp-slot" data-index="...">value</div>
pub fn radix_input_otp_slot(
  index : Int,
  value? : String,
  active? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_active = match active {
    Some(true) => true
    _ => false
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-input-otp-slot")),
    ("data-index", @luna.attr_static(index.to_string())),
  ]

  if is_active {
    attrs.push(("data-active", @luna.attr_static("")))
  }

  match value {
    Some(v) => attrs.push(("data-value", @luna.attr_static(v)))
    None => ()
  }

  @luna.h("div", attrs, children)
}

///|
/// Create a headless input OTP separator
/// Outputs: <div class="radix-input-otp-separator">-</div>
pub fn radix_input_otp_separator() -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-input-otp-separator"))],
    [@luna.text("-")],
  )
}

///|
/// Create a headless hidden input for form submission
/// Outputs: <input type="hidden" name="..." value="..." />
pub fn radix_input_otp_hidden(
  name? : String,
  value? : String,
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("type", @luna.attr_static("hidden")),
  ]

  match name {
    Some(n) => attrs.push(("name", @luna.attr_static(n)))
    None => ()
  }

  match value {
    Some(v) => attrs.push(("value", @luna.attr_static(v)))
    None => ()
  }

  @luna.h("input", attrs, [])
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the input OTP component
fn input_otp_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|}
    #|
    #|.input-otp {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|}
    #|
    #|.input-otp-group {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.25rem;
    #|}
    #|
    #|.input-otp-slot {
    #|  position: relative;
    #|  width: 2.5rem;
    #|  height: 2.5rem;
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  font-size: 1.125rem;
    #|  font-weight: 500;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 6px;
    #|  background: white;
    #|  transition: border-color 0.15s ease, box-shadow 0.15s ease;
    #|}
    #|
    #|.input-otp-slot:first-child {
    #|  border-top-left-radius: 6px;
    #|  border-bottom-left-radius: 6px;
    #|}
    #|
    #|.input-otp-slot:last-child {
    #|  border-top-right-radius: 6px;
    #|  border-bottom-right-radius: 6px;
    #|}
    #|
    #|.input-otp-slot[data-active] {
    #|  border-color: #18181b;
    #|  box-shadow: 0 0 0 1px #18181b;
    #|}
    #|
    #|.input-otp-slot[data-active]::after {
    #|  content: '';
    #|  position: absolute;
    #|  bottom: 0.5rem;
    #|  left: 50%;
    #|  transform: translateX(-50%);
    #|  width: 0.5rem;
    #|  height: 2px;
    #|  background: #18181b;
    #|  animation: blink 1s infinite;
    #|}
    #|
    #|@keyframes blink {
    #|  0%, 50% { opacity: 1; }
    #|  51%, 100% { opacity: 0; }
    #|}
    #|
    #|.input-otp-separator {
    #|  color: #a1a1aa;
    #|  font-size: 1.25rem;
    #|}
  css
}

///|
/// Create a styled input OTP with Declarative Shadow DOM
pub fn radix_input_otp_styled(
  length? : Int,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let len = match length {
    Some(l) => l
    None => 6
  }

  let css = match styles {
    Some(s) => s
    None => input_otp_styles()
  }

  // Build template content
  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("slot", [], []),
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

  @luna.h(
    "radix-input-otp",
    [("data-length", @luna.attr_static(len.to_string()))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create an input OTP with luna/css atomic styles
pub fn radix_input_otp_ucss(
  length? : Int,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let len = match length {
    Some(l) => l
    None => 6
  }

  let class_names = input_otp_base_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-length", @luna.attr_static(len.to_string())),
    ],
    children,
  )
}

///|
/// Create an input OTP group with luna/css atomic styles
pub fn radix_input_otp_group_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = input_otp_group_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create an input OTP slot with luna/css atomic styles
pub fn radix_input_otp_slot_ucss(
  index : Int,
  value? : String,
  active? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_active = match active {
    Some(true) => true
    _ => false
  }

  let mut class_names = input_otp_slot_styles()

  if is_active {
    class_names = class_names +
      " " +
      @css.styles([("border-color", "#18181b"), ("box-shadow", "0 0 0 1px #18181b")])
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("data-index", @luna.attr_static(index.to_string())),
  ]

  if is_active {
    attrs.push(("data-active", @luna.attr_static("")))
  }

  match value {
    Some(v) => attrs.push(("data-value", @luna.attr_static(v)))
    None => ()
  }

  @luna.h("div", attrs, children)
}

///|
/// Create an input OTP separator with luna/css atomic styles
pub fn radix_input_otp_separator_ucss() -> @luna.Node[Unit] {
  let class_names = input_otp_separator_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], [@luna.text("-")])
}
