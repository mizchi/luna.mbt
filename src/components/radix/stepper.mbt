///|
/// Stepper component for Luna (Headless)
/// Multi-step wizard/progress indicator

///|
/// Stepper orientation enum
pub enum StepperOrientation {
  Horizontal
  Vertical
}

///|
/// Step status enum
pub enum StepStatus {
  Completed
  Current
  Upcoming
}

///|
/// Create a headless stepper root
/// Outputs: <div class="radix-stepper" data-orientation="...">children</div>
pub fn radix_stepper(
  orientation? : StepperOrientation,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(Vertical) => "vertical"
    _ => "horizontal"
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-stepper")),
      ("data-orientation", @luna.attr_static(orient)),
    ],
    children,
  )
}

///|
/// Create a headless stepper item
/// Outputs: <div class="radix-stepper-item" data-status="...">children</div>
pub fn radix_stepper_item(
  status? : StepStatus,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let status_str = match status {
    Some(Completed) => "completed"
    Some(Current) => "current"
    _ => "upcoming"
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-stepper-item")),
      ("data-status", @luna.attr_static(status_str)),
    ],
    children,
  )
}

///|
/// Create a headless stepper trigger (clickable step indicator)
/// Outputs: <button class="radix-stepper-trigger">children</button>
pub fn radix_stepper_trigger(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-stepper-trigger")),
  ]
  match disabled {
    Some(true) => {
      attrs.push(("disabled", @luna.attr_static("")))
      attrs.push(("data-disabled", @luna.attr_static("")))
    }
    _ => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a headless stepper indicator (step number/icon)
/// Outputs: <div class="radix-stepper-indicator">children</div>
pub fn radix_stepper_indicator(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-stepper-indicator"))],
    children,
  )
}

///|
/// Create a headless stepper title
/// Outputs: <div class="radix-stepper-title">children</div>
pub fn radix_stepper_title(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-stepper-title"))],
    children,
  )
}

///|
/// Create a headless stepper description
/// Outputs: <div class="radix-stepper-description">children</div>
pub fn radix_stepper_description(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-stepper-description"))],
    children,
  )
}

///|
/// Create a headless stepper separator
/// Outputs: <div class="radix-stepper-separator"></div>
pub fn radix_stepper_separator() -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-stepper-separator"))], [])
}

///|
/// Create a headless stepper content (step panel)
/// Outputs: <div class="radix-stepper-content">children</div>
pub fn radix_stepper_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-stepper-content"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the stepper component
fn stepper_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.stepper[data-orientation="horizontal"] {
    #|  display: flex;
    #|  align-items: flex-start;
    #|}
    #|
    #|.stepper[data-orientation="vertical"] {
    #|  display: flex;
    #|  flex-direction: column;
    #|}
    #|
    #|.stepper-item {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|}
    #|
    #|[data-orientation="vertical"] .stepper-item {
    #|  flex-direction: column;
    #|  align-items: flex-start;
    #|}
    #|
    #|.stepper-trigger {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.75rem;
    #|  background: transparent;
    #|  border: none;
    #|  cursor: pointer;
    #|  padding: 0;
    #|}
    #|
    #|.stepper-trigger[data-disabled] {
    #|  cursor: not-allowed;
    #|  opacity: 0.5;
    #|}
    #|
    #|.stepper-indicator {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 2rem;
    #|  height: 2rem;
    #|  border-radius: 50%;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  background: #e4e4e7;
    #|  color: #71717a;
    #|  flex-shrink: 0;
    #|}
    #|
    #|[data-status="current"] .stepper-indicator {
    #|  background: #18181b;
    #|  color: white;
    #|}
    #|
    #|[data-status="completed"] .stepper-indicator {
    #|  background: #22c55e;
    #|  color: white;
    #|}
    #|
    #|.stepper-title {
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  color: #71717a;
    #|}
    #|
    #|[data-status="current"] .stepper-title,
    #|[data-status="completed"] .stepper-title {
    #|  color: #18181b;
    #|}
    #|
    #|.stepper-description {
    #|  font-size: 0.75rem;
    #|  color: #a1a1aa;
    #|}
    #|
    #|.stepper-separator {
    #|  flex: 1;
    #|  height: 2px;
    #|  min-width: 2rem;
    #|  background: #e4e4e7;
    #|  margin: 0 0.5rem;
    #|}
    #|
    #|[data-orientation="vertical"] .stepper-separator {
    #|  width: 2px;
    #|  height: 2rem;
    #|  min-width: 0;
    #|  margin: 0.5rem 0 0.5rem 1rem;
    #|}
    #|
    #|[data-status="completed"] + .stepper-separator {
    #|  background: #22c55e;
    #|}
    #|
    #|.stepper-content {
    #|  padding: 1rem 0;
    #|}
  css
}

///|
/// Create a styled stepper with Declarative Shadow DOM
pub fn radix_stepper_styled(
  orientation? : StepperOrientation,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(Vertical) => "vertical"
    _ => "horizontal"
  }
  let css = match styles {
    Some(s) => s
    None => stepper_styles()
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
    "radix-stepper",
    [("data-orientation", @luna.attr_static(orient))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a stepper with luna/css atomic styles
pub fn radix_stepper_ucss(
  orientation? : StepperOrientation,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let orient = match orientation {
    Some(Vertical) => "vertical"
    _ => "horizontal"
  }
  let class_names = stepper_base_styles(orientation)
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-orientation", @luna.attr_static(orient)),
    ],
    children,
  )
}

///|
/// Create a stepper item with luna/css atomic styles
pub fn radix_stepper_item_ucss(
  status? : StepStatus,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let status_str = match status {
    Some(Completed) => "completed"
    Some(Current) => "current"
    _ => "upcoming"
  }
  let class_names = stepper_item_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-status", @luna.attr_static(status_str)),
    ],
    children,
  )
}

///|
/// Create a stepper indicator with luna/css atomic styles
pub fn radix_stepper_indicator_ucss(
  status? : StepStatus,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = stepper_indicator_styles(status)
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a stepper separator with luna/css atomic styles
pub fn radix_stepper_separator_ucss(completed? : Bool) -> @luna.Node[Unit] {
  let class_names = stepper_separator_styles(completed)
  @luna.h("div", [("class", @luna.attr_static(class_names))], [])
}
