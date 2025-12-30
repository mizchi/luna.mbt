// Button component - Light DOM WebComponent
// Uses @css for styling

///|
using @luna {
  fragment,
  h,
  text,
  text_dyn,
  attr_static,
  attr_dynamic,
  attr_handler,
  handler,
  type Node,
}

// Button-specific styles

///|
fn btn_base() -> String {
  @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("justify-content", "center"),
    ("padding", "8px 16px"),
    ("font-size", "14px"),
    ("font-weight", "500"),
    ("cursor", "pointer"),
    ("border", "none"),
    ("transition", "all 0.2s ease"),
  ])
}

///|
fn btn_primary() -> String {
  @css.styles([("background", "#2563eb"), ("color", "#fff")])
}

///|
fn btn_secondary() -> String {
  @css.styles([
    ("background", "#f3f4f6"),
    ("color", "#374151"),
    ("border", "1px solid #d1d5db"),
  ])
}

///|
fn btn_hover_primary() -> String {
  @css.hover("background", "#1d4ed8")
}

///|
fn btn_hover_secondary() -> String {
  @css.hover("background", "#e5e7eb")
}

// Button uses shared styles + button-specific styles

///|
pub fn register_button_component() -> Unit {
  @luna_api.register("luna-button", fn(_host) {
    let click_count = @signal.signal(0)
    let variant = @signal.signal("primary")
    fn get_button_class() -> String {
      let base = btn_base()
      let rounded = @css.css("border-radius", "8px") // shared: rounded
      if variant.get() == "primary" {
        @css.combine([base, rounded, btn_primary(), btn_hover_primary()])
      } else {
        @css.combine([base, rounded, btn_secondary(), btn_hover_secondary()])
      }
    }

    fragment([
      h(
        "div",
        [
          (
            "class",
            attr_static(
              @css.styles([
                ("display", "flex"), // shared: flex
                ("gap", "8px"),
                ("align-items", "center"), // shared: align-items
              ]),
            ),
          ),
        ],
        [
          h(
            "button",
            [
              ("class", attr_dynamic(get_button_class)),
              (
                "onclick",
                attr_handler(
                  handler(fn(_) { click_count.update(fn(n) { n + 1 }) }),
                ),
              ),
            ],
            [text_dyn(fn() { "Clicked: " + click_count.get().to_string() })],
          ),
          h(
            "button",
            [
              (
                "class",
                attr_static(
                  @css.styles([
                    ("padding", "4px 8px"),
                    ("font-size", "12px"),
                    ("cursor", "pointer"),
                  ]),
                ),
              ),
              (
                "onclick",
                attr_handler(
                  handler(fn(_) {
                    variant.update(fn(v) {
                      if v == "primary" {
                        "secondary"
                      } else {
                        "primary"
                      }
                    })
                  }),
                ),
              ),
            ],
            [text("Toggle Variant")],
          ),
        ],
      ),
    ])
  })
}
