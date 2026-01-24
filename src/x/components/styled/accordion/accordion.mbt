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
  content : Array[@luna.Node[@js.Any, String]]
}

///|
pub fn accordion_item(
  id : String,
  heading : String,
  content : Array[@luna.Node[@js.Any, String]],
) -> AccordionItemData {
  { id, heading, content }
}

///|
/// Styled accordion with APG keyboard navigation.
///
/// Keyboard:
/// - Enter/Space: Toggle panel expansion
/// - ArrowDown: Move focus to next header (no wrap)
/// - ArrowUp: Move focus to previous header (no wrap)
/// - Home: Move focus to first header
/// - End: Move focus to last header
pub fn accordion(
  items : Array[AccordionItemData],
  expanded : @resource.Signal[Int],
  class? : String,
) -> @luna.Node[@js.Any, String] {
  let slots = accordion_slots()
  let root_class = match class {
    Some(c) => slots.root + " " + c
    None => slots.root
  }

  // Generate header IDs for focus management
  let header_ids : Array[String] = []
  let panel_ids : Array[String] = []
  for item in items {
    header_ids.push("accordion-header-" + item.id)
    panel_ids.push("accordion-panel-" + item.id)
  }
  let children : Array[@luna.Node[@js.Any, String]] = []
  for i, item in items {
    let header_id = header_ids[i]
    let panel_id = panel_ids[i]
    let index = i

    // Get headless props
    let header_props = @headless.use_accordion_header_nav(
      header_id, panel_id, header_ids, index, expanded,
    )
    let panel_props = @headless.use_accordion_panel_nav(
      panel_id, header_id, index, expanded,
    )

    // Build header attrs from headless + styling
    let header_attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
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
    ]
    for attr in header_props.attrs {
      header_attrs.push(attr)
    }
    let header = @luna.h("h3", [], [
      @luna.h("button", header_attrs, [
        @luna.text(item.heading),
        @luna.h(
          "span",
          [("class", @luna.attr_static(slots.icon))],
          [@luna.text("\u{25BC}")], // ▼
        ),
      ]),
    ])

    // Build panel attrs from headless + styling
    let panel_attrs : Array[(String, @luna.Attr[@js.Any, String])] = [
      ("class", @luna.attr_static(slots.panel)),
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
    ]
    for attr in panel_props.attrs {
      panel_attrs.push(attr)
    }
    let panel = @luna.h("div", panel_attrs, [
      @luna.h(
        "div",
        [("class", @luna.attr_static(slots.panel + "-content"))],
        item.content,
      ),
    ])
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
    #|  border-radius: 0.5rem;
    #|  overflow: hidden;
    #|  background: var(--background);
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
    #|  background: transparent;
    #|  color: var(--foreground);
    #|  cursor: pointer;
    #|  font-size: 0.875rem;
    #|  font-weight: 500;
    #|  text-align: left;
    #|  transition: background-color 0.15s;
    #|}
    #|
    #|.accordion__header:hover {
    #|  background: var(--muted);
    #|}
    #|
    #|.accordion__header:focus-visible {
    #|  outline: 2px solid var(--accent);
    #|  outline-offset: -2px;
    #|}
    #|
    #|.accordion__icon {
    #|  font-size: 0.75rem;
    #|  transition: transform 0.15s;
    #|  color: var(--muted-foreground);
    #|}
    #|
    #|.accordion__item[data-state="open"] .accordion__icon {
    #|  transform: rotate(180deg);
    #|}
    #|
    #|.accordion__panel {
    #|  display: grid;
    #|  grid-template-rows: 0fr;
    #|  overflow: hidden;
    #|  transition: grid-template-rows 0.2s ease-out;
    #|}
    #|
    #|.accordion__panel[data-state="open"] {
    #|  grid-template-rows: 1fr;
    #|}
    #|
    #|.accordion__panel-content {
    #|  min-height: 0;
    #|  padding: 0 1rem;
    #|  background: var(--background);
    #|  color: var(--foreground);
    #|  overflow: hidden;
    #|}
    #|
    #|.accordion__panel[data-state="open"] .accordion__panel-content {
    #|  padding: 1rem;
    #|  border-top: 1px solid var(--border);
    #|}
    #|
    #|/* Reduced motion */
    #|@media (prefers-reduced-motion: reduce) {
    #|  .accordion__header,
    #|  .accordion__icon,
    #|  .accordion__panel {
    #|    transition: none;
    #|  }
    #|}
  css
}
