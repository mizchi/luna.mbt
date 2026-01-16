// Card component - Light DOM WebComponent
// Uses @css for styling

///|
using @luna {fragment, h, text, text_dyn, attr_static, attr_handler, handler}

// Card-specific styles

///|
fn card_container() -> String {
  @css.styles([
    ("padding", "16px"),
    ("background", "#fff"),
    ("border", "1px solid #e0e0e0"),
  ])
}

///|
fn card_title() -> String {
  @css.styles([
    ("font-size", "18px"),
    ("font-weight", "600"),
    ("margin-bottom", "8px"),
  ])
}

///|
fn card_content() -> String {
  @css.styles([("font-size", "14px"), ("color", "#666"), ("line-height", "1.5")])
}

// Card uses shared styles + card-specific styles

///|
pub fn register_card_component() -> Unit {
  @luna_api.register("luna-card", fn(_host) {
    let expanded = @resource.signal(false)

    // Combine shared + component-specific classes
    let container_class = @css.combine([
      card_container(),
      @css.css("border-radius", "8px"), // shared: rounded
      @css.css("box-shadow", "0 2px 4px rgba(0,0,0,0.1)"), // shared: shadow
    ])
    fragment([
      h("div", [("class", attr_static(container_class))], [
        h("div", [("class", attr_static(card_title()))], [text("Card Title")]),
        h("div", [("class", attr_static(card_content()))], [
          text_dyn(fn() {
            if expanded.get() {
              "This is expanded content. Click to collapse."
            } else {
              "Click to expand..."
            }
          }),
        ]),
        h(
          "button",
          [
            (
              "class",
              attr_static(
                @css.styles([
                  ("margin-top", "8px"),
                  ("padding", "4px 8px"),
                  ("cursor", "pointer"),
                ]),
              ),
            ),
            (
              "onclick",
              attr_handler(handler(fn(_) { expanded.update(fn(v) { not(v) }) })),
            ),
          ],
          [
            text_dyn(fn() { if expanded.get() { "Collapse" } else { "Expand" } }),
          ],
        ),
      ]),
    ])
  })
}
