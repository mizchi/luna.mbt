///|
/// Tree component for Luna (Headless)
/// Hierarchical tree view for nested data

///|
/// Create a headless tree root
/// Outputs: <div class="radix-tree" role="tree">children</div>
pub fn radix_tree(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-tree")),
      ("role", @luna.attr_static("tree")),
    ],
    children,
  )
}

///|
/// Create a headless tree item (branch or leaf)
/// Outputs: <div class="radix-tree-item" role="treeitem">children</div>
pub fn radix_tree_item(
  expanded? : Bool,
  selected? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-tree-item")),
    ("role", @luna.attr_static("treeitem")),
  ]

  match expanded {
    Some(true) => {
      attrs.push(("data-expanded", @luna.attr_static("")))
      attrs.push(("aria-expanded", @luna.attr_static("true")))
    }
    Some(false) => attrs.push(("aria-expanded", @luna.attr_static("false")))
    None => ()
  }

  match selected {
    Some(true) => {
      attrs.push(("data-selected", @luna.attr_static("")))
      attrs.push(("aria-selected", @luna.attr_static("true")))
    }
    _ => ()
  }

  @luna.h("div", attrs, children)
}

///|
/// Create a headless tree item content (the clickable row)
/// Outputs: <div class="radix-tree-item-content">children</div>
pub fn radix_tree_item_content(
  level? : Int,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-tree-item-content")),
  ]

  match level {
    Some(l) => attrs.push(("data-level", @luna.attr_static(l.to_string())))
    None => ()
  }

  @luna.h("div", attrs, children)
}

///|
/// Create a headless tree toggle (expand/collapse button)
/// Outputs: <button class="radix-tree-toggle">children</button>
pub fn radix_tree_toggle(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "button",
    [
      ("class", @luna.attr_static("radix-tree-toggle")),
      ("type", @luna.attr_static("button")),
    ],
    children,
  )
}

///|
/// Create a headless tree icon slot
/// Outputs: <span class="radix-tree-icon">children</span>
pub fn radix_tree_icon(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("span", [("class", @luna.attr_static("radix-tree-icon"))], children)
}

///|
/// Create a headless tree label
/// Outputs: <span class="radix-tree-label">children</span>
pub fn radix_tree_label(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("span", [("class", @luna.attr_static("radix-tree-label"))], children)
}

///|
/// Create a headless tree group (nested children container)
/// Outputs: <div class="radix-tree-group" role="group">children</div>
pub fn radix_tree_group(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("radix-tree-group")),
      ("role", @luna.attr_static("group")),
    ],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the tree component
fn tree_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.tree {
    #|  font-size: 0.875rem;
    #|}
    #|
    #|.tree-item {
    #|  outline: none;
    #|}
    #|
    #|.tree-item-content {
    #|  display: flex;
    #|  align-items: center;
    #|  gap: 0.25rem;
    #|  padding: 0.25rem 0.5rem;
    #|  border-radius: 4px;
    #|  cursor: pointer;
    #|  transition: background 0.15s ease;
    #|}
    #|
    #|.tree-item-content:hover {
    #|  background: #f4f4f5;
    #|}
    #|
    #|[data-selected] > .tree-item-content {
    #|  background: #e4e4e7;
    #|}
    #|
    #|.tree-item-content[data-level="1"] { padding-left: 1.5rem; }
    #|.tree-item-content[data-level="2"] { padding-left: 2.5rem; }
    #|.tree-item-content[data-level="3"] { padding-left: 3.5rem; }
    #|.tree-item-content[data-level="4"] { padding-left: 4.5rem; }
    #|.tree-item-content[data-level="5"] { padding-left: 5.5rem; }
    #|
    #|.tree-toggle {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 1.25rem;
    #|  height: 1.25rem;
    #|  padding: 0;
    #|  background: transparent;
    #|  border: none;
    #|  cursor: pointer;
    #|  color: #71717a;
    #|  flex-shrink: 0;
    #|  transition: transform 0.15s ease;
    #|}
    #|
    #|[data-expanded] > .tree-item-content .tree-toggle {
    #|  transform: rotate(90deg);
    #|}
    #|
    #|.tree-icon {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  width: 1.25rem;
    #|  height: 1.25rem;
    #|  color: #71717a;
    #|  flex-shrink: 0;
    #|}
    #|
    #|.tree-label {
    #|  flex: 1;
    #|  color: #18181b;
    #|  white-space: nowrap;
    #|  overflow: hidden;
    #|  text-overflow: ellipsis;
    #|}
    #|
    #|.tree-group {
    #|  display: none;
    #|}
    #|
    #|[data-expanded] > .tree-group {
    #|  display: block;
    #|}
  css
}

///|
/// Create a styled tree with Declarative Shadow DOM
pub fn radix_tree_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => tree_styles()
  }

  let template_children : Array[@luna.Node[Unit]] = [
    @luna.h("style", [], [@luna.text(css)]),
    @luna.h("slot", [], []),
  ]

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

  @luna.h("radix-tree", [("role", @luna.attr_static("tree"))], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a tree with luna/css atomic styles
pub fn radix_tree_ucss(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  let class_names = tree_base_styles()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static(class_names)),
      ("role", @luna.attr_static("tree")),
    ],
    children,
  )
}

///|
/// Create a tree item content with luna/css atomic styles
pub fn radix_tree_item_content_ucss(
  level? : Int,
  selected? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let mut class_names = tree_item_content_styles()

  match selected {
    Some(true) =>
      class_names = class_names + " " + @css.styles([("background", "#e4e4e7")])
    _ => ()
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
  ]

  match level {
    Some(l) => attrs.push(("data-level", @luna.attr_static(l.to_string())))
    None => ()
  }

  @luna.h("div", attrs, children)
}

///|
/// Create a tree toggle with luna/css atomic styles
pub fn radix_tree_toggle_ucss(
  expanded? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let mut class_names = tree_toggle_styles()

  match expanded {
    Some(true) =>
      class_names = class_names + " " + @css.styles([("transform", "rotate(90deg)")])
    _ => ()
  }

  @luna.h(
    "button",
    [
      ("class", @luna.attr_static(class_names)),
      ("type", @luna.attr_static("button")),
    ],
    children,
  )
}
