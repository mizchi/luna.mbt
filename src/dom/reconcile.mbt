// Solid-style reference-based reconciliation for DOM reuse
//
// Unlike React's key-based reconciliation, this approach tracks item references
// using JavaScript's === operator. When items are reordered, their DOM nodes
// are moved rather than recreated.
//

///|
/// Check if two values are the same reference (physical equality)
/// Uses JavaScript's === operator for reference comparison
extern "js" fn ref_equal_any(a : @js.Any, b : @js.Any) -> Bool =
  #| (a, b) => a === b

///|
/// Check if two values are the same reference (type-safe wrapper)
pub fn[T] ref_equal(a : T, b : T) -> Bool {
  ref_equal_any(@js.any(a), @js.any(b))
}

///|
/// Reference-keyed Map helpers for faster lookups (JS Map)
extern "js" fn ref_map_new() -> @js.Any =
  #| () => new Map()

///|
extern "js" fn ref_map_has(map : @js.Any, key : @js.Any) -> Bool =
  #| (map, key) => map.has(key)

///|
extern "js" fn ref_map_set(map : @js.Any, key : @js.Any, value : Int) -> Unit =
  #| (map, key, value) => { map.set(key, value); }

///|
extern "js" fn ref_map_get_or_minus1(map : @js.Any, key : @js.Any) -> Int =
  #| (map, key) => {
  #|   const v = map.get(key);
  #|   return v === undefined ? -1 : v;
  #| }

///|
/// Check if a node's next sibling matches the expected node
extern "js" fn next_sibling_is(
  node : @js_dom.Node,
  expected : @js_dom.Node,
) -> Bool =
  #| (node, expected) => node.nextSibling === expected

///|
/// Item-DOM mapping entry
/// Stores the association between an item reference and its DOM nodes
/// Also stores a dispose function for cleanup when item is removed
pub(all) struct ItemEntry[T] {
  item : T
  dom : @js_dom.Node
  last : @js_dom.Node
  nodes : Array[@js_dom.Node]
  dispose : () -> Unit
}

///|
/// Create a new ItemEntry
pub fn[T] ItemEntry::new(item : T, dom : @js_dom.Node) -> ItemEntry[T] {
  // Default dispose is no-op for backwards compatibility
  { item, dom, last: dom, nodes: [dom], dispose: fn() {  } }
}

///|
/// Create a new ItemEntry with dispose function
pub fn[T] ItemEntry::new_with_dispose(
  item : T,
  dom : @js_dom.Node,
  dispose : () -> Unit,
) -> ItemEntry[T] {
  { item, dom, last: dom, nodes: [dom], dispose }
}

///|
/// Create ItemEntry from multiple DOM nodes
pub fn[T] ItemEntry::new_with_nodes_and_dispose(
  item : T,
  nodes : Array[@js_dom.Node],
  dispose : () -> Unit,
) -> ItemEntry[T] {
  let first = nodes[0]
  let last = nodes[nodes.length() - 1]
  { item, dom: first, last, nodes, dispose }
}

///|
/// Build a reference-keyed index map for old entries
fn[T] build_entry_index_map(entries : Array[ItemEntry[T]]) -> @js.Any {
  let map = ref_map_new()
  for i, entry in entries {
    let key = @js.any(entry.item)
    if not(ref_map_has(map, key)) {
      ref_map_set(map, key, i)
    }
  }
  map
}

///|
/// Detect duplicate references in a list (JS ===)
fn[T] has_duplicate_refs(items : Array[T]) -> Bool {
  let seen = ref_map_new()
  for item in items {
    let key = @js.any(item)
    if ref_map_has(seen, key) {
      return true
    }
    ref_map_set(seen, key, 1)
  }
  false
}

///|
/// Find an entry index by item reference using a map
fn[T] find_entry_index(
  map : @js.Any,
  item : T,
  used_indices : Array[Bool],
  old_entries : Array[ItemEntry[T]],
) -> Int {
  let key = @js.any(item)
  let first = ref_map_get_or_minus1(map, key)
  if first >= 0 && not(used_indices[first]) {
    return first
  }
  // Duplicate references: find another unused entry with the same reference
  for i, entry in old_entries {
    if not(used_indices[i]) && ref_equal(entry.item, item) {
      return i
    }
  }
  -1
}

///|
/// Move a list of nodes before cursor, preserving order
fn move_nodes_before(
  parent : @js_dom.Node,
  nodes : Array[@js_dom.Node],
  cursor : @js_dom.Node,
) -> Unit {
  // Move in order to preserve node sequence
  for node in nodes {
    move_before(parent, node, Some(cursor)) |> ignore
  }
}

///|
/// Safely remove multiple nodes
fn safe_remove_nodes(
  parent : @js_dom.Node,
  nodes : Array[@js_dom.Node],
) -> Unit {
  for node in nodes {
    safe_remove_child(parent, node)
  }
}

///|
/// Reconcile items with DOM nodes using reference equality
///
/// Algorithm:
/// 1. Build a lookup from old entries (item -> entry) using reference equality
/// 2. Process new items in order:
///    - If same reference exists in old entries → reuse DOM, use moveBefore
///    - If not found → create new DOM with render_item
/// 3. Remove DOM nodes for items no longer present
/// 4. Return new ItemEntry array
///
/// Parameters:
/// - parent: The parent DOM node containing the items
/// - old_entries: Previous item-DOM mappings
/// - new_items: New items array
/// - render_item: Function to render a new item to DOM
/// - end_marker: Comment node marking the end of the For region
///
/// Returns: New ItemEntry array reflecting current items
pub fn[T] reconcile_items(
  parent : @js_dom.Node,
  old_entries : Array[ItemEntry[T]],
  new_items : Array[T],
  render_item : (T, Int) -> @js_dom.Node,
  end_marker : @js_dom.Node,
) -> Array[ItemEntry[T]] {
  let n = new_items.length()

  // Handle empty case - dispose and remove all old entries
  if n == 0 {
    for entry in old_entries {
      // Dispose first to run cleanups, then remove DOM
      (entry.dispose)()
      safe_remove_nodes(parent, entry.nodes)
    }
    return []
  }

  // Duplicate references are ambiguous for ref-based reconciliation.
  // Fall back to full re-render to keep DOM consistent.
  if has_duplicate_refs(new_items) {
    for entry in old_entries {
      (entry.dispose)()
      safe_remove_nodes(parent, entry.nodes)
    }
    let fresh_entries : Array[ItemEntry[T]] = []
    for i, item in new_items {
      let dom = render_item(item, i)
      let nodes = collect_dom_nodes(dom)
      if nodes.length() == 0 {
        let placeholder = @js_dom.document().createComment("empty")
        parent.insertBefore(placeholder, Some(end_marker)) |> ignore
        fresh_entries.push(
          ItemEntry::new_with_nodes_and_dispose(item, [placeholder], fn() {  }),
        )
      } else {
        parent.insertBefore(dom, Some(end_marker)) |> ignore
        fresh_entries.push(
          ItemEntry::new_with_nodes_and_dispose(item, nodes, fn() {  }),
        )
      }
    }
    return fresh_entries
  }
  let new_entries : Array[ItemEntry[T]] = []
  for j in 0..<n {
    new_entries.push(ItemEntry::new(new_items[0], end_marker))
  }
  let used_indices : Array[Bool] = Array::make(old_entries.length(), false)
  let index_map = build_entry_index_map(old_entries)

  // Process items in REVERSE order (last to first)
  // This allows us to efficiently check if nodes are already in correct position
  // cursor tracks "what should be the next sibling of the current item"
  let cursor : Ref[@js_dom.Node] = Ref::new(end_marker)

  // Process from last to first
  let last = n - 1
  for i in last>=..0 {
    let item = new_items[i]
    let old_index = find_entry_index(index_map, item, used_indices, old_entries)
    if old_index >= 0 {
      // Reuse existing DOM node
      let entry = old_entries[old_index]
      used_indices[old_index] = true

      // Only move if not already at correct position
      // The node is at correct position if its nextSibling equals cursor
      if entry.nodes.length() > 0 {
        if not(next_sibling_is(entry.last, cursor.val)) {
          move_nodes_before(parent, entry.nodes, cursor.val)
        }
        cursor.val = entry.dom
      }
      new_entries[i] = entry
    } else {
      // Create new DOM node
      let dom = render_item(item, i)
      let nodes = collect_dom_nodes(dom)
      if nodes.length() == 0 {
        let placeholder = @js_dom.document().createComment("empty")
        parent.insertBefore(placeholder, Some(cursor.val)) |> ignore
        let placeholder_nodes = [placeholder]
        cursor.val = placeholder
        new_entries[i] = ItemEntry::new_with_nodes_and_dispose(
          item,
          placeholder_nodes,
          fn() {  },
        )
      } else {
        parent.insertBefore(dom, Some(cursor.val)) |> ignore
        cursor.val = nodes[0]
        // New items get no-op dispose - actual dispose is set by for_each
        new_entries[i] = ItemEntry::new_with_nodes_and_dispose(item, nodes, fn() {

        })
      }
    }
  }

  // Remove unused DOM nodes and dispose their owner scopes
  for i, entry in old_entries {
    if not(used_indices[i]) {
      // Dispose first to run cleanups, then remove DOM
      (entry.dispose)()
      safe_remove_nodes(parent, entry.nodes)
    }
  }
  new_entries
}

///|
/// Safely remove a child node, handling cases where the node may have been
/// moved to a different parent (e.g., during moveBefore fallback to insertBefore)
extern "js" fn safe_remove_child(parent : @js_dom.Node, child : @js_dom.Node) =
  #| (parent, child) => {
  #|   try {
  #|     // Check if the child is actually a child of this parent
  #|     if (child.parentNode === parent) {
  #|       parent.removeChild(child);
  #|     } else if (child.parentNode) {
  #|       // Node was moved to a different parent, remove from there
  #|       child.parentNode.removeChild(child);
  #|     }
  #|     // If child.parentNode is null, node is already detached
  #|   } catch (e) {
  #|     // Ignore errors - node may already be removed or in invalid state
  #|   }
  #| }

///|
/// Simplified reconciliation for render.mbt's for_each
/// Uses a DocumentFragment as container with a placeholder comment
pub fn[T] reconcile_for_each(
  entries_ref : Ref[Array[ItemEntry[T]]],
  placeholder : @js_dom.Node,
  new_items : Array[T],
  render_item : (T, Int) -> @js_dom.Node,
) -> Unit {
  if placeholder.parentNode() is Some(parent) {
    entries_ref.val = reconcile_items(
      parent,
      entries_ref.val,
      new_items,
      render_item,
      placeholder,
    )
  }
}

///|
/// Reconciliation with dispose function support
/// render_item returns both the DOM node and a dispose function for cleanup
pub fn[T] reconcile_for_each_with_dispose(
  entries_ref : Ref[Array[ItemEntry[T]]],
  placeholder : @js_dom.Node,
  new_items : Array[T],
  render_item : (T, Int) -> (@js_dom.Node, () -> Unit),
) -> Unit {
  if placeholder.parentNode() is Some(parent) {
    entries_ref.val = reconcile_items_with_dispose(
      parent,
      entries_ref.val,
      new_items,
      render_item,
      placeholder,
    )
  }
}

///|
/// Reconcile items with dispose support
/// Similar to reconcile_items but render_item returns (Node, dispose)
pub fn[T] reconcile_items_with_dispose(
  parent : @js_dom.Node,
  old_entries : Array[ItemEntry[T]],
  new_items : Array[T],
  render_item : (T, Int) -> (@js_dom.Node, () -> Unit),
  end_marker : @js_dom.Node,
) -> Array[ItemEntry[T]] {
  let n = new_items.length()

  // Handle empty case - dispose and remove all old entries
  if n == 0 {
    for entry in old_entries {
      (entry.dispose)()
      safe_remove_nodes(parent, entry.nodes)
    }
    return []
  }

  // Duplicate references are ambiguous for ref-based reconciliation.
  // Fall back to full re-render to keep DOM consistent.
  if has_duplicate_refs(new_items) {
    for entry in old_entries {
      (entry.dispose)()
      safe_remove_nodes(parent, entry.nodes)
    }
    let fresh_entries : Array[ItemEntry[T]] = []
    for i, item in new_items {
      let (dom, dispose) = render_item(item, i)
      let nodes = collect_dom_nodes(dom)
      if nodes.length() == 0 {
        let placeholder = @js_dom.document().createComment("empty")
        parent.insertBefore(placeholder, Some(end_marker)) |> ignore
        fresh_entries.push(
          ItemEntry::new_with_nodes_and_dispose(item, [placeholder], dispose),
        )
      } else {
        parent.insertBefore(dom, Some(end_marker)) |> ignore
        fresh_entries.push(
          ItemEntry::new_with_nodes_and_dispose(item, nodes, dispose),
        )
      }
    }
    return fresh_entries
  }
  let new_entries : Array[ItemEntry[T]] = []
  for j in 0..<n {
    new_entries.push(ItemEntry::new(new_items[0], end_marker))
  }
  let used_indices : Array[Bool] = Array::make(old_entries.length(), false)
  let index_map = build_entry_index_map(old_entries)
  let cursor : Ref[@js_dom.Node] = Ref::new(end_marker)

  // Process from last to first
  let last = n - 1
  for i in last>=..0 {
    let item = new_items[i]
    let old_index = find_entry_index(index_map, item, used_indices, old_entries)
    if old_index >= 0 {
      // Reuse existing entry (including its dispose function)
      let entry = old_entries[old_index]
      used_indices[old_index] = true
      if entry.nodes.length() > 0 {
        if not(next_sibling_is(entry.last, cursor.val)) {
          move_nodes_before(parent, entry.nodes, cursor.val)
        }
        cursor.val = entry.dom
      }
      new_entries[i] = entry
    } else {
      // Create new DOM node with dispose
      let (dom, dispose) = render_item(item, i)
      let nodes = collect_dom_nodes(dom)
      if nodes.length() == 0 {
        let placeholder = @js_dom.document().createComment("empty")
        parent.insertBefore(placeholder, Some(cursor.val)) |> ignore
        let placeholder_nodes = [placeholder]
        cursor.val = placeholder
        new_entries[i] = ItemEntry::new_with_nodes_and_dispose(
          item, placeholder_nodes, dispose,
        )
      } else {
        parent.insertBefore(dom, Some(cursor.val)) |> ignore
        cursor.val = nodes[0]
        new_entries[i] = ItemEntry::new_with_nodes_and_dispose(
          item, nodes, dispose,
        )
      }
    }
  }

  // Remove unused DOM nodes and dispose their owner scopes
  for i, entry in old_entries {
    if not(used_indices[i]) {
      (entry.dispose)()
      safe_remove_nodes(parent, entry.nodes)
    }
  }
  new_entries
}
