///| Diff algorithm - generates patches from VNode comparison
///| Extracted from proto_vdom

///|
/// Patch operations - represents changes to apply to the DOM
enum Patch[H] {
  CreateElement(VNode[H], @js_dom.Node, @js_dom.Node?) // vnode, parent, before
  RemoveNode(@js_dom.Node, @js_dom.Node) // node, parent
  ReplaceNode(@js_dom.Node, VNode[H], @js_dom.Node) // old_node, new_vnode, parent
  UpdateProps(@js_dom.Element, Props[H], Props[H]) // element, old_props, new_props
  UpdateText(@js_dom.Text, String) // text_node, new_text
  ReconcileChildren(
    @js_dom.Element,
    Array[VNode[H]],
    Array[VNode[H]],
    Array[@js_dom.Node]
  ) // parent, old_vnodes, new_vnodes, old_dom_nodes
}

///|
/// Diff two optional VNodes and generate patches
pub fn[H] diff(
  old_vnode : VNode[H]?,
  new_vnode : VNode[H]?,
  dom_node : @js_dom.Node?,
  parent : @js_dom.Node?,
) -> Array[Patch[H]] {
  match (old_vnode, new_vnode) {
    (None, Some(new_v)) =>
      match parent {
        Some(p) => [Patch::CreateElement(new_v, p, None)]
        None => []
      }
    (Some(_), None) =>
      match (dom_node, parent) {
        (Some(node), Some(p)) => [Patch::RemoveNode(node, p)]
        _ => []
      }
    (Some(old_v), Some(new_v)) =>
      match dom_node {
        Some(node) => diff_nodes(old_v, new_v, node)
        None => []
      }
    (None, None) => []
  }
}

///|
/// Diff two non-null VNodes
fn[H] diff_nodes(
  old : VNode[H],
  new : VNode[H],
  dom_node : @js_dom.Node,
) -> Array[Patch[H]] {
  match (old, new) {
    (Empty, Empty) => []
    (Text(old_text), Text(new_text)) =>
      if old_text != new_text {
        let text_node : @js_dom.Text = dom_node.as_any().cast()
        [Patch::UpdateText(text_node, new_text)]
      } else {
        []
      }
    (Element(old_el), Element(new_el)) =>
      if old_el.tag != new_el.tag {
        match dom_node.parentNode() {
          Some(parent) =>
            [Patch::ReplaceNode(dom_node, Element(new_el), parent)]
          None => []
        }
      } else {
        let patches : Array[Patch[H]] = []
        let dom_element : @js_dom.Element = dom_node.as_any().cast()
        if props_differ(old_el.props, new_el.props) {
          patches.push(
            Patch::UpdateProps(dom_element, old_el.props, new_el.props),
          )
        }
        let old_dom_children = dom_element.as_node().childNodes()
        patches.push(
          Patch::ReconcileChildren(
            dom_element,
            old_el.children,
            new_el.children,
            old_dom_children,
          ),
        )
        patches
      }
    (Fragment(old_children), Fragment(new_children)) => {
      let dom_element : @js_dom.Element = dom_node.as_any().cast()
      let old_dom_children = dom_element.as_node().childNodes()
      [
        Patch::ReconcileChildren(
          dom_element, old_children, new_children, old_dom_children,
        ),
      ]
    }
    _ =>
      match dom_node.parentNode() {
        Some(parent) => [Patch::ReplaceNode(dom_node, new, parent)]
        None => []
      }
  }
}

///|
fn[H] props_differ(old_props : Props[H], new_props : Props[H]) -> Bool {
  not(compare_props(old_props, new_props))
}
