///|
/// Radix-style Table component for Luna (Headless)
/// Semantic table with styling hooks

///|
/// Create a headless table root
/// Outputs: <div class="radix-table-wrapper"><table class="radix-table">children</table></div>
pub fn radix_table(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("div", [("class", @luna.attr_static("radix-table-wrapper"))], [
    @luna.h("table", [("class", @luna.attr_static("radix-table"))], children),
  ])
}

///|
/// Create a headless table header
/// Outputs: <thead class="radix-table-header">children</thead>
pub fn radix_table_header(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "thead",
    [("class", @luna.attr_static("radix-table-header"))],
    children,
  )
}

///|
/// Create a headless table body
/// Outputs: <tbody class="radix-table-body">children</tbody>
pub fn radix_table_body(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("tbody", [("class", @luna.attr_static("radix-table-body"))], children)
}

///|
/// Create a headless table footer
/// Outputs: <tfoot class="radix-table-footer">children</tfoot>
pub fn radix_table_footer(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "tfoot",
    [("class", @luna.attr_static("radix-table-footer"))],
    children,
  )
}

///|
/// Create a headless table row
/// Outputs: <tr class="radix-table-row">children</tr>
pub fn radix_table_row(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("tr", [("class", @luna.attr_static("radix-table-row"))], children)
}

///|
/// Create a headless table head cell
/// Outputs: <th class="radix-table-head">children</th>
pub fn radix_table_head(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("th", [("class", @luna.attr_static("radix-table-head"))], children)
}

///|
/// Create a headless table cell
/// Outputs: <td class="radix-table-cell">children</td>
pub fn radix_table_cell(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("td", [("class", @luna.attr_static("radix-table-cell"))], children)
}

///|
/// Create a headless table caption
/// Outputs: <caption class="radix-table-caption">children</caption>
pub fn radix_table_caption(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "caption",
    [("class", @luna.attr_static("radix-table-caption"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the table component
fn table_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.table-wrapper {
    #|  width: 100%;
    #|  overflow: auto;
    #|}
    #|
    #|.table {
    #|  width: 100%;
    #|  border-collapse: collapse;
    #|  font-size: 0.875rem;
    #|}
    #|
    #|.table-header {
    #|  border-bottom: 1px solid #e4e4e7;
    #|}
    #|
    #|.table-head {
    #|  padding: 0.75rem 1rem;
    #|  text-align: left;
    #|  font-weight: 500;
    #|  color: #71717a;
    #|}
    #|
    #|.table-body .table-row {
    #|  border-bottom: 1px solid #e4e4e7;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.table-body .table-row:last-child {
    #|  border-bottom: none;
    #|}
    #|
    #|.table-body .table-row:hover {
    #|  background: #f4f4f5;
    #|}
    #|
    #|.table-cell {
    #|  padding: 0.75rem 1rem;
    #|  vertical-align: middle;
    #|}
    #|
    #|.table-footer {
    #|  border-top: 1px solid #e4e4e7;
    #|  background: #fafafa;
    #|}
    #|
    #|.table-footer .table-cell {
    #|  font-weight: 500;
    #|}
    #|
    #|.table-caption {
    #|  margin-top: 0.5rem;
    #|  font-size: 0.875rem;
    #|  color: #71717a;
    #|}
  css
}

///|
/// Create a styled table with Declarative Shadow DOM
pub fn radix_table_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => table_styles()
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
  @luna.h("radix-table", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a table with luna/css atomic styles
pub fn radix_table_ucss(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  let wrapper_class = table_wrapper_styles()
  let table_class = table_base_styles()
  @luna.h("div", [("class", @luna.attr_static(wrapper_class))], [
    @luna.h("table", [("class", @luna.attr_static(table_class))], children),
  ])
}

///|
/// Create a table header with luna/css atomic styles
pub fn radix_table_header_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = table_header_styles()
  @luna.h("thead", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a table body with luna/css atomic styles
pub fn radix_table_body_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h("tbody", [], children)
}

///|
/// Create a table row with luna/css atomic styles
pub fn radix_table_row_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = table_row_styles()
  @luna.h("tr", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a table head cell with luna/css atomic styles
pub fn radix_table_head_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = table_head_styles()
  @luna.h("th", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a table cell with luna/css atomic styles
pub fn radix_table_cell_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = table_cell_styles()
  @luna.h("td", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a table caption with luna/css atomic styles
pub fn radix_table_caption_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = table_caption_styles()
  @luna.h("caption", [("class", @luna.attr_static(class_names))], children)
}
