///|
/// Styled Accordion Component
///
/// Class names (BEM):
/// - .accordion          - Root container
/// - .accordion__item    - Item wrapper
/// - .accordion__header  - Header button
/// - .accordion__icon    - Expand/collapse icon
/// - .accordion__panel   - Content panel
///
/// Data attributes:
/// - [data-state="open"|"closed"]

///|
pub(all) struct AccordionSlots {
  root : String
  item : String
  header : String
  icon : String
  panel : String
}

///|
pub fn accordion_slots() -> AccordionSlots {
  {
    root: "accordion",
    item: "accordion__item",
    header: "accordion__header",
    icon: "accordion__icon",
    panel: "accordion__panel",
  }
}

///|
pub(all) struct AccordionItemData {
  id : String
  heading : String
  content : Array[@luna.Node[@js.Any]]
}

///|
pub fn accordion_item(
  id : String,
  heading : String,
  content : Array[@luna.Node[@js.Any]],
) -> AccordionItemData {
  { id, heading, content }
}

///|
pub fn accordion(
  items : Array[AccordionItemData],
  expanded : @signal.Signal[Int],
  class? : String,
) -> @luna.Node[@js.Any] {
  let slots = accordion_slots()
  let root_class = match class {
    Some(c) => slots.root + " " + c
    None => slots.root
  }

  let children : Array[@luna.Node[@js.Any]] = []

  for i, item in items {
    let header_id = "accordion-header-" + item.id
    let panel_id = "accordion-panel-" + item.id
    let index = i

    // Header
    let header_attrs : Array[(String, @luna.Attr[@js.Any])] = [
      ("type", @luna.attr_static("button")),
      ("id", @luna.attr_static(header_id)),
      (
        "aria-expanded",
        @luna.attr_dynamic(fn() {
          if expanded.get() == index {
            "true"
          } else {
            "false"
          }
        }),
      ),
      ("aria-controls", @luna.attr_static(panel_id)),
      ("class", @luna.attr_static(slots.header)),
      (
        "data-state",
        @luna.attr_dynamic(fn() {
          if expanded.get() == index {
            "open"
          } else {
            "closed"
          }
        }),
      ),
      (
        "click",
        @luna.attr_handler(
          @luna.handler(fn(_) {
            if expanded.get() == index {
              expanded.set(-1)
            } else {
              expanded.set(index)
            }
          }),
        ),
      ),
    ]

    let header = @luna.h(
      "h3",
      [],
      [
        @luna.h(
          "button",
          header_attrs,
          [
            @luna.text(item.heading),
            @luna.h(
              "span",
              [("class", @luna.attr_static(slots.icon))],
              [@luna.text("\u{25BC}")], // ▼
            ),
          ],
        ),
      ],
    )

    // Panel
    let panel = @luna.show(
      fn() { expanded.get() == index },
      fn() {
        @luna.h(
          "div",
          [
            ("id", @luna.attr_static(panel_id)),
            ("aria-labelledby", @luna.attr_static(header_id)),
            ("role", @luna.attr_static("region")),
            ("class", @luna.attr_static(slots.panel)),
          ],
          item.content,
        )
      },
    )

    children.push(
      @luna.h(
        "div",
        [
          ("class", @luna.attr_static(slots.item)),
          (
            "data-state",
            @luna.attr_dynamic(fn() {
              if expanded.get() == index {
                "open"
              } else {
                "closed"
              }
            }),
          ),
        ],
        [header, panel],
      ),
    )
  }

  @luna.h("div", [("class", @luna.attr_static(root_class))], children)
}

///|
pub fn accordion_css() -> String {
  let css =
    #|/* Accordion - Default Theme */
    #|.accordion {
    #|  border: 1px solid var(--border);
    #|  border-radius: 8px;
    #|  overflow: hidden;
    #|}
    #|
    #|.accordion__item {
    #|  border-bottom: 1px solid var(--border);
    #|}
    #|
    #|.accordion__item:last-child {
    #|  border-bottom: none;
    #|}
    #|
    #|.accordion__header {
    #|  display: flex;
    #|  justify-content: space-between;
    #|  align-items: center;
    #|  width: 100%;
    #|  padding: 1rem;
    #|  border: none;
    #|  background: var(--muted);
    #|  color: var(--foreground);
    #|  cursor: pointer;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  text-align: left;
    #|  transition: background-color 0.2s;
    #|}
    #|
    #|.accordion__header:hover {
    #|  background: var(--border);
    #|}
    #|
    #|.accordion__header:focus-visible {
    #|  outline: 2px solid var(--accent);
    #|  outline-offset: -2px;
    #|}
    #|
    #|.accordion__icon {
    #|  font-size: 0.625rem;
    #|  transition: transform 0.2s;
    #|  color: var(--muted-foreground);
    #|}
    #|
    #|.accordion__item[data-state="open"] .accordion__icon {
    #|  transform: rotate(180deg);
    #|}
    #|
    #|.accordion__panel {
    #|  padding: 1rem;
    #|  background: var(--background);
    #|  color: var(--foreground);
    #|}
  css
}
