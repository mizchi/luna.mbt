// Accordion Component - SSR + Hydration
//
// Universal component pattern:
// - SSR: Render static HTML with data-* attributes
// - Client: Hydration JS adds event handlers
//
// HTML Convention:
//   <div luna:url="/components/accordion.js" luna:trigger="visible">
//     <div data-accordion-item="id" data-state="open|closed">
//       <button data-accordion-trigger>
//         Title <span data-chevron>▼</span>
//       </button>
//       <div data-accordion-content>Content</div>
//     </div>
//   </div>
//
// CSS handles visual changes via [data-state] selector:
//   [data-state="open"] [data-accordion-content] { max-height: 200px; }
//   [data-state="closed"] [data-accordion-content] { max-height: 0; }

///|
/// Single accordion item props
pub(all) struct AccordionItemProps {
  id : String
  title : String
  content : @luna.Node[Unit]
  default_open : Bool
}

///|
/// Accordion props
pub(all) struct AccordionProps {
  items : Array[AccordionItemProps]
  hydration_url : String
}

///|
/// Create an accordion item
fn accordion_item(props : AccordionItemProps) -> @luna.Node[Unit] {
  let state = if props.default_open { "open" } else { "closed" }
  @element.div(
    attrs=[
      ("data-accordion-item", @luna.attr_static(props.id)),
      ("data-state", @luna.attr_static(state)),
    ],
    [
      @element.button(
        attrs=[("data-accordion-trigger", @luna.attr_static(""))],
        [
          @element.text(props.title),
          @element.span(
            attrs=[("data-chevron", @luna.attr_static(""))],
            [@element.text(" ▼")],
          ),
        ],
      ),
      @element.div(
        attrs=[("data-accordion-content", @luna.attr_static(""))],
        [props.content],
      ),
    ],
  )
}

///|
/// Create an accordion component with hydration
pub fn accordion(props : AccordionProps) -> @luna.Node[Unit] {
  let items = props.items.map(fn(item) { accordion_item(item) })
  @luna.island(
    "accordion",
    props.hydration_url,
    "{}",
    [@element.div(items)],
    trigger=@luna.Visible,
  )
}

///|
/// Create an accordion without island wrapper (for testing SSR output)
pub fn accordion_static(items : Array[AccordionItemProps]) -> @luna.Node[Unit] {
  @element.div(items.map(fn(item) { accordion_item(item) }))
}
