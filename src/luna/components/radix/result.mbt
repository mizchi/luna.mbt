///|
/// Result component for Luna (Headless)
/// Operation result display (success/error/info pages)

///|
/// Result status enum
pub enum ResultStatus {
  Success
  Error
  Info
  Warning
  NotFound
}

///|
/// Create a headless result root
/// Outputs: <div class="radix-result" data-status="...">children</div>
pub fn radix_result(
  status : ResultStatus,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let status_str = match status {
    Success => "success"
    Error => "error"
    Info => "info"
    Warning => "warning"
    NotFound => "not-found"
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-result")),
      ("data-status", @luna.attr_static(status_str)),
    ],
    children,
  )
}

///|
/// Create a headless result icon
/// Outputs: <div class="radix-result-icon">children</div>
pub fn radix_result_icon(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-result-icon"))], children)
}

///|
/// Create a headless result title
/// Outputs: <h2 class="radix-result-title">children</h2>
pub fn radix_result_title(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("h2", [("class", @luna.attr_static("radix-result-title"))], children)
}

///|
/// Create a headless result subtitle
/// Outputs: <p class="radix-result-subtitle">children</p>
pub fn radix_result_subtitle(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "p",
    [("class", @luna.attr_static("radix-result-subtitle"))],
    children,
  )
}

///|
/// Create a headless result extra content (actions)
/// Outputs: <div class="radix-result-extra">children</div>
pub fn radix_result_extra(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-result-extra"))], children)
}

///|
/// Create a headless result content
/// Outputs: <div class="radix-result-content">children</div>
pub fn radix_result_content(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-result-content"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the result component
fn result_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.result {
    #|  display: flex;
    #|  flex-direction: column;
    #|  align-items: center;
    #|  padding: 3rem 1.5rem;
    #|  text-align: center;
    #|}
    #|
    #|.result-icon {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 4rem;
    #|  height: 4rem;
    #|  margin-bottom: 1.5rem;
    #|  border-radius: 50%;
    #|}
    #|
    #|.result[data-status="success"] .result-icon {
    #|  background: #dcfce7;
    #|  color: #22c55e;
    #|}
    #|
    #|.result[data-status="error"] .result-icon {
    #|  background: #fee2e2;
    #|  color: #ef4444;
    #|}
    #|
    #|.result[data-status="info"] .result-icon {
    #|  background: #dbeafe;
    #|  color: #3b82f6;
    #|}
    #|
    #|.result[data-status="warning"] .result-icon {
    #|  background: #fef3c7;
    #|  color: #f59e0b;
    #|}
    #|
    #|.result[data-status="not-found"] .result-icon {
    #|  background: #f4f4f5;
    #|  color: #71717a;
    #|}
    #|
    #|.result-title {
    #|  margin: 0 0 0.5rem;
    #|  font-size: 1.5rem;
    #|  font-weight: 600;
    #|  color: #18181b;
    #|}
    #|
    #|.result-subtitle {
    #|  margin: 0 0 1.5rem;
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|  max-width: 24rem;
    #|}
    #|
    #|.result-extra {
    #|  display: flex;
    #|  gap: 0.75rem;
    #|  margin-bottom: 1.5rem;
    #|}
    #|
    #|.result-content {
    #|  width: 100%;
    #|  max-width: 32rem;
    #|  text-align: left;
    #|}
  css
}

///|
/// Create a styled result with Declarative Shadow DOM
pub fn radix_result_styled(
  status : ResultStatus,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let status_str = match status {
    Success => "success"
    Error => "error"
    Info => "info"
    Warning => "warning"
    NotFound => "not-found"
  }
  let css = match styles {
    Some(s) => s
    None => result_styles()
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
    "radix-result",
    [("data-status", @luna.attr_static(status_str))],
    all_children,
  )
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a result with luna/css atomic styles
pub fn radix_result_ucss(
  status : ResultStatus,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let status_str = match status {
    Success => "success"
    Error => "error"
    Info => "info"
    Warning => "warning"
    NotFound => "not-found"
  }
  let class_names = result_base_styles()
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
/// Create a result icon with luna/css atomic styles
pub fn radix_result_icon_ucss(
  status : ResultStatus,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = result_icon_styles(status)
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a result title with luna/css atomic styles
pub fn radix_result_title_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = result_title_styles()
  @luna.h("h2", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a result subtitle with luna/css atomic styles
pub fn radix_result_subtitle_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = result_subtitle_styles()
  @luna.h("p", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a result extra with luna/css atomic styles
pub fn radix_result_extra_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = result_extra_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}
