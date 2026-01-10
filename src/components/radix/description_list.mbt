///|
/// DescriptionList component for Luna (Headless)
/// Key-value pair display (definition list)

///|
/// Create a headless description list
/// Outputs: <dl class="radix-description-list">children</dl>
pub fn radix_description_list(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "dl",
    [("class", @luna.attr_static("radix-description-list"))],
    children,
  )
}

///|
/// Create a headless description list item (term + details pair)
/// Outputs: <div class="radix-description-item">children</div>
pub fn radix_description_item(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [("class", @luna.attr_static("radix-description-item"))],
    children,
  )
}

///|
/// Create a headless description term (key)
/// Outputs: <dt class="radix-description-term">children</dt>
pub fn radix_description_term(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "dt",
    [("class", @luna.attr_static("radix-description-term"))],
    children,
  )
}

///|
/// Create a headless description details (value)
/// Outputs: <dd class="radix-description-details">children</dd>
pub fn radix_description_details(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(
    "dd",
    [("class", @luna.attr_static("radix-description-details"))],
    children,
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the description list component
fn description_list_styles() -> String {
  let css =
    #|:host {
    #|  display: block;
    #|}
    #|
    #|.description-list {
    #|  margin: 0;
    #|}
    #|
    #|.description-item {
    #|  display: flex;
    #|  flex-direction: column;
    #|  padding: 0.75rem 0;
    #|  border-bottom: 1px solid #e4e4e7;
    #|}
    #|
    #|.description-item:last-child {
    #|  border-bottom: none;
    #|}
    #|
    #|@media (min-width: 640px) {
    #|  .description-item {
    #|    flex-direction: row;
    #|    gap: 1rem;
    #|  }
    #|}
    #|
    #|.description-term {
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  color: #71717a;
    #|  margin: 0;
    #|}
    #|
    #|@media (min-width: 640px) {
    #|  .description-term {
    #|    flex-shrink: 0;
    #|    width: 10rem;
    #|  }
    #|}
    #|
    #|.description-details {
    #|  font-size: 0.875rem;
    #|  color: #18181b;
    #|  margin: 0.25rem 0 0 0;
    #|}
    #|
    #|@media (min-width: 640px) {
    #|  .description-details {
    #|    flex: 1;
    #|    margin: 0;
    #|  }
    #|}
  css
}

///|
/// Create a styled description list with Declarative Shadow DOM
pub fn radix_description_list_styled(
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let css = match styles {
    Some(s) => s
    None => description_list_styles()
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
  @luna.h("radix-description-list", [], all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a description list with luna/css atomic styles
pub fn radix_description_list_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = description_list_base_styles()
  @luna.h("dl", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a description item with luna/css atomic styles
pub fn radix_description_item_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = description_item_styles()
  @luna.h("div", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a description term with luna/css atomic styles
pub fn radix_description_term_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = description_term_styles()
  @luna.h("dt", [("class", @luna.attr_static(class_names))], children)
}

///|
/// Create a description details with luna/css atomic styles
pub fn radix_description_details_ucss(
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let class_names = description_details_styles()
  @luna.h("dd", [("class", @luna.attr_static(class_names))], children)
}
