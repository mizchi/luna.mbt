///|
/// APG Tree View Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/treeview/
///
/// A tree view presents a hierarchical list of items that can be
/// expanded and collapsed.
///
/// Keyboard Interaction:
/// - Down Arrow: Move to next visible node
/// - Up Arrow: Move to previous visible node
/// - Right Arrow: Expand closed parent or move to first child
/// - Left Arrow: Collapse open parent or move to parent
/// - Home: Move to first node
/// - End: Move to last visible node
/// - Enter/Space: Activate/select node
///
/// ARIA:
/// - role="tree" on container
/// - role="treeitem" on each node
/// - role="group" on child container
/// - aria-expanded on parent nodes
/// - aria-selected on all nodes

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
pub fn has_children(node : TreeNode) -> Bool {
  node.children.length() > 0
}

///|
/// Create the tree container.
///
/// Parameters:
/// - id: Tree ID
/// - aria_label: Accessible label
/// - aria_labelledby: ID of labelling element
/// - multiselectable: Whether multiple items can be selected
/// - children: Tree items
pub fn[E] tree(
  id? : String,
  aria_label? : String,
  aria_labelledby? : String,
  multiselectable? : Bool,
  children : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("role", @luna.attr_static("tree")),
  ]
  if id is Some(i) {
    attrs.push(("id", @luna.attr_static(i)))
  }
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(lid) {
    attrs.push(("aria-labelledby", @luna.attr_static(lid)))
  }
  if multiselectable is Some(true) {
    attrs.push(("aria-multiselectable", @luna.attr_static("true")))
  }
  @luna.h("ul", attrs, children)
}

///|
/// Create a tree item (leaf node or branch node).
///
/// Parameters:
/// - id: Item ID
/// - selected: Whether the item is selected
/// - expanded: Whether the item is expanded (for parent nodes)
/// - has_children: Whether this is a parent node
/// - focused: Whether this item has tabindex=0
/// - disabled: Whether the item is disabled
/// - on_click: Click handler
/// - on_keydown: Keydown handler
/// - label_content: Content for the label
/// - children: Child nodes (for parent nodes)
pub fn[E] treeitem(
  id? : String,
  selected : Bool,
  expanded? : Bool,
  has_children : Bool,
  focused : Bool,
  disabled? : Bool,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  label_content : Array[@luna.Node[E, String]],
  children? : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let is_disabled = disabled.unwrap_or(false)
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("role", @luna.attr_static("treeitem")),
    (
      "aria-selected",
      @luna.attr_static(if selected { "true" } else { "false" }),
    ),
    ("tabindex", @luna.attr_static(if focused { "0" } else { "-1" })),
  ]
  if id is Some(i) {
    attrs.push(("id", @luna.attr_static(i)))
  }
  if has_children {
    if expanded is Some(exp) {
      attrs.push(
        ("aria-expanded", @luna.attr_static(if exp { "true" } else { "false" })),
      )
    }
  }
  if is_disabled {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if on_click is Some(handler) {
    if not(is_disabled) {
      attrs.push(("click", @luna.attr_handler(handler)))
    }
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  // Build content
  let content : Array[@luna.Node[E, String]] = label_content.copy()
  // Add child group if expanded
  if has_children {
    if expanded is Some(true) && children is Some(kids) {
      content.push(@luna.h("ul", [("role", @luna.attr_static("group"))], kids))
    }
  }
  @luna.h("li", attrs, content)
}

///|
/// Create a dynamic tree item with signal-based state.
pub fn[E] treeitem_dyn(
  id? : String,
  selected : @resource.Signal[String],
  item_id : String,
  expanded? : @resource.Signal[Map[String, Bool]],
  has_children : Bool,
  focused_id : @resource.Signal[String],
  disabled? : Bool,
  on_click? : @luna.EventHandler[E],
  on_keydown? : @luna.EventHandler[E],
  label_content : Array[@luna.Node[E, String]],
  children? : Array[@luna.Node[E, String]],
) -> @luna.Node[E, String] {
  let is_disabled = disabled.unwrap_or(false)
  let attrs : Array[(String, @luna.Attr[E, String])] = [
    ("role", @luna.attr_static("treeitem")),
    (
      "aria-selected",
      @luna.attr_dynamic(fn() {
        if selected.get() == item_id {
          "true"
        } else {
          "false"
        }
      }),
    ),
    (
      "tabindex",
      @luna.attr_dynamic(fn() {
        if focused_id.get() == item_id {
          "0"
        } else {
          "-1"
        }
      }),
    ),
  ]
  if id is Some(i) {
    attrs.push(("id", @luna.attr_static(i)))
  }
  if has_children {
    if expanded is Some(exp_map) {
      attrs.push(
        (
          "aria-expanded",
          @luna.attr_dynamic(fn() {
            if exp_map.get().get(item_id).unwrap_or(false) {
              "true"
            } else {
              "false"
            }
          }),
        ),
      )
    }
  }
  if is_disabled {
    attrs.push(("aria-disabled", @luna.attr_static("true")))
  }
  if on_click is Some(handler) {
    if not(is_disabled) {
      attrs.push(("click", @luna.attr_handler(handler)))
    }
  }
  if on_keydown is Some(handler) {
    attrs.push(("keydown", @luna.attr_handler(handler)))
  }
  // Build content - children need to be rendered conditionally
  let content : Array[@luna.Node[E, String]] = label_content.copy()
  if has_children {
    if expanded is Some(exp_map) && children is Some(kids) {
      content.push(
        @luna.show(fn() { exp_map.get().get(item_id).unwrap_or(false) }, fn() {
          @luna.h("ul", [("role", @luna.attr_static("group"))], kids)
        }),
      )
    }
  }
  @luna.h("li", attrs, content)
}

///|
/// Flatten tree nodes into a list of visible node IDs for navigation.
/// Only includes expanded nodes' children.
pub fn flatten_visible_nodes(
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
pub fn find_parent_id(
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
pub fn find_node(nodes : Array[TreeNode], target_id : String) -> TreeNode? {
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
/// Create tree view keyboard handler.
pub fn make_tree_handler(
  nodes : Array[TreeNode],
  focused_id : @resource.Signal[String],
  expanded : @resource.Signal[Map[String, Bool]],
  selected : @resource.Signal[String],
  on_activate : (String) -> Unit,
) -> @luna.EventHandler[@js.Any] {
  @luna.handler(fn(e : @js.Any) {
    // Stop event propagation to prevent multiple handlers firing
    let _ = e._call("stopPropagation", [])
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
            // Move to parent
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
/// Focus a tree item by ID
fn focus_tree_item(item_id : String) -> Unit {
  let doc = @js.global_this()._get("document")
  let el = doc._call("getElementById", [@js.any(item_id)])
  let _ = el._call("focus", [])
}

///|
/// Render a single tree node (helper to ensure proper closure capture).
fn render_single_tree_node(
  node_id : String,
  node_label : String,
  node_children : Array[TreeNode],
  node_disabled : Bool,
  focused_id : @resource.Signal[String],
  expanded : @resource.Signal[Map[String, Bool]],
  selected : @resource.Signal[String],
  keydown_handler : @luna.EventHandler[@js.Any],
  on_select : (String) -> Unit,
) -> @luna.Node[@js.Any, String] {
  let has_kids = node_children.length() > 0
  // Build child nodes recursively
  let child_nodes = if has_kids {
    Some(
      render_tree_nodes(
        node_children, focused_id, expanded, selected, keydown_handler, on_select,
      ),
    )
  } else {
    None
  }
  treeitem_dyn(
    id=node_id,
    selected,
    node_id,
    expanded~,
    has_kids,
    focused_id,
    disabled=node_disabled,
    on_click=@luna.handler(fn(_) {
      focused_id.set(node_id)
      on_select(node_id)
    }),
    on_keydown=keydown_handler,
    [@luna.text(node_label)],
    children=child_nodes.unwrap_or([]),
  )
}

///|
/// Render tree nodes recursively.
fn render_tree_nodes(
  nodes : Array[TreeNode],
  focused_id : @resource.Signal[String],
  expanded : @resource.Signal[Map[String, Bool]],
  selected : @resource.Signal[String],
  keydown_handler : @luna.EventHandler[@js.Any],
  on_select : (String) -> Unit,
) -> Array[@luna.Node[@js.Any, String]] {
  let items : Array[@luna.Node[@js.Any, String]] = []
  for node in nodes {
    // Call helper function to ensure proper closure capture
    items.push(
      render_single_tree_node(
        node.id,
        node.label,
        node.children,
        node.disabled,
        focused_id,
        expanded,
        selected,
        keydown_handler,
        on_select,
      ),
    )
  }
  items
}

///|
/// Create a complete interactive tree view.
///
/// Parameters:
/// - id: Tree ID
/// - nodes: Tree node data
/// - aria_label: Accessible label
/// - on_select: Called when a node is selected
pub fn tree_interactive(
  id : String,
  nodes : Array[TreeNode],
  aria_label? : String,
  on_select : (String) -> Unit,
) -> @luna.Node[@js.Any, String] {
  // Initialize state
  let first_id = if nodes.length() > 0 { nodes[0].id } else { "" }
  let focused_id = @resource.signal(first_id)
  let expanded : @resource.Signal[Map[String, Bool]] = @resource.signal({})
  let selected = @resource.signal("")
  // Create keydown handler
  let keydown_handler = make_tree_handler(
    nodes, focused_id, expanded, selected, on_select,
  )
  // Render tree items
  let tree_items = render_tree_nodes(
    nodes, focused_id, expanded, selected, keydown_handler, on_select,
  )
  // Build tree container
  let attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
    ("role", @luna.attr_static("tree")),
    ("id", @luna.attr_static(id)),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  @luna.h("ul", attrs, tree_items)
}
