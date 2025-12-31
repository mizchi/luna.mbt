///|
/// Rating component for Luna (Headless)
/// Star rating input/display

///|
/// Create a headless rating root
/// Outputs: <div class="radix-rating" role="radiogroup">children</div>
pub fn radix_rating(
  value? : Int,
  max? : Int,
  read_only? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let max_val = match max {
    Some(m) => m
    None => 5
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-rating")),
    ("role", @luna.attr_static("radiogroup")),
    ("data-max", @luna.attr_static(max_val.to_string())),
  ]

  match value {
    Some(v) => attrs.push(("data-value", @luna.attr_static(v.to_string())))
    None => ()
  }

  match read_only {
    Some(true) => attrs.push(("data-readonly", @luna.attr_static("")))
    _ => ()
  }

  @luna.h("div", attrs, children)
}

///|
/// Create a headless rating item (single star)
/// Outputs: <button class="radix-rating-item" role="radio">children</button>
pub fn radix_rating_item(
  value : Int,
  filled? : Bool,
  half? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_filled = match filled {
    Some(true) => true
    _ => false
  }
  let is_half = match half {
    Some(true) => true
    _ => false
  }

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static("radix-rating-item")),
    ("role", @luna.attr_static("radio")),
    ("data-value", @luna.attr_static(value.to_string())),
    ("aria-checked", @luna.attr_static(if is_filled { "true" } else { "false" })),
  ]

  if is_filled {
    attrs.push(("data-filled", @luna.attr_static("")))
  }
  if is_half {
    attrs.push(("data-half", @luna.attr_static("")))
  }

  @luna.h("button", attrs, children)
}

///|
/// Create a default star icon for rating
/// Outputs: <svg class="radix-rating-star">...</svg>
pub fn radix_rating_star() -> @luna.Node[Unit] {
  @luna.h(
    "svg",
    [
      ("class", @luna.attr_static("radix-rating-star")),
      ("viewBox", @luna.attr_static("0 0 24 24")),
      ("fill", @luna.attr_static("currentColor")),
    ],
    [
      @luna.h(
        "path",
        [
          (
            "d",
            @luna.attr_static(
              "M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z",
            ),
          ),
        ],
        [],
      ),
    ],
  )
}

// =============================================================================
// Styled version with DSD (Declarative Shadow DOM)
// =============================================================================

///|
/// CSS styles for the rating component
fn rating_styles() -> String {
  let css =
    #|:host {
    #|  display: inline-block;
    #|}
    #|
    #|.rating {
    #|  display: inline-flex;
    #|  gap: 0.125rem;
    #|}
    #|
    #|.rating-item {
    #|  display: flex;
    #|  align-items: center;
    #|  justify-content: center;
    #|  padding: 0;
    #|  background: transparent;
    #|  border: none;
    #|  cursor: pointer;
    #|  color: #d4d4d8;
    #|  transition: color 0.15s ease, transform 0.15s ease;
    #|}
    #|
    #|.rating-item:hover {
    #|  transform: scale(1.1);
    #|}
    #|
    #|.rating-item[data-filled] {
    #|  color: #fbbf24;
    #|}
    #|
    #|.rating-item[data-half] {
    #|  color: #fbbf24;
    #|}
    #|
    #|[data-readonly] .rating-item {
    #|  cursor: default;
    #|}
    #|
    #|[data-readonly] .rating-item:hover {
    #|  transform: none;
    #|}
    #|
    #|.rating-star {
    #|  width: 1.25rem;
    #|  height: 1.25rem;
    #|}
  css
}

///|
/// Create a styled rating with Declarative Shadow DOM
pub fn radix_rating_styled(
  value? : Int,
  max? : Int,
  read_only? : Bool,
  styles? : String,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let max_val = match max {
    Some(m) => m
    None => 5
  }

  let css = match styles {
    Some(s) => s
    None => rating_styles()
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

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("role", @luna.attr_static("radiogroup")),
    ("data-max", @luna.attr_static(max_val.to_string())),
  ]

  match value {
    Some(v) => attrs.push(("data-value", @luna.attr_static(v.to_string())))
    None => ()
  }

  match read_only {
    Some(true) => attrs.push(("data-readonly", @luna.attr_static("")))
    _ => ()
  }

  @luna.h("radix-rating", attrs, all_children)
}

// =============================================================================
// Utility CSS version (luna/css integration)
// =============================================================================

///|
/// Create a rating with luna/css atomic styles
pub fn radix_rating_ucss(
  value? : Int,
  max? : Int,
  read_only? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let max_val = match max {
    Some(m) => m
    None => 5
  }

  let class_names = rating_base_styles()

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("role", @luna.attr_static("radiogroup")),
    ("data-max", @luna.attr_static(max_val.to_string())),
  ]

  match value {
    Some(v) => attrs.push(("data-value", @luna.attr_static(v.to_string())))
    None => ()
  }

  match read_only {
    Some(true) => attrs.push(("data-readonly", @luna.attr_static("")))
    _ => ()
  }

  @luna.h("div", attrs, children)
}

///|
/// Create a rating item with luna/css atomic styles
pub fn radix_rating_item_ucss(
  value : Int,
  filled? : Bool,
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  let is_filled = match filled {
    Some(true) => true
    _ => false
  }

  let class_names = rating_item_styles(filled)

  let attrs : Array[(String, @luna.Attr[Unit])] = [
    ("class", @luna.attr_static(class_names)),
    ("role", @luna.attr_static("radio")),
    ("data-value", @luna.attr_static(value.to_string())),
    ("aria-checked", @luna.attr_static(if is_filled { "true" } else { "false" })),
  ]

  if is_filled {
    attrs.push(("data-filled", @luna.attr_static("")))
  }

  @luna.h("button", attrs, children)
}
