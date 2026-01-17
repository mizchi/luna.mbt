///|
/// Styled Table Component
///
/// A styled data table with sortable columns, selectable rows, and keyboard navigation.
///
/// Class names (BEM):
/// - .table           - Root container (wrapper)
/// - .table__table    - The actual table element
/// - .table__header   - Table header row
/// - .table__th       - Header cell
/// - .table__th--sortable - Sortable header cell
/// - .table__sort-icon - Sort direction indicator
/// - .table__body     - Table body
/// - .table__row      - Data row
/// - .table__cell     - Data cell
///
/// Data attributes:
/// - [data-selected]  - On selected row
/// - [aria-sort]      - Sort direction on header

///|
/// Sort direction for sortable columns
pub(all) enum SortDirection {
  None
  Ascending
  Descending
}

///|
/// Slots for the table component
pub(all) struct TableSlots {
  root : String
  table : String
  header : String
  th : String
  th_sortable : String
  sort_icon : String
  body : String
  row : String
  cell : String
}

///|
/// Default BEM class names for table
pub fn table_slots() -> TableSlots {
  {
    root: "table",
    table: "table__table",
    header: "table__header",
    th: "table__th",
    th_sortable: "table__th--sortable",
    sort_icon: "table__sort-icon",
    body: "table__body",
    row: "table__row",
    cell: "table__cell",
  }
}

///|
/// Column definition
pub(all) struct TableColumn {
  id : String
  label : String
  sortable : Bool
}

///|
/// Create a column definition
pub fn table_column(
  id : String,
  label : String,
  sortable? : Bool,
) -> TableColumn {
  { id, label, sortable: sortable.unwrap_or(false) }
}

///|
/// Row definition for data tables
pub(all) struct TableRow {
  id : String
  cells : Array[String]
}

///|
/// Create a row definition
pub fn table_row(id : String, cells : Array[String]) -> TableRow {
  { id, cells }
}

///|
/// Sort rows by column index
fn sort_rows(
  rows : Array[TableRow],
  col_idx : Int,
  direction : SortDirection,
) -> Array[TableRow] {
  if col_idx < 0 {
    return rows
  }
  match direction {
    None => rows
    Ascending => {
      let sorted = rows.copy()
      sorted.sort_by(fn(a, b) {
        let a_val = if col_idx < a.cells.length() { a.cells[col_idx] } else { "" }
        let b_val = if col_idx < b.cells.length() { b.cells[col_idx] } else { "" }
        a_val.compare(b_val)
      })
      sorted
    }
    Descending => {
      let sorted = rows.copy()
      sorted.sort_by(fn(a, b) {
        let a_val = if col_idx < a.cells.length() { a.cells[col_idx] } else { "" }
        let b_val = if col_idx < b.cells.length() { b.cells[col_idx] } else { "" }
        b_val.compare(a_val)
      })
      sorted
    }
  }
}

///|
/// Find column index by id
fn find_column_index(columns : Array[TableColumn], col_id : String) -> Int {
  for i, col in columns {
    if col.id == col_id {
      return i
    }
  }
  -1
}

///|
/// Create a styled interactive data table.
///
/// Parameters:
/// - id: Table ID
/// - columns: Column definitions
/// - rows: Row data
/// - aria_label: Accessible label
/// - selectable: Whether rows are selectable
/// - class: Additional CSS class
/// - on_row_select: Called when a row is selected
pub fn table(
  id : String,
  columns : Array[TableColumn],
  rows : Array[TableRow],
  aria_label? : String,
  selectable? : Bool,
  class? : String,
  on_row_select? : (String) -> Unit,
) -> @luna.Node[@js.Any] {
  let slots = table_slots()
  let is_selectable = selectable.unwrap_or(false)
  let root_class = match class {
    Some(c) => slots.root + " " + c
    None => slots.root
  }

  // State signals
  let selected_row = @resource.signal("")
  let sort_column = @resource.signal("")
  let sort_direction : @resource.Signal[SortDirection] = @resource.signal(None)

  // Build header cells
  let header_cells : Array[@luna.Node[@js.Any]] = []
  for column in columns {
    let col_id = column.id
    let th_class = if column.sortable {
      slots.th + " " + slots.th_sortable
    } else {
      slots.th
    }
    let header_attrs : Array[(String, @luna.Attr[@js.Any])] = [
      ("class", @luna.attr_static(th_class)),
      ("scope", @luna.attr_static("col")),
    ]
    if column.sortable {
      header_attrs.push(
        (
          "aria-sort",
          @luna.attr_dynamic(fn() {
            if sort_column.get() == col_id {
              match sort_direction.get() {
                Ascending => "ascending"
                Descending => "descending"
                None => "none"
              }
            } else {
              "none"
            }
          }),
        ),
      )
      header_attrs.push(
        (
          "click",
          @luna.attr_handler(
            @luna.handler(fn(_ : @js.Any) {
              let curr_col = sort_column.get()
              let curr_dir = sort_direction.get()
              let new_dir = if curr_col == col_id {
                match curr_dir {
                  None => Ascending
                  Ascending => Descending
                  Descending => None
                }
              } else {
                Ascending
              }
              sort_column.set(col_id)
              sort_direction.set(new_dir)
            }),
          ),
        ),
      )
    }

    // Build header content with sort icon
    let header_content : Array[@luna.Node[@js.Any]] = [@luna.text(column.label)]
    if column.sortable {
      header_content.push(
        @luna.h(
          "span",
          [
            ("class", @luna.attr_static(slots.sort_icon)),
            (
              "aria-hidden",
              @luna.attr_dynamic(fn() {
                if sort_column.get() == col_id {
                  match sort_direction.get() {
                    None => "true"
                    _ => "false"
                  }
                } else {
                  "true"
                }
              }),
            ),
          ],
          [
            @luna.text_dyn(fn() {
              if sort_column.get() == col_id {
                match sort_direction.get() {
                  Ascending => " \u{25B2}"
                  Descending => " \u{25BC}"
                  None => ""
                }
              } else {
                ""
              }
            }),
          ],
        ),
      )
    }
    header_cells.push(@luna.h("th", header_attrs, header_content))
  }

  // Build table body with reactive sorting using For node
  let table_body = @luna.h(
    "tbody",
    [("class", @luna.attr_static(slots.body))],
    [
      @luna.Node::For(
        render=fn() {
          let col_id = sort_column.get()
          let dir = sort_direction.get()
          let col_idx = find_column_index(columns, col_id)
          let sorted_rows = sort_rows(rows, col_idx, dir)
          let row_nodes : Array[@luna.Node[@js.Any]] = []
          for row in sorted_rows {
            let row_id = row.id
            let row_attrs : Array[(String, @luna.Attr[@js.Any])] = [
              ("class", @luna.attr_static(slots.row)),
            ]
            if is_selectable {
              row_attrs.push(
                (
                  "data-selected",
                  @luna.attr_dynamic(fn() {
                    if selected_row.get() == row_id {
                      "true"
                    } else {
                      "false"
                    }
                  }),
                ),
              )
              row_attrs.push(
                (
                  "click",
                  @luna.attr_handler(
                    @luna.handler(fn(_ : @js.Any) {
                      selected_row.set(row_id)
                      match on_row_select {
                        Some(handler) => handler(row_id)
                        None => ()
                      }
                    }),
                  ),
                ),
              )
            }

            // Build cells
            let cells : Array[@luna.Node[@js.Any]] = []
            for cell in row.cells {
              cells.push(
                @luna.h(
                  "td",
                  [("class", @luna.attr_static(slots.cell))],
                  [@luna.text(cell)],
                ),
              )
            }
            row_nodes.push(@luna.h("tr", row_attrs, cells))
          }
          row_nodes
        },
      ),
    ],
  )

  // Build table
  let table_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("id", @luna.attr_static(id)),
    ("class", @luna.attr_static(slots.table)),
  ]
  match aria_label {
    Some(label) => table_attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  @luna.h("div", [("class", @luna.attr_static(root_class))], [
    @luna.h("table", table_attrs, [
      @luna.h("thead", [("class", @luna.attr_static(slots.header))], [
        @luna.h("tr", [], header_cells),
      ]),
      table_body,
    ]),
  ])
}

///|
/// Get the CSS for the styled table.
pub fn table_css() -> String {
  let css =
    #|/* Table - Default Theme */
    #|.table {
    #|  width: 100%;
    #|  overflow-x: auto;
    #|}
    #|
    #|.table__table {
    #|  width: 100%;
    #|  border-collapse: collapse;
    #|  border: 1px solid var(--border);
    #|  border-radius: 0.375rem;
    #|  overflow: hidden;
    #|  font-size: 0.875rem;
    #|}
    #|
    #|.table__header {
    #|  background: var(--muted);
    #|}
    #|
    #|.table__th {
    #|  padding: 0.75rem 1rem;
    #|  text-align: left;
    #|  font-weight: 600;
    #|  color: var(--foreground);
    #|  border-bottom: 1px solid var(--border);
    #|  white-space: nowrap;
    #|}
    #|
    #|.table__th--sortable {
    #|  cursor: pointer;
    #|  user-select: none;
    #|  transition: background-color 0.15s;
    #|}
    #|
    #|.table__th--sortable:hover {
    #|  background: var(--border);
    #|}
    #|
    #|.table__th--sortable:focus-visible {
    #|  outline: 2px solid var(--accent);
    #|  outline-offset: -2px;
    #|}
    #|
    #|.table__sort-icon {
    #|  display: inline-block;
    #|  margin-left: 0.25rem;
    #|  color: var(--accent);
    #|  font-size: 0.75rem;
    #|}
    #|
    #|.table__row {
    #|  border-bottom: 1px solid var(--border);
    #|  transition: background-color 0.15s;
    #|}
    #|
    #|.table__row:last-child {
    #|  border-bottom: none;
    #|}
    #|
    #|.table__row:hover {
    #|  background: var(--muted);
    #|}
    #|
    #|.table__row[data-selected="true"] {
    #|  background: var(--accent);
    #|  color: var(--accent-foreground);
    #|}
    #|
    #|.table__row[data-selected="true"]:hover {
    #|  background: var(--accent);
    #|  opacity: 0.9;
    #|}
    #|
    #|.table__cell {
    #|  padding: 0.75rem 1rem;
    #|  color: var(--foreground);
    #|}
    #|
    #|.table__row[data-selected="true"] .table__cell {
    #|  color: var(--accent-foreground);
    #|}
    #|
    #|/* Reduced motion */
    #|@media (prefers-reduced-motion: reduce) {
    #|  .table__th--sortable,
    #|  .table__row {
    #|    transition: none;
    #|  }
    #|}
  css
}
