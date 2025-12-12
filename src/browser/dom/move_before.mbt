///|
/// moveBefore API - Experimental DOM API for moving nodes without losing state
/// https://developer.mozilla.org/en-US/docs/Web/API/Element/moveBefore
///
/// Unlike insertBefore which removes and re-inserts (losing state like animations,
/// focus, iframe content), moveBefore preserves the node's state.
///
/// Browser support: Limited (Chrome 133+, Firefox experimental)

///|
/// Check if moveBefore is supported in the current environment
pub fn is_move_before_supported() -> Bool {
  move_before_supported()
}

///|
extern "js" fn move_before_supported() -> Bool =
  #| () => typeof Element.prototype.moveBefore === 'function'

///|
/// Move a node before a reference node, preserving state (animations, focus, etc.)
/// Falls back to insertBefore if moveBefore is not supported.
///
/// Parameters:
/// - parent: The parent node to move the child within
/// - node: The node to move
/// - ref_node: The reference node (node will be inserted before this), or None for end
///
/// Returns the moved node
pub fn move_before(
  parent : @js_dom.Node,
  node : @js_dom.Node,
  ref_node : @js_dom.Node?
) -> @js_dom.Node {
  match ref_node {
    Some(reference) => move_before_impl(parent, node, reference)
    None => move_before_impl_null(parent, node)
  }
}

///|
extern "js" fn move_before_impl(
  parent : @js_dom.Node,
  node : @js_dom.Node,
  ref_node : @js_dom.Node
) -> @js_dom.Node =
  #| (parent, node, refNode) => {
  #|   if (typeof parent.moveBefore === 'function') {
  #|     parent.moveBefore(node, refNode);
  #|     return node;
  #|   } else {
  #|     return parent.insertBefore(node, refNode);
  #|   }
  #| }

///|
extern "js" fn move_before_impl_null(
  parent : @js_dom.Node,
  node : @js_dom.Node
) -> @js_dom.Node =
  #| (parent, node) => {
  #|   if (typeof parent.moveBefore === 'function') {
  #|     parent.moveBefore(node, null);
  #|     return node;
  #|   } else {
  #|     return parent.insertBefore(node, null);
  #|   }
  #| }

///|
/// Force use of moveBefore (throws if not supported)
pub fn move_before_strict(
  parent : @js_dom.Node,
  node : @js_dom.Node,
  ref_node : @js_dom.Node?
) -> @js_dom.Node {
  match ref_node {
    Some(reference) => move_before_strict_impl(parent, node, reference)
    None => move_before_strict_impl_null(parent, node)
  }
}

///|
extern "js" fn move_before_strict_impl(
  parent : @js_dom.Node,
  node : @js_dom.Node,
  ref_node : @js_dom.Node
) -> @js_dom.Node =
  #| (parent, node, refNode) => {
  #|   parent.moveBefore(node, refNode);
  #|   return node;
  #| }

///|
extern "js" fn move_before_strict_impl_null(
  parent : @js_dom.Node,
  node : @js_dom.Node
) -> @js_dom.Node =
  #| (parent, node) => {
  #|   parent.moveBefore(node, null);
  #|   return node;
  #| }
