///|
/// Styled Tree View Component
///
/// A styled hierarchical tree view with expand/collapse and keyboard navigation.
///
/// Class names (BEM):
/// - .treeview           - Root container
/// - .treeview__item     - Tree item (li)
/// - .treeview__row      - Clickable row content
/// - .treeview__icon     - Expand/collapse icon
/// - .treeview__label    - Item label text
/// - .treeview__group    - Child group container
///
/// Data attributes:
/// - [data-expanded="true"|"false"] - On items with children
/// - [data-selected="true"|"false"] - Selection state
/// - [data-depth="0"|"1"|"2"...] - Nesting depth

///|
/// Slots for the treeview component
pub(all) struct TreeViewSlots {
  root : String
  item : String
  row : String
  icon : String
  label : String
  group : String
}

///|
/// Default BEM class names for treeview
pub fn treeview_slots() -> TreeViewSlots {
  {
    root: "treeview",
    item: "treeview__item",
    row: "treeview__row",
    icon: "treeview__icon",
    label: "treeview__label",
    group: "treeview__group",
  }
}

///|
/// Tree node data structure
pub(all) struct TreeNode {
  id : String
  label : String
  children : Array[TreeNode]
  disabled : Bool
}

///|
/// Create a tree node
pub fn tree_node(
  id : String,
  label : String,
  children? : Array[TreeNode],
  disabled? : Bool,
) -> TreeNode {
  {
    id,
    label,
    children: children.unwrap_or([]),
    disabled: disabled.unwrap_or(false),
  }
}

///|
/// Check if a node has children
fn has_children(node : TreeNode) -> Bool {
  node.children.length() > 0
}

///|
/// Flatten tree nodes into a list of visible node IDs for navigation.
fn flatten_visible_nodes(
  nodes : Array[TreeNode],
  expanded : Map[String, Bool],
) -> Array[String] {
  let result : Array[String] = []
  for node in nodes {
    result.push(node.id)
    if has_children(node) && expanded.get(node.id).unwrap_or(false) {
      let children_flat = flatten_visible_nodes(node.children, expanded)
      for child_id in children_flat {
        result.push(child_id)
      }
    }
  }
  result
}

///|
/// Find parent ID for a node
fn find_parent_id(
  nodes : Array[TreeNode],
  target_id : String,
  parent_id : String?,
) -> String? {
  for node in nodes {
    if node.id == target_id {
      return parent_id
    }
    if has_children(node) {
      let found = find_parent_id(node.children, target_id, Some(node.id))
      if found is Some(_) {
        return found
      }
    }
  }
  None
}

///|
/// Find a node by ID
fn find_node(nodes : Array[TreeNode], target_id : String) -> TreeNode? {
  for node in nodes {
    if node.id == target_id {
      return Some(node)
    }
    if has_children(node) {
      let found = find_node(node.children, target_id)
      if found is Some(_) {
        return found
      }
    }
  }
  None
}

///|
/// Focus a tree item by ID
fn focus_tree_item(item_id : String) -> Unit {
  let doc = @js.global_this()._get("document")
  let el = doc._call("getElementById", [@js.any(item_id)])
  let _ = el._call("focus", [])

}

///|
/// Create tree view keyboard handler.
fn make_tree_handler(
  nodes : Array[TreeNode],
  focused_id : @resource.Signal[String],
  expanded : @resource.Signal[Map[String, Bool]],
  selected : @resource.Signal[String],
  on_activate : (String) -> Unit,
) -> @luna.EventHandler[@js.Any] {
  @luna.handler(fn(e : @js.Any) {
    let key : String = e._get("key").cast()
    let current_id = focused_id.get()
    let exp_map = expanded.get()
    let visible = flatten_visible_nodes(nodes, exp_map)
    let current_index = {
      let mut idx = 0
      for i, id in visible {
        if id == current_id {
          idx = i
          break
        }
      }
      idx
    }
    match key {
      "ArrowDown" => {
        let _ = e._call("preventDefault", [])
        if current_index < visible.length() - 1 {
          let next_id = visible[current_index + 1]
          focused_id.set(next_id)
          focus_tree_item(next_id)
        }
      }
      "ArrowUp" => {
        let _ = e._call("preventDefault", [])
        if current_index > 0 {
          let prev_id = visible[current_index - 1]
          focused_id.set(prev_id)
          focus_tree_item(prev_id)
        }
      }
      "ArrowRight" => {
        let _ = e._call("preventDefault", [])
        if find_node(nodes, current_id) is Some(node) {
          if has_children(node) {
            let is_expanded = exp_map.get(current_id).unwrap_or(false)
            if not(is_expanded) {
              // Expand
              let new_map = exp_map.copy()
              new_map.set(current_id, true)
              expanded.set(new_map)
            } else if node.children.length() > 0 {
              // Move to first child
              let first_child = node.children[0]
              focused_id.set(first_child.id)
              focus_tree_item(first_child.id)
            }
          }
        }
      }
      "ArrowLeft" => {
        let _ = e._call("preventDefault", [])
        if find_node(nodes, current_id) is Some(node) {
          if has_children(node) && exp_map.get(current_id).unwrap_or(false) {
            // Collapse
            let new_map = exp_map.copy()
            new_map.set(current_id, false)
            expanded.set(new_map)
          } else if find_parent_id(nodes, current_id, None) is Some(parent_id) {
            focused_id.set(parent_id)
            focus_tree_item(parent_id)
          }
        }
      }
      "Home" => {
        let _ = e._call("preventDefault", [])
        if visible.length() > 0 {
          let first_id = visible[0]
          focused_id.set(first_id)
          focus_tree_item(first_id)
        }
      }
      "End" => {
        let _ = e._call("preventDefault", [])
        if visible.length() > 0 {
          let last_id = visible[visible.length() - 1]
          focused_id.set(last_id)
          focus_tree_item(last_id)
        }
      }
      "Enter" | " " => {
        let _ = e._call("preventDefault", [])
        selected.set(current_id)
        on_activate(current_id)
      }
      _ => ()
    }
  })
}

///|
/// Render tree nodes recursively with styling.
fn render_styled_tree_nodes(
  nodes : Array[TreeNode],
  focused_id : @resource.Signal[String],
  expanded : @resource.Signal[Map[String, Bool]],
  selected : @resource.Signal[String],
  keydown_handler : @luna.EventHandler[@js.Any],
  on_select : (String) -> Unit,
  depth : Int,
) -> Array[@luna.Node[@js.Any]] {
  let slots = treeview_slots()
  let items : Array[@luna.Node[@js.Any]] = []
  for node in nodes {
    let node_id = node.id
    let has_kids = has_children(node)

    // Icon element (only for items with children)
    let icon_node : @luna.Node[@js.Any] = if has_kids {
      @luna.h(
        "span",
        [
          ("class", @luna.attr_static(slots.icon)),
          ("aria-hidden", @luna.attr_static("true")),
        ],
        [
          @luna.text_dyn(fn() {
            if expanded.get().get(node_id).unwrap_or(false) {
              "\u{25BC}" // ▼
            } else {
              "\u{25B6}" // ▶
            }
          }),
        ],
      )
    } else {
      // Placeholder for alignment
      @luna.h(
        "span",
        [
          ("class", @luna.attr_static(slots.icon + " " + slots.icon + "--empty")),
          ("aria-hidden", @luna.attr_static("true")),
        ],
        [],
      )
    }

    // Label element
    let label_node = @luna.h(
      "span",
      [("class", @luna.attr_static(slots.label))],
      [@luna.text(node.label)],
    )

    // Row element (clickable)
    let row_node = @luna.h(
      "div",
      [
        ("class", @luna.attr_static(slots.row)),
        (
          "data-selected",
          @luna.attr_dynamic(fn() {
            if selected.get() == node_id {
              "true"
            } else {
              "false"
            }
          }),
        ),
        ("data-depth", @luna.attr_static(depth.to_string())),
        (
          "click",
          @luna.attr_handler(@luna.handler(fn(e : @js.Any) {
            let _ = e._call("stopPropagation", [])
            focused_id.set(node_id)
            selected.set(node_id)
            on_select(node_id)
            // Toggle expand/collapse if has children
            if has_kids {
              let exp_map = expanded.get()
              let new_map = exp_map.copy()
              let is_expanded = exp_map.get(node_id).unwrap_or(false)
              new_map.set(node_id, not(is_expanded))
              expanded.set(new_map)
            }
          })),
        ),
      ],
      [icon_node, label_node],
    )

    // Build child group (always rendered, visibility controlled by CSS/show)
    let children_content : Array[@luna.Node[@js.Any]] = [row_node]
    if has_kids {
      children_content.push(
        @luna.show(
          fn() { expanded.get().get(node_id).unwrap_or(false) },
          fn() {
            let child_items = render_styled_tree_nodes(
              node.children,
              focused_id,
              expanded,
              selected,
              keydown_handler,
              on_select,
              depth + 1,
            )
            @luna.h(
              "ul",
              [
                ("role", @luna.attr_static("group")),
                ("class", @luna.attr_static(slots.group)),
              ],
              child_items,
            )
          },
        ),
      )
    }

    // Item element
    let item_attrs : Array[(String, @luna.Attr[@js.Any])] = [
      ("role", @luna.attr_static("treeitem")),
      ("id", @luna.attr_static(node_id)),
      ("class", @luna.attr_static(slots.item)),
      (
        "tabindex",
        @luna.attr_dynamic(fn() {
          if focused_id.get() == node_id {
            "0"
          } else {
            "-1"
          }
        }),
      ),
      (
        "aria-selected",
        @luna.attr_dynamic(fn() {
          if selected.get() == node_id {
            "true"
          } else {
            "false"
          }
        }),
      ),
      ("keydown", @luna.attr_handler(keydown_handler)),
    ]
    if has_kids {
      item_attrs.push(
        (
          "aria-expanded",
          @luna.attr_dynamic(fn() {
            if expanded.get().get(node_id).unwrap_or(false) {
              "true"
            } else {
              "false"
            }
          }),
        ),
      )
    }
    if node.disabled {
      item_attrs.push(("aria-disabled", @luna.attr_static("true")))
    }

    items.push(@luna.h("li", item_attrs, children_content))
  }
  items
}

///|
/// Create a styled tree view component.
///
/// Parameters:
/// - id: Tree ID
/// - nodes: Tree node data
/// - aria_label: Accessible label
/// - on_select: Called when a node is selected
/// - class: Additional CSS class
/// - initial_expanded: IDs of initially expanded nodes
pub fn treeview(
  id : String,
  nodes : Array[TreeNode],
  aria_label? : String,
  on_select : (String) -> Unit,
  class? : String,
  initial_expanded? : Array[String],
) -> @luna.Node[@js.Any] {
  let slots = treeview_slots()
  let root_class = match class {
    Some(c) => slots.root + " " + c
    None => slots.root
  }

  // Initialize state
  let first_id = if nodes.length() > 0 { nodes[0].id } else { "" }
  let focused_id = @resource.signal(first_id)

  // Build initial expanded map
  let init_expanded : Map[String, Bool] = {}
  match initial_expanded {
    Some(ids) =>
      for exp_id in ids {
        init_expanded.set(exp_id, true)
      }
    None => ()
  }
  let expanded : @resource.Signal[Map[String, Bool]] = @resource.signal(
    init_expanded,
  )
  let selected = @resource.signal("")

  // Create keydown handler
  let keydown_handler = make_tree_handler(
    nodes, focused_id, expanded, selected, on_select,
  )

  // Render tree items
  let tree_items = render_styled_tree_nodes(
    nodes, focused_id, expanded, selected, keydown_handler, on_select, 0,
  )

  // Build tree container
  let attrs : Array[(String, @luna.Attr[@js.Any])] = [
    ("role", @luna.attr_static("tree")),
    ("id", @luna.attr_static(id)),
    ("class", @luna.attr_static(root_class)),
  ]
  match aria_label {
    Some(label) => attrs.push(("aria-label", @luna.attr_static(label)))
    None => ()
  }
  @luna.h("ul", attrs, tree_items)
}

///|
/// Get the CSS for the styled treeview.
pub fn treeview_css() -> String {
  let css =
    #|/* TreeView - Default Theme */
    #|
    #|/* Override APG headless styles to prevent icon conflicts */
    #|.treeview [role="treeitem"]::before {
    #|  content: none !important;
    #|  display: none !important;
    #|}
    #|.treeview [role="treeitem"] {
    #|  padding: 0;
    #|  border-bottom: none;
    #|}
    #|.treeview [role="treeitem"]:hover {
    #|  background: transparent;
    #|}
    #|.treeview [role="treeitem"]:focus {
    #|  box-shadow: none;
    #|}
    #|
    #|.treeview {
    #|  list-style: none;
    #|  margin: 0;
    #|  padding: 0;
    #|  border: 1px solid var(--border);
    #|  border-radius: 0.5rem;
    #|  background: var(--background);
    #|  overflow: hidden;
    #|  min-width: 200px;
    #|}
    #|
    #|.treeview__item {
    #|  list-style: none;
    #|  margin: 0;
    #|  padding: 0;
    #|  outline: none;
    #|}
    #|
    #|.treeview__row {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.25rem;
    #|  padding: 0.625rem 0.75rem;
    #|  cursor: pointer;
    #|  border-bottom: 1px solid var(--border);
    #|  transition: background-color 0.15s;
    #|}
    #|
    #|/* Depth-based indentation */
    #|.treeview__row[data-depth="0"] { padding-left: 0.75rem; }
    #|.treeview__row[data-depth="1"] { padding-left: 1.75rem; }
    #|.treeview__row[data-depth="2"] { padding-left: 2.75rem; }
    #|.treeview__row[data-depth="3"] { padding-left: 3.75rem; }
    #|.treeview__row[data-depth="4"] { padding-left: 4.75rem; }
    #|.treeview__row[data-depth="5"] { padding-left: 5.75rem; }
    #|
    #|.treeview__row:hover {
    #|  background: var(--muted);
    #|}
    #|
    #|.treeview__row[data-selected="true"] {
    #|  background: var(--accent);
    #|}
    #|
    #|.treeview__row[data-selected="true"]:hover {
    #|  background: var(--accent);
    #|}
    #|
    #|.treeview__item:focus > .treeview__row {
    #|  outline: 2px solid var(--accent);
    #|  outline-offset: -2px;
    #|}
    #|
    #|.treeview__item:last-child > .treeview__row {
    #|  border-bottom: none;
    #|}
    #|
    #|.treeview__icon {
    #|  flex-shrink: 0;
    #|  width: 1rem;
    #|  font-size: 0.625rem;
    #|  color: var(--muted-foreground);
    #|  text-align: center;
    #|}
    #|
    #|.treeview__row[data-selected="true"] .treeview__icon {
    #|  color: var(--foreground);
    #|}
    #|
    #|.treeview__icon--empty {
    #|  visibility: hidden;
    #|}
    #|
    #|.treeview__label {
    #|  flex: 1;
    #|  font-size: 0.875rem;
    #|  font-weight: 400;
    #|  color: var(--foreground);
    #|}
    #|
    #|.treeview__row[data-selected="true"] .treeview__label {
    #|  font-weight: 500;
    #|}
    #|
    #|.treeview__group {
    #|  list-style: none;
    #|  margin: 0;
    #|  padding: 0;
    #|}
    #|
    #|/* Nested items don't have bottom border on last child unless it's also last in parent */
    #|.treeview__group .treeview__item:last-child > .treeview__row {
    #|  border-bottom: 1px solid var(--border);
    #|}
    #|
    #|.treeview__item:last-child .treeview__group .treeview__item:last-child > .treeview__row {
    #|  border-bottom: none;
    #|}
    #|
    #|/* Disabled state */
    #|.treeview__item[aria-disabled="true"] .treeview__row {
    #|  opacity: 0.5;
    #|  cursor: not-allowed;
    #|}
    #|
    #|/* Reduced motion */
    #|@media (prefers-reduced-motion: reduce) {
    #|  .treeview__row {
    #|    transition: none;
    #|  }
    #|}
  css
}
