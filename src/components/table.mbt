///|
/// APG Table Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/table/
///
/// A table is a widget that presents content as a two-dimensional grid.
/// Tables can include sortable columns, selectable rows, and keyboard navigation.
///
/// Keyboard Interaction (Grid navigation):
/// - Right Arrow: Move to next cell in row
/// - Left Arrow: Move to previous cell in row
/// - Down Arrow: Move to same column in next row
/// - Up Arrow: Move to same column in previous row
/// - Home: Move to first cell in row
/// - End: Move to last cell in row
/// - Ctrl+Home: Move to first cell in table
/// - Ctrl+End: Move to last cell in table
/// - PageDown: Move down by viewport
/// - PageUp: Move up by viewport
///
/// ARIA:
/// - role="table" (or native <table>)
/// - role="rowgroup" for <thead>, <tbody>, <tfoot>
/// - role="row" for <tr>
/// - role="columnheader" for <th> in header
/// - role="rowheader" for <th> in row
/// - role="cell" for <td>
/// - aria-sort on sortable columns (ascending, descending, none)
/// - aria-selected on selectable rows

///|
/// Sort direction for sortable columns
pub(all) enum SortDirection {
  None
  Ascending
  Descending
}

///|
/// Column definition
pub(all) struct TableColumn {
  id : String
  label : String
  sortable : Bool
  header_scope : String // "col" or "row"
}

///|
/// Create a column definition
pub fn table_column(
  id : String,
  label : String,
  sortable? : Bool,
) -> TableColumn {
  { id, label, sortable: sortable.unwrap_or(false), header_scope: "col" }
}

///|
/// Row definition for data tables
pub(all) struct TableRow {
  id : String
  cells : Array[String]
  disabled : Bool
}

///|
/// Create a row definition
pub fn table_row(
  id : String,
  cells : Array[String],
  disabled? : Bool,
) -> TableRow {
  { id, cells, disabled: disabled.unwrap_or(false) }
}

///|
/// Create a table container element.
///
/// Parameters:
/// - id: Table ID
/// - aria_label: Accessible label
/// - aria_labelledby: ID of labelling element
/// - aria_describedby: ID of description element
/// - children: Table content (thead, tbody, etc.)
pub fn[E] table(
  id? : String,
  aria_label? : String,
  aria_labelledby? : String,
  aria_describedby? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = []
  if id is Some(i) {
    attrs.push(("id", @luna.attr_static(i)))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(lid) {
    attrs.push(("aria-labelledby", @luna.attr_static(lid)))
  }
  if aria_describedby is Some(did) {
    attrs.push(("aria-describedby", @luna.attr_static(did)))
  }
  @luna.h("table", attrs, children)
}

///|
/// Create a table head section.
pub fn[E] thead(children : Array[@luna.Node[E]]) -> @luna.Node[E] {
  @luna.h("thead", [], children)
}

///|
/// Create a table body section.
pub fn[E] tbody(children : Array[@luna.Node[E]]) -> @luna.Node[E] {
  @luna.h("tbody", [], children)
}

///|
/// Create a table footer section.
pub fn[E] tfoot(children : Array[@luna.Node[E]]) -> @luna.Node[E] {
  @luna.h("tfoot", [], children)
}

///|
/// Create a table row element.
///
/// Parameters:
/// - id: Row ID
/// - selected: Whether row is selected
/// - on_click: Click handler
/// - on_keydown: Keydown handler
/// - children: Cell elements
pub fn[E] tr(
  id? : String,
  selected? : Bool,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = []
  if id is Some(i) {
    attrs.push(("id", @luna.attr_static(i)))
  }
  if selected is Some(true) {
    attrs.push(("aria-selected", @luna.attr_static("true")))
  } else if selected is Some(false) {
    attrs.push(("aria-selected", @luna.attr_static("false")))
  }
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  @luna.h("tr", attrs, children)
}

///|
/// Create a dynamic table row with signal-based selection.
pub fn[E] tr_dyn(
  id : String,
  selected_row : @signal.Signal[String],
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("id", @luna.attr_static(id)),
    (
      "aria-selected",
      @luna.attr_dynamic(fn() {
        if selected_row.get() == id {
          "true"
        } else {
          "false"
        }
      }),
    ),
  ]
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  @luna.h("tr", attrs, children)
}

///|
/// Create a column header cell.
///
/// Parameters:
/// - id: Header ID
/// - scope: Scope (col, row, colgroup, rowgroup)
/// - sort: Sort direction (for sortable columns)
/// - on_click: Click handler (for sortable columns)
/// - children: Header content
pub fn[E] th(
  id? : String,
  scope? : String,
  sort? : SortDirection,
  on_click? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = []
  if id is Some(i) {
    attrs.push(("id", @luna.attr_static(i)))
  }
  if scope is Some(s) {
    attrs.push(("scope", @luna.attr_static(s)))
  }
  if sort is Some(Ascending) {
    attrs.push(("aria-sort", @luna.attr_static("ascending")))
  } else if sort is Some(Descending) {
    attrs.push(("aria-sort", @luna.attr_static("descending")))
  } else if sort is Some(None) {
    attrs.push(("aria-sort", @luna.attr_static("none")))
  }
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  @luna.h("th", attrs, children)
}

///|
/// Create a dynamic column header with signal-based sort state.
pub fn[E] th_dyn(
  id : String,
  scope : String,
  sort_column : @signal.Signal[String],
  sort_direction : @signal.Signal[SortDirection],
  on_click? : @luna.EventHandler[E],
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("id", @luna.attr_static(id)),
    ("scope", @luna.attr_static(scope)),
    (
      "aria-sort",
      @luna.attr_dynamic(fn() {
        if sort_column.get() == id {
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
  ]
  if on_click is Some(handler) {
    attrs.push(("click", @luna.attr_handler(handler)))
  }
  @luna.h("th", attrs, children)
}

///|
/// Create a data cell.
///
/// Parameters:
/// - id: Cell ID
/// - headers: Space-separated list of header IDs
/// - children: Cell content
pub fn[E] td(
  id? : String,
  headers? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = []
  if id is Some(i) {
    attrs.push(("id", @luna.attr_static(i)))
  }
  if headers is Some(h) {
    attrs.push(("headers", @luna.attr_static(h)))
  }
  @luna.h("td", attrs, children)
}

///|
/// Create a table caption.
pub fn[E] caption(
  id? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = []
  if id is Some(i) {
    attrs.push(("id", @luna.attr_static(i)))
  }
  @luna.h("caption", attrs, children)
}

///|
/// Create a table keyboard handler for grid navigation.
/// Handles arrow keys, Home/End, PageUp/PageDown.
pub fn make_table_handler(
  row_count : Int,
  col_count : Int,
  current_row : () -> Int,
  current_col : () -> Int,
  on_change : (Int, Int) -> Unit,
  focus_cell : (Int, Int) -> Unit,
  page_size? : Int,
) -> @luna.EventHandler[@js.Any] {
  let pg_size = page_size.unwrap_or(10)
  @luna.handler(fn(e : @js.Any) {
    let key : String = e._get("key").cast()
    let ctrl : Bool = e._get("ctrlKey").cast()
    let row = current_row()
    let col = current_col()
    let new_pos : (Int, Int)? = match key {
      "ArrowRight" =>
        if col < col_count - 1 {
          Some((row, col + 1))
        } else {
          None
        }
      "ArrowLeft" => if col > 0 { Some((row, col - 1)) } else { None }
      "ArrowDown" =>
        if row < row_count - 1 {
          Some((row + 1, col))
        } else {
          None
        }
      "ArrowUp" => if row > 0 { Some((row - 1, col)) } else { None }
      "Home" => if ctrl { Some((0, 0)) } else { Some((row, 0)) }
      "End" =>
        if ctrl {
          Some((row_count - 1, col_count - 1))
        } else {
          Some((row, col_count - 1))
        }
      "PageDown" => {
        let new_row = if row + pg_size >= row_count {
          row_count - 1
        } else {
          row + pg_size
        }
        Some((new_row, col))
      }
      "PageUp" => {
        let new_row = if row - pg_size < 0 { 0 } else { row - pg_size }
        Some((new_row, col))
      }
      _ => None
    }
    if new_pos is Some((new_row, new_col)) {
      if new_row != row || new_col != col {
        let _ = e._call("preventDefault", [])
        on_change(new_row, new_col)
        focus_cell(new_row, new_col)
      }
    }
  })
}

///|
/// Create a sortable table header click handler.
/// Toggles between ascending, descending, and none.
pub fn make_sort_handler(
  column_id : String,
  current_sort_column : () -> String,
  current_sort_direction : () -> SortDirection,
  on_sort : (String, SortDirection) -> Unit,
) -> @luna.EventHandler[@js.Any] {
  @luna.handler(fn(_ : @js.Any) {
    let curr_col = current_sort_column()
    let curr_dir = current_sort_direction()
    let new_dir = if curr_col == column_id {
      match curr_dir {
        None => Ascending
        Ascending => Descending
        Descending => None
      }
    } else {
      Ascending
    }
    on_sort(column_id, new_dir)
  })
}

///|
/// Create a complete interactive data table.
///
/// Parameters:
/// - id: Table ID
/// - columns: Column definitions
/// - rows: Row data
/// - aria_label: Accessible label
/// - selectable: Whether rows are selectable
/// - sortable: Whether columns are sortable
/// - on_row_select: Called when a row is selected
/// - on_sort: Called when sort changes
pub fn table_interactive(
  id : String,
  columns : Array[TableColumn],
  rows : Array[TableRow],
  aria_label? : String,
  selectable? : Bool,
  on_row_select? : (String) -> Unit,
  on_sort? : (String, SortDirection) -> Unit,
) -> @luna.Node[@js.Any] {
  let is_selectable = selectable.unwrap_or(false)
  let selected_row = @signal.signal("")
  let sort_column = @signal.signal("")
  let sort_direction : @signal.Signal[SortDirection] = @signal.signal(None)
  let focused_row = @signal.signal(0)
  let focused_col = @signal.signal(0)
  let row_count = rows.length()
  let col_count = columns.length()
  // Focus helper
  let focus_cell = fn(row : Int, col : Int) {
    let cell_id = id + "-cell-" + row.to_string() + "-" + col.to_string()
    let doc = @js.global_this()._get("document")
    let el = doc._call("getElementById", [@js.any(cell_id)])
    let _ = el._call("focus", [])

  }
  // Keyboard handler
  let keydown_handler = make_table_handler(
    row_count,
    col_count,
    fn() { focused_row.get() },
    fn() { focused_col.get() },
    fn(row, col) {
      focused_row.set(row)
      focused_col.set(col)
    },
    focus_cell,
  )
  // Build header row
  let header_cells : Array[@luna.Node[@js.Any]] = []
  for column in columns {
    let col_id = column.id
    let header_id = id + "-header-" + column.id
    let header_attrs : Array[(String, @luna.Attr[@js.Any])] = [
      ("id", @luna.attr_static(header_id)),
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
              if on_sort is Some(handler) {
                handler(col_id, new_dir)
              }
            }),
          ),
        ),
      )
      header_attrs.push(("style", @luna.attr_static("cursor: pointer")))
    }
    header_cells.push(@luna.h("th", header_attrs, [@luna.text(column.label)]))
  }
  // Build data rows
  let data_rows : Array[@luna.Node[@js.Any]] = []
  for row_idx, row in rows {
    let row_id = row.id
    let tr_id = id + "-row-" + row.id
    let row_attrs : Array[(String, @luna.Attr[@js.Any])] = [
      ("id", @luna.attr_static(tr_id)),
    ]
    if is_selectable {
      row_attrs.push(
        (
          "aria-selected",
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
              if on_row_select is Some(handler) {
                handler(row_id)
              }
            }),
          ),
        ),
      )
    }
    // Build cells for this row
    let cells : Array[@luna.Node[@js.Any]] = []
    for col_idx, cell in row.cells {
      let cell_id = id +
        "-cell-" +
        row_idx.to_string() +
        "-" +
        col_idx.to_string()
      let cell_attrs : Array[(String, @luna.Attr[@js.Any])] = [
        ("id", @luna.attr_static(cell_id)),
        (
          "tabindex",
          @luna.attr_dynamic(fn() {
            if focused_row.get() == row_idx && focused_col.get() == col_idx {
              "0"
            } else {
              "-1"
            }
          }),
        ),
        ("keydown", @luna.attr_handler(keydown_handler)),
      ]
      // Link to column header
      if col_idx < columns.length() {
        let header_id = id + "-header-" + columns[col_idx].id
        cell_attrs.push(("headers", @luna.attr_static(header_id)))
      }
      cells.push(@luna.h("td", cell_attrs, [@luna.text(cell)]))
    }
    data_rows.push(@luna.h("tr", row_attrs, cells))
  }
  // Build table
  let table_attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("id", @luna.attr_static(id)),
  ]
  if aria_label is Some(label) {
    table_attrs.push(("aria-label", @luna.attr_static(label)))
  }
  @luna.h("table", table_attrs, [
    @luna.h("thead", [], [@luna.h("tr", [], header_cells)]),
    @luna.h("tbody", [], data_rows),
  ])
}

///|
/// Create a simple static table with caption.
///
/// Parameters:
/// - id: Table ID
/// - caption_text: Caption text
/// - headers: Header labels
/// - rows: Array of row data (each row is an array of cell strings)
pub fn[E] simple_table(
  id : String,
  caption_text? : String,
  headers : Array[String],
  rows : Array[Array[String]],
) -> @luna.Node[E] {
  // Build header cells
  let header_cells : Array[@luna.Node[E]] = []
  for header in headers {
    header_cells.push(th(scope="col", [@luna.text(header)]))
  }
  // Build data rows
  let data_rows : Array[@luna.Node[E]] = []
  for row in rows {
    let cells : Array[@luna.Node[E]] = []
    for cell in row {
      cells.push(td([@luna.text(cell)]))
    }
    data_rows.push(tr(cells))
  }
  // Build table
  let table_content : Array[@luna.Node[E]] = []
  if caption_text is Some(cap) {
    table_content.push(caption([@luna.text(cap)]))
  }
  table_content.push(thead([tr(header_cells)]))
  table_content.push(tbody(data_rows))
  table(id~, table_content)
}
