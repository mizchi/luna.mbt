///|
/// Timeline component for Luna (Headless)
/// Vertical timeline display for events/history

///|
/// Create a headless timeline root
/// Outputs: <div class="radix-timeline">children</div>
pub fn radix_timeline(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-timeline"))], children)
}

///|
/// Create a headless timeline item
/// Outputs: <div class="radix-timeline-item">children</div>
pub fn radix_timeline_item(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-timeline-item"))],
    children,
  )
}

///|
/// Create a headless timeline connector (the line between items)
/// Outputs: <div class="radix-timeline-connector"></div>
pub fn radix_timeline_connector() -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-timeline-connector"))],
    [],
  )
}

///|
/// Create a headless timeline dot
/// Outputs: <div class="radix-timeline-dot">children</div>
pub fn radix_timeline_dot(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-timeline-dot"))], children)
}

///|
/// Create a headless timeline content
/// Outputs: <div class="radix-timeline-content">children</div>
pub fn radix_timeline_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-timeline-content"))],
    children,
  )
}

///|
/// Create a headless timeline time
/// Outputs: <time class="radix-timeline-time">children</time>
pub fn radix_timeline_time(
  datetime? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-timeline-time")),
  ]

  match datetime {
    Some(dt) => attrs.push(("datetime", @luna.attr_static(dt)))
    None => ()
  }

  @luna.h("time", attrs, children)
}

///|
/// Create a headless timeline title
/// Outputs: <h3 class="radix-timeline-title">children</h3>
pub fn radix_timeline_title(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "h3",
    [("class", @luna.attr_static("radix-timeline-title"))],
    children,
  )
}

///|
/// Create a headless timeline description
/// Outputs: <p class="radix-timeline-description">children</p>
pub fn radix_timeline_description(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "p",
    [("class", @luna.attr_static("radix-timeline-description"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the timeline component
fn timeline_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.timeline {
    #|  position: relative;
    #|  padding-left: 2rem;
    #|}
    #|
    #|.timeline-item {
    #|  position: relative;
    #|  padding-bottom: 1.5rem;
    #|}
    #|
    #|.timeline-item:last-child {
    #|  padding-bottom: 0;
    #|}
    #|
    #|.timeline-connector {
    #|  position: absolute;
    #|  left: -1.5rem;
    #|  top: 1.5rem;
    #|  bottom: 0;
    #|  width: 2px;
    #|  background: #e4e4e7;
    #|}
    #|
    #|.timeline-item:last-child .timeline-connector {
    #|  display: none;
    #|}
    #|
    #|.timeline-dot {
    #|  position: absolute;
    #|  left: -2rem;
    #|  top: 0;
    #|  width: 1rem;
    #|  height: 1rem;
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  background: white;
    #|  border: 2px solid #e4e4e7;
    #|  border-radius: 50%;
    #|}
    #|
    #|.timeline-dot:empty {
    #|  background: #18181b;
    #|  border-color: #18181b;
    #|}
    #|
    #|.timeline-content {
    #|  padding-left: 0.5rem;
    #|}
    #|
    #|.timeline-time {
    #|  display: block;
    #|  font-size: 0.75rem;
    #|  color: #71717a;
    #|  margin-bottom: 0.25rem;
    #|}
    #|
    #|.timeline-title {
    #|  font-size: 0.875rem;
    #|  font-weight: 600;
    #|  color: #18181b;
    #|  margin: 0 0 0.25rem 0;
    #|}
    #|
    #|.timeline-description {
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|  margin: 0;
    #|  line-height: 1.5;
    #|}
  css
}

///|
/// Create a styled timeline with Declarative Shadow DOM
pub fn radix_timeline_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => timeline_styles()
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

  @luna.h("radix-timeline", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a timeline with luna/css atomic styles
pub fn radix_timeline_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = timeline_base_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a timeline item with luna/css atomic styles
pub fn radix_timeline_item_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = timeline_item_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a timeline dot with luna/css atomic styles
pub fn radix_timeline_dot_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = timeline_dot_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a timeline content with luna/css atomic styles
pub fn radix_timeline_content_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = timeline_content_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
