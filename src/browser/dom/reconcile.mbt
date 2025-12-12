///| Solid-style reference-based reconciliation for DOM reuse
///|
///| Unlike React's key-based reconciliation, this approach tracks item references
///| using JavaScript's === operator. When items are reordered, their DOM nodes
///| are moved rather than recreated.

///|
/// Check if two values are the same reference (physical equality)
/// Uses JavaScript's === operator for reference comparison
extern "js" fn ref_equal_any(a : @core.Any, b : @core.Any) -> Bool =
  #| (a, b) => a === b

///|
/// Check if two values are the same reference (type-safe wrapper)
pub fn[T] ref_equal(a : T, b : T) -> Bool {
  ref_equal_any(@core.any(a), @core.any(b))
}

///|
/// Check if a node's next sibling matches the expected node
extern "js" fn next_sibling_is(
  node : @js_dom.Node,
  expected : @js_dom.Node
) -> Bool =
  #| (node, expected) => node.nextSibling === expected

///|
/// Item-DOM mapping entry
/// Stores the association between an item reference and its DOM node
pub(all) struct ItemEntry[T] {
  item : T
  dom : @js_dom.Node
}

///|
/// Create a new ItemEntry
pub fn[T] ItemEntry::new(item : T, dom : @js_dom.Node) -> ItemEntry[T] {
  { item, dom }
}

///|
/// Find an entry by item reference in the entries array
/// Returns the index if found, -1 otherwise
fn[T] find_entry_index(entries : Array[ItemEntry[T]], item : T) -> Int {
  for i = 0; i < entries.length(); i = i + 1 {
    if ref_equal(entries[i].item, item) {
      return i
    }
  }
  -1
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

  // Handle empty case - just remove all old entries
  if n == 0 {
    for i = 0; i < old_entries.length(); i = i + 1 {
      parent.removeChild(old_entries[i].dom) |> ignore
    }
    return []
  }

  let new_entries : Array[ItemEntry[T]] = []
  for j = 0; j < n; j = j + 1 {
    new_entries.push({ item: new_items[0], dom: end_marker })
  }
  let used_indices : Array[Bool] = Array::make(old_entries.length(), false)

  // Process items in REVERSE order (last to first)
  // This allows us to efficiently check if nodes are already in correct position
  // cursor tracks "what should be the next sibling of the current item"
  let cursor : Ref[@js_dom.Node] = { val: end_marker }

  // Process from last to first
  for i = n - 1; i >= 0; i = i - 1 {
    let item = new_items[i]
    let old_index = find_entry_index(old_entries, item)

    if old_index >= 0 {
      // Reuse existing DOM node
      let entry = old_entries[old_index]
      used_indices[old_index] = true

      // Only move if not already at correct position
      // The node is at correct position if its nextSibling equals cursor
      if not(next_sibling_is(entry.dom, cursor.val)) {
        move_before(parent, entry.dom, Some(cursor.val)) |> ignore
      }

      cursor.val = entry.dom
      new_entries[i] = entry
    } else {
      // Create new DOM node
      let dom = render_item(item, i)
      parent.insertBefore(dom, Some(cursor.val)) |> ignore
      cursor.val = dom
      new_entries[i] = { item, dom }
    }
  }

  // Remove unused DOM nodes
  for i = 0; i < old_entries.length(); i = i + 1 {
    if not(used_indices[i]) {
      parent.removeChild(old_entries[i].dom) |> ignore
    }
  }

  new_entries
}

///|
/// Simplified reconciliation for render.mbt's for_each
/// Uses a DocumentFragment as container with a placeholder comment
pub fn[T] reconcile_for_each(
  entries_ref : Ref[Array[ItemEntry[T]]],
  placeholder : @js_dom.Node,
  new_items : Array[T],
  render_item : (T, Int) -> @js_dom.Node,
) -> Unit {
  match placeholder.parentNode() {
    Some(parent) => {
      entries_ref.val = reconcile_items(
        parent,
        entries_ref.val,
        new_items,
        render_item,
        placeholder,
      )
    }
    None => ()
  }
}
