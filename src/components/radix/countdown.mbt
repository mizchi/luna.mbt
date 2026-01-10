///|
/// Countdown component for Luna (Headless)
/// Countdown timer display

///|
/// Create a headless countdown root
/// Outputs: <div class="radix-countdown">children</div>
pub fn radix_countdown(
  finished? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-countdown")),
  ]
  match finished {
    Some(true) => attrs.push(("data-finished", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a headless countdown segment (days/hours/minutes/seconds)
/// Outputs: <div class="radix-countdown-segment" data-type="...">children</div>
pub fn radix_countdown_segment(
  segment_type : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-countdown-segment")),
      ("data-type", @luna.attr_static(segment_type)),
    ],
    children,
  )
}

///|
/// Create a headless countdown value
/// Outputs: <span class="radix-countdown-value">value</span>
pub fn radix_countdown_value(value : String) -> @luna.Node[Unit] {
  @luna.h("span", [("class", @luna.attr_static("radix-countdown-value"))], [
    @luna.text(value),
  ])
}

///|
/// Create a headless countdown label
/// Outputs: <span class="radix-countdown-label">label</span>
pub fn radix_countdown_label(label : String) -> @luna.Node[Unit] {
  @luna.h("span", [("class", @luna.attr_static("radix-countdown-label"))], [
    @luna.text(label),
  ])
}

///|
/// Create a headless countdown separator
/// Outputs: <span class="radix-countdown-separator">:</span>
pub fn radix_countdown_separator() -> @luna.Node[Unit] {
  @luna.h("span", [("class", @luna.attr_static("radix-countdown-separator"))], [
    @luna.text(":"),
  ])
}

///|
/// Create a headless countdown finished content
/// Outputs: <div class="radix-countdown-finished">children</div>
pub fn radix_countdown_finished(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-countdown-finished"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the countdown component
fn countdown_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|}
    #|
    #|.countdown {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  gap: 0.5rem;
    #|}
    #|
    #|.countdown-segment {
    #|  display: flex;
    #|  flex-direction: column;
    #|  align-items: center;
    #|  min-width: 3rem;
    #|}
    #|
    #|.countdown-value {
    #|  font-size: 2rem;
    #|  font-weight: 700;
    #|  line-height: 1;
    #|  color: #18181b;
    #|  font-variant-numeric: tabular-nums;
    #|}
    #|
    #|.countdown-label {
    #|  font-size: 0.75rem;
    #|  color: #71717a;
    #|  text-transform: uppercase;
    #|  letter-spacing: 0.05em;
    #|  margin-top: 0.25rem;
    #|}
    #|
    #|.countdown-separator {
    #|  font-size: 2rem;
    #|  font-weight: 700;
    #|  color: #71717a;
    #|  line-height: 1;
    #|}
    #|
    #|.countdown[data-finished] .countdown-segment,
    #|.countdown[data-finished] .countdown-separator {
    #|  display: none;
    #|}
    #|
    #|.countdown:not([data-finished]) .countdown-finished {
    #|  display: none;
    #|}
    #|
    #|.countdown-finished {
    #|  font-size: 1.5rem;
    #|  font-weight: 600;
    #|  color: #18181b;
    #|}
  css
}

///|
/// Create a styled countdown with Declarative Shadow DOM
pub fn radix_countdown_styled(
  finished? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => countdown_styles()
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
  match finished {
    Some(true) => attrs.push(("data-finished", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("radix-countdown", attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a countdown with luna/css atomic styles
pub fn radix_countdown_ucss(
  finished? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = countdown_base_styles()
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
  ]
  match finished {
    Some(true) => attrs.push(("data-finished", @luna.attr_static("")))
    _ => ()
  }
  @luna.h("div", attrs, children)
}

///|
/// Create a countdown segment with luna/css atomic styles
pub fn radix_countdown_segment_ucss(
  segment_type : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = countdown_segment_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-type", @luna.attr_static(segment_type)),
    ],
    children,
  )
}

///|
/// Create a countdown value with luna/css atomic styles
pub fn radix_countdown_value_ucss(value : String) -> @luna.Node[Unit] {
  let class_names = countdown_value_styles()
  @luna.h("span", [("class", @luna.attr_static(class_names))], [
    @luna.text(value),
  ])
}

///|
/// Create a countdown label with luna/css atomic styles
pub fn radix_countdown_label_ucss(label : String) -> @luna.Node[Unit] {
  let class_names = countdown_label_styles()
  @luna.h("span", [("class", @luna.attr_static(class_names))], [
    @luna.text(label),
  ])
}

///|
/// Create a countdown separator with luna/css atomic styles
pub fn radix_countdown_separator_ucss() -> @luna.Node[Unit] {
  let class_names = countdown_separator_styles()
  @luna.h("span", [("class", @luna.attr_static(class_names))], [@luna.text(":")])
}
