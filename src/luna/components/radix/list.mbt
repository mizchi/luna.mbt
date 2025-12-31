///|
/// List component for Luna (Headless)
/// Ordered and unordered lists with items

///|
/// List type enum
pub enum ListType {
  Unordered
  Ordered
}

///|
/// Create a headless list
/// Outputs: <ul/ol class="radix-list">children</ul/ol>
pub fn radix_list(
  list_type? : ListType,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let tag = match list_type {
    Some(Ordered) => "ol"
    _ => "ul"
  }

  @luna.h(tag, [("class", @luna.attr_static("radix-list"))], children)
}

///|
/// Create a headless list item
/// Outputs: <li class="radix-list-item">children</li>
pub fn radix_list_item(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.h("li", [("class", @luna.attr_static("radix-list-item"))], children)
}

///|
/// Create a headless list item with icon
/// Outputs: <li class="radix-list-item"><span class="icon">icon</span><span class="content">children</span></li>
pub fn radix_list_item_icon(
  icon : Array[@luna.Node[Unit]],
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "li",
    [("class", @luna.attr_static("radix-list-item radix-list-item-icon"))],
    [
      @luna.h(
        "span",
        [("class", @luna.attr_static("radix-list-item-icon-slot"))],
        icon,
      ),
      @luna.h(
        "span",
        [("class", @luna.attr_static("radix-list-item-content"))],
        children,
      ),
    ],
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the list component
fn list_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.list {
    #|  margin: 0;
    #|  padding: 0 0 0 1.5rem;
    #|}
    #|
    #|.list-item {
    #|  margin: 0.25rem 0;
    #|  line-height: 1.5;
    #|}
    #|
    #|.list-item-icon {
    #|  display: flex;
    #|  align-items: flex-start;
    #|  gap: 0.5rem;
    #|  list-style: none;
    #|  margin-left: -1.5rem;
    #|}
    #|
    #|.list-item-icon-slot {
    #|  flex-shrink: 0;
    #|  width: 1.25rem;
    #|  height: 1.25rem;
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  margin-top: 0.125rem;
    #|  color: #71717a;
    #|}
    #|
    #|.list-item-content {
    #|  flex: 1;
    #|}
    #|
    #|ul.list {
    #|  list-style-type: disc;
    #|}
    #|
    #|ol.list {
    #|  list-style-type: decimal;
    #|}
  css
}

///|
/// Create a styled list with Declarative Shadow DOM
pub fn radix_list_styled(
  list_type? : ListType,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => list_styles()
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

  let tag = match list_type {
    Some(Ordered) => "radix-list-ol"
    _ => "radix-list-ul"
  }

  @luna.h(tag, [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a list with luna/css atomic styles
pub fn radix_list_ucss(
  list_type? : ListType,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let tag = match list_type {
    Some(Ordered) => "ol"
    _ => "ul"
  }

  let class_names = list_base_styles()
  @luna.h(tag, [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a list item with luna/css atomic styles
pub fn radix_list_item_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = list_item_styles()
  @luna.h("li", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a list item with icon using luna/css atomic styles
pub fn radix_list_item_icon_ucss(
  icon : Array[@luna.Node[Unit]],
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let item_class = list_item_icon_styles()
  let icon_class = list_item_icon_slot_styles()
  let content_class = list_item_content_styles()

  @luna.h(
    "li",
    [("class", @luna.attr_static(item_class))],
    [
      @luna.h("span", [("class", @luna.attr_static(icon_class))], icon),
      @luna.h("span", [("class", @luna.attr_static(content_class))], children),
    ],
  )
}
