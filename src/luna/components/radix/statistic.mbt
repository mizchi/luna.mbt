///|
/// Statistic component for Luna (Headless)
/// Display statistics with label, value, and optional trend

///|
/// Statistic trend direction
pub enum StatisticTrend {
  Up
  Down
  Neutral
}

///|
/// Create a headless statistic root
/// Outputs: <div class="radix-statistic">children</div>
pub fn radix_statistic(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-statistic"))], children)
}

///|
/// Create a headless statistic label
/// Outputs: <div class="radix-statistic-label">children</div>
pub fn radix_statistic_label(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-statistic-label"))],
    children,
  )
}

///|
/// Create a headless statistic value
/// Outputs: <div class="radix-statistic-value">children</div>
pub fn radix_statistic_value(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-statistic-value"))],
    children,
  )
}

///|
/// Create a headless statistic prefix
/// Outputs: <span class="radix-statistic-prefix">children</span>
pub fn radix_statistic_prefix(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [("class", @luna.attr_static("radix-statistic-prefix"))],
    children,
  )
}

///|
/// Create a headless statistic suffix
/// Outputs: <span class="radix-statistic-suffix">children</span>
pub fn radix_statistic_suffix(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "span",
    [("class", @luna.attr_static("radix-statistic-suffix"))],
    children,
  )
}

///|
/// Create a headless statistic trend indicator
/// Outputs: <div class="radix-statistic-trend" data-trend="...">children</div>
pub fn radix_statistic_trend(
  trend : StatisticTrend,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let trend_str = match trend {
    Up => "up"
    Down => "down"
    Neutral => "neutral"
  }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-statistic-trend")),
      ("data-trend", @luna.attr_static(trend_str)),
    ],
    children,
  )
}

///|
/// Create a headless statistic description/help text
/// Outputs: <div class="radix-statistic-description">children</div>
pub fn radix_statistic_description(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-statistic-description"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the statistic component
fn statistic_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.statistic {
    #|  display: flex;
    #|  flex-direction: column;
    #|  gap: 0.25rem;
    #|}
    #|
    #|.statistic-label {
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|}
    #|
    #|.statistic-value {
    #|  display: flex;
    #|  align-items: baseline;
    #|  gap: 0.25rem;
    #|  font-size: 2rem;
    #|  font-weight: 600;
    #|  color: #18181b;
    #|  line-height: 1;
    #|}
    #|
    #|.statistic-prefix,
    #|.statistic-suffix {
    #|  font-size: 1rem;
    #|  font-weight: 400;
    #|  color: #71717a;
    #|}
    #|
    #|.statistic-trend {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  gap: 0.25rem;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|}
    #|
    #|.statistic-trend[data-trend="up"] {
    #|  color: #22c55e;
    #|}
    #|
    #|.statistic-trend[data-trend="down"] {
    #|  color: #ef4444;
    #|}
    #|
    #|.statistic-trend[data-trend="neutral"] {
    #|  color: #71717a;
    #|}
    #|
    #|.statistic-description {
    #|  font-size: 0.75rem;
    #|  color: #a1a1aa;
    #|}
  css
}

///|
/// Create a styled statistic with Declarative Shadow DOM
pub fn radix_statistic_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => statistic_styles()
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
  @luna.h("radix-statistic", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a statistic with luna/css atomic styles
pub fn radix_statistic_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = statistic_base_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a statistic label with luna/css atomic styles
pub fn radix_statistic_label_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = statistic_label_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a statistic value with luna/css atomic styles
pub fn radix_statistic_value_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = statistic_value_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a statistic trend with luna/css atomic styles
pub fn radix_statistic_trend_ucss(
  trend : StatisticTrend,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let trend_str = match trend {
    Up => "up"
    Down => "down"
    Neutral => "neutral"
  }
  let class_names = statistic_trend_styles(trend)
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("data-trend", @luna.attr_static(trend_str)),
    ],
    children,
  )
}
