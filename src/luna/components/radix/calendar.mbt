///|
/// Radix-style Calendar component for Luna (Headless)
/// Date picker calendar

///|
/// Create a headless calendar root
/// Outputs: <div class="radix-calendar">children</div>
pub fn radix_calendar(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-calendar"))], children)
}

///|
/// Create a headless calendar header
/// Outputs: <div class="radix-calendar-header">children</div>
pub fn radix_calendar_header(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-calendar-header"))],
    children,
  )
}

///|
/// Create a headless calendar title (month/year)
/// Outputs: <div class="radix-calendar-title">children</div>
pub fn radix_calendar_title(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-calendar-title"))],
    children,
  )
}

///|
/// Create a headless calendar nav buttons container
/// Outputs: <div class="radix-calendar-nav">children</div>
pub fn radix_calendar_nav(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-calendar-nav"))], children)
}

///|
/// Create a headless calendar nav button
/// Outputs: <button class="radix-calendar-nav-button">children</button>
pub fn radix_calendar_nav_button(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-calendar-nav-button")),
  ]
  match disabled {
    Some(true) => {
      attrs.push(("data-disabled", @luna.attr_static("")))
      attrs.push(("disabled", @luna.attr_static("")))
    }
    _ => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a headless calendar grid
/// Outputs: <table class="radix-calendar-grid" role="grid">children</table>
pub fn radix_calendar_grid(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "table",
    [
      ("class", @luna.attr_static("radix-calendar-grid")),
      ("role", @luna.attr_static("grid")),
    ],
    children,
  )
}

///|
/// Create a headless calendar grid head
/// Outputs: <thead class="radix-calendar-grid-head">children</thead>
pub fn radix_calendar_grid_head(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "thead",
    [("class", @luna.attr_static("radix-calendar-grid-head"))],
    children,
  )
}

///|
/// Create a headless calendar grid body
/// Outputs: <tbody class="radix-calendar-grid-body">children</tbody>
pub fn radix_calendar_grid_body(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "tbody",
    [("class", @luna.attr_static("radix-calendar-grid-body"))],
    children,
  )
}

///|
/// Create a headless calendar grid row
/// Outputs: <tr class="radix-calendar-grid-row">children</tr>
pub fn radix_calendar_grid_row(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "tr",
    [("class", @luna.attr_static("radix-calendar-grid-row"))],
    children,
  )
}

///|
/// Create a headless calendar head cell
/// Outputs: <th class="radix-calendar-head-cell">children</th>
pub fn radix_calendar_head_cell(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "th",
    [("class", @luna.attr_static("radix-calendar-head-cell"))],
    children,
  )
}

///|
/// Create a headless calendar cell
/// Outputs: <td class="radix-calendar-cell"><button>children</button></td>
pub fn radix_calendar_cell(
  day : Int,
  selected? : Bool,
  today? : Bool,
  outside_month? : Bool,
  disabled? : Bool,
) -> @luna.Node[Unit] {
  let is_selected = match selected {
    Some(true) => true
    _ => false
  }
  let is_today = match today {
    Some(true) => true
    _ => false
  }
  let is_outside = match outside_month {
    Some(true) => true
    _ => false
  }
  let button_attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-calendar-day")),
  ]
  if is_selected {
    button_attrs.push(("data-selected", @luna.attr_static("")))
  }
  if is_today {
    button_attrs.push(("data-today", @luna.attr_static("")))
  }
  if is_outside {
    button_attrs.push(("data-outside-month", @luna.attr_static("")))
  }
  match disabled {
    Some(true) => {
      button_attrs.push(("data-disabled", @luna.attr_static("")))
      button_attrs.push(("disabled", @luna.attr_static("")))
    }
    _ => ()
  }
  @luna.h("td", [("class", @luna.attr_static("radix-calendar-cell"))], [
    @luna.h("button", button_attrs, [@luna.text(day.to_string())]),
  ])
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the calendar component
fn calendar_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.calendar {
    #|  padding: 0.75rem;
    #|  background: white;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 8px;
    #|}
    #|
    #|.calendar-header {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: space-between;
    #|  margin-bottom: 0.5rem;
    #|}
    #|
    #|.calendar-title {
    #|  font-size: 0.875rem;
    #|  font-weight: 600;
    #|}
    #|
    #|.calendar-nav {
    #|  display: flex;
    #|  gap: 0.25rem;
    #|}
    #|
    #|.calendar-nav-button {
    #|  display: inline-flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 1.75rem;
    #|  height: 1.75rem;
    #|  padding: 0;
    #|  background: transparent;
    #|  border: 1px solid #e4e4e7;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.calendar-nav-button:hover:not([data-disabled]) {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.calendar-nav-button[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|.calendar-grid {
    #|  width: 100%;
    #|  border-collapse: collapse;
    #|}
    #|
    #|.calendar-head-cell {
    #|  padding: 0.5rem;
    #|  font-size: 0.75rem;
    #|  font-weight: 500;
    #|  color: #71717a;
    #|  text-align: center;
    #|}
    #|
    #|.calendar-cell {
    #|  padding: 0.125rem;
    #|  text-align: center;
    #|}
    #|
    #|.calendar-day {
    #|  width: 2rem;
    #|  height: 2rem;
    #|  padding: 0;
    #|  font-size: 0.875rem;
    #|  background: transparent;
    #|  border: none;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.calendar-day:hover:not([data-disabled]):not([data-selected]) {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.calendar-day[data-selected] {
    #|  background: #18181b;
    #|  color: white;
    #|}
    #|
    #|.calendar-day[data-today]:not([data-selected]) {
    #|  background: #f4f4f5;
    #|  font-weight: 600;
    #|}
    #|
    #|.calendar-day[data-outside-month] {
    #|  color: #a1a1aa;
    #|}
    #|
    #|.calendar-day[data-disabled] {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
  css
}

///|
/// Create a styled calendar with Declarative Shadow DOM
pub fn radix_calendar_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => calendar_styles()
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
  @luna.h("radix-calendar", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a calendar with luna/css atomic styles
pub fn radix_calendar_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = calendar_base_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a calendar header with luna/css atomic styles
pub fn radix_calendar_header_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = calendar_header_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a calendar nav button with luna/css atomic styles
pub fn radix_calendar_nav_button_ucss(
  disabled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let mut class_names = calendar_nav_button_styles()
  match disabled {
    Some(true) =>
      class_names = class_names +
        " " +
        @css.styles([("opacity", "0.5"), ("cursor", "not-allowed")])
    _ => ()
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
  ]
  match disabled {
    Some(true) => {
      attrs.push(("data-disabled", @luna.attr_static("")))
      attrs.push(("disabled", @luna.attr_static("")))
    }
    _ => ()
  }
  @luna.h("button", attrs, children)
}

///|
/// Create a calendar day with luna/css atomic styles
pub fn radix_calendar_day_ucss(
  day : Int,
  selected? : Bool,
  today? : Bool,
  outside_month? : Bool,
  disabled? : Bool,
) -> @luna.Node[Unit] {
  let is_selected = match selected {
    Some(true) => true
    _ => false
  }
  let is_today = match today {
    Some(true) => true
    _ => false
  }
  let is_outside = match outside_month {
    Some(true) => true
    _ => false
  }
  let mut class_names = calendar_day_styles()
  if is_selected {
    class_names = class_names +
      " " +
      @css.styles([("background", "#18181b"), ("color", "white")])
  } else if is_today {
    class_names = class_names +
      " " +
      @css.styles([("background", "#f4f4f5"), ("font-weight", "600")])
  }
  if is_outside {
    class_names = class_names + " " + @css.styles([("color", "#a1a1aa")])
  }
  match disabled {
    Some(true) =>
      class_names = class_names +
        " " +
        @css.styles([("opacity", "0.5"), ("cursor", "not-allowed")])
    _ => ()
  }
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
  ]
  match disabled {
    Some(true) => {
      attrs.push(("data-disabled", @luna.attr_static("")))
      attrs.push(("disabled", @luna.attr_static("")))
    }
    _ => ()
  }
  @luna.h("button", attrs, [@luna.text(day.to_string())])
}
