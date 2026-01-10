///|
/// Spinner/Loading component for Luna (Headless)
/// Loading indicators and spinners

///|
/// Spinner size enum
pub enum SpinnerSize {
  Sm
  Md
  Lg
  Xl
}

///|
/// Create a headless spinner
/// Outputs: <div class="radix-spinner" role="status" data-size="...">children</div>
pub fn radix_spinner(
  size? : SpinnerSize,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let size_str = match size {
    Some(Sm) => "sm"
    Some(Lg) => "lg"
    Some(Xl) => "xl"
    _ => "md"
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-spinner")),
      ("role", @luna.attr_static("status")),
      ("aria-label", @luna.attr_static("Loading")),
      ("data-size", @luna.attr_static(size_str)),
    ],
    children,
  )
}

///|
/// Create a headless loading wrapper
/// Outputs: <div class="radix-loading" data-loading="...">children</div>
pub fn radix_loading(
  loading? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_loading = match loading {
    Some(true) => true
    _ => false
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-loading")),
      (
        "data-loading",
        @luna.attr_static(if is_loading { "true" } else { "false" }),
      ),
    ],
    children,
  )
}

///|
/// Create a headless loading overlay
/// Outputs: <div class="radix-loading-overlay">children</div>
pub fn radix_loading_overlay(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-loading-overlay"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the spinner component
fn spinner_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|}
    #|
    #|.spinner {
    #|  display: inline-block;
    #|  border-radius: 50%;
    #|  border: 2px solid #e4e4e7;
    #|  border-top-color: #18181b;
    #|  animation: spin 0.6s linear infinite;
    #|}
    #|
    #|.spinner[data-size="sm"] {
    #|  width: 1rem;
    #|  height: 1rem;
    #|  border-width: 2px;
    #|}
    #|
    #|.spinner[data-size="md"] {
    #|  width: 1.5rem;
    #|  height: 1.5rem;
    #|  border-width: 2px;
    #|}
    #|
    #|.spinner[data-size="lg"] {
    #|  width: 2rem;
    #|  height: 2rem;
    #|  border-width: 3px;
    #|}
    #|
    #|.spinner[data-size="xl"] {
    #|  width: 3rem;
    #|  height: 3rem;
    #|  border-width: 4px;
    #|}
    #|
    #|@keyframes spin {
    #|  to { transform: rotate(360deg); }
    #|}
    #|
    #|.loading {
    #|  position: relative;
    #|}
    #|
    #|.loading[data-loading="true"] {
    #|  pointer-events: none;
    #|}
    #|
    #|.loading-overlay {
    #|  position: absolute;
    #|  inset: 0;
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  background: rgba(255, 255, 255, 0.8);
    #|  z-index: 10;
    #|}
  css
}

///|
/// Create a styled spinner with Declarative Shadow DOM
pub fn radix_spinner_styled(
  size? : SpinnerSize,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let size_str = match size {
    Some(Sm) => "sm"
    Some(Lg) => "lg"
    Some(Xl) => "xl"
    _ => "md"
  }
  let css = match styles {
    Some(s) => s
    None => spinner_styles()
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
  @luna.h(
    "radix-spinner",
    [
      ("role", @luna.attr_static("status")),
      ("data-size", @luna.attr_static(size_str)),
    ],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a spinner with luna/css atomic styles
pub fn radix_spinner_ucss(size? : SpinnerSize) -> @luna.Node[Unit] {
  let size_str = match size {
    Some(Sm) => "sm"
    Some(Lg) => "lg"
    Some(Xl) => "xl"
    _ => "md"
  }
  let class_names = spinner_base_styles(size)
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("status")),
      ("aria-label", @luna.attr_static("Loading")),
      ("data-size", @luna.attr_static(size_str)),
    ],
    [],
  )
}

///|
/// Create a loading wrapper with luna/css atomic styles
pub fn radix_loading_ucss(
  loading? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_loading = match loading {
    Some(true) => true
    _ => false
  }
  let class_names = loading_wrapper_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      (
        "data-loading",
        @luna.attr_static(if is_loading { "true" } else { "false" }),
      ),
    ],
    children,
  )
}

///|
/// Create a loading overlay with luna/css atomic styles
pub fn radix_loading_overlay_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = loading_overlay_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
