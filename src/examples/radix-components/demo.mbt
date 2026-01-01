// Demo file to print SSR output for verification

///|
pub fn demo_accordion() -> String {
  let items : Array[AccordionItemProps] = [
    {
      id: "item-1",
      title: "Section 1",
      content: @element.text("Content for section 1"),
      default_open: true,
    },
    {
      id: "item-2",
      title: "Section 2",
      content: @element.text("Content for section 2"),
      default_open: false,
    },
  ]
  @static_dom.render(accordion_static(items))
}

///|
pub fn demo_switch() -> String {
  @static_dom.render(switch_static(true, Some("Enable notifications")))
}

///|
pub fn demo_checkbox() -> String {
  @static_dom.render(checkbox_static(Checked, Some("I agree to terms")))
}

///|
pub fn demo_accordion_with_island() -> String {
  let items : Array[AccordionItemProps] = [
    {
      id: "faq-1",
      title: "What is Luna?",
      content: @element.text("Luna is a UI library for MoonBit."),
      default_open: true,
    },
  ]
  @static_dom.render(
    accordion({ items, hydration_url: "/components/accordion.js" }),
  )
}
