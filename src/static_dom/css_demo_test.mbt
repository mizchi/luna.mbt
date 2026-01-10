// CSS Utilities Integration Demo
// Demonstrates how to use CSS utilities with static_dom for SSR

///|
/// Demo: Card component using CSS utilities
test "demo: card component with CSS utilities" {
  // Reset CSS registry for clean state
  @css.reset_all()

  // Define card styles using CSS utilities
  let card_class = @css.styles([
    ("display", "flex"),
    ("flex-direction", "column"),
    ("padding", "1.5rem"),
    ("border-radius", "0.5rem"),
    ("background", "white"),
    ("box-shadow", "0 1px 3px rgba(0,0,0,0.1)"),
  ])

  // Add responsive and interactive styles
  let hover_shadow = @css.hover("box-shadow", "0 4px 12px rgba(0,0,0,0.15)")
  let dark_bg = @css.dark("background", "#1e1e1e")
  let md_padding = @css.at_md("padding", "2rem")

  // Combine all classes
  let full_card_class = card_class +
    " " +
    hover_shadow +
    " " +
    dark_bg +
    " " +
    md_padding

  // Build the card component
  let card = @element.div(class=full_card_class, [
    @element.h2(class=@css.css("font-size", "1.25rem"), [
      @element.text("Hello CSS Utilities"),
    ]),
    @element.p(class=@css.css("color", "#666"), [
      @element.text("This card uses atomic CSS classes generated at SSR time."),
    ]),
  ])

  // Render component to HTML
  let card_html = render(card)

  // Generate all CSS (base + pseudo + media queries)
  let generated_css = @css.generate_full_css()

  // Build complete document with CSS
  let doc = @element.html(lang="en", [
    @element.head([
      @element.title("CSS Utilities Demo"),
      @element.style_(generated_css),
    ]),
    @element.body([card]),
  ])
  let full_html = render(doc)

  // Verify: Card HTML contains generated class names
  assert_true(card_html.contains("class=\""))
  assert_true(card_html.contains("_")) // Underscore-prefixed classes

  // Verify: Generated CSS contains base styles
  assert_true(generated_css.contains("display:flex"))
  assert_true(generated_css.contains("padding:1.5rem"))
  assert_true(generated_css.contains("background:white"))

  // Verify: Generated CSS contains pseudo-classes
  assert_true(generated_css.contains(":hover{"))
  assert_true(generated_css.contains("box-shadow:0 4px 12px"))

  // Verify: Generated CSS contains media queries
  assert_true(generated_css.contains("@media(min-width:768px)"))
  assert_true(generated_css.contains("@media(prefers-color-scheme:dark)"))

  // Verify: Full HTML includes the style tag
  assert_true(full_html.contains("<style>"))
  assert_true(full_html.contains("</style>"))
}

///|
/// Demo: Button with hover states
test "demo: button with hover states" {
  @css.reset_all()

  // Primary button style
  let btn_base = @css.styles([
    ("display", "inline-flex"),
    ("align-items", "center"),
    ("padding", "0.5rem 1rem"),
    ("border-radius", "0.375rem"),
    ("background", "#3b82f6"),
    ("color", "white"),
    ("font-weight", "500"),
    ("cursor", "pointer"),
  ])
  let btn_hover = @css.hover("background", "#2563eb")
  let btn_focus = @css.focus("outline", "2px solid #93c5fd")
  let btn_active = @css.active("transform", "scale(0.98)")
  let btn_class = btn_base +
    " " +
    btn_hover +
    " " +
    btn_focus +
    " " +
    btn_active
  let button = @element.button(class=btn_class, [@element.text("Click me")])
  let html = render(button)
  let css = @css.generate_full_css()

  // Verify button HTML
  assert_true(html.contains("<button"))
  assert_true(html.contains("class=\""))

  // Verify all interaction states are generated
  assert_true(css.contains(":hover{"))
  assert_true(css.contains(":focus{"))
  assert_true(css.contains(":active{"))
}

///|
/// Demo: Responsive grid layout
test "demo: responsive grid layout" {
  @css.reset_all()

  // Base: single column
  let grid = @css.styles([("display", "grid"), ("gap", "1rem")])

  // Responsive: 2 columns at md, 3 at lg
  let md_cols = @css.at_md("grid-template-columns", "repeat(2, 1fr)")
  let lg_cols = @css.at_lg("grid-template-columns", "repeat(3, 1fr)")
  let grid_class = grid + " " + md_cols + " " + lg_cols

  // Build grid items
  let items = []
  for i = 0; i < 6; i = i + 1 {
    items.push(
      @element.div(class=@css.css("padding", "1rem"), [
        @element.text("Item " + (i + 1).to_string()),
      ]),
    )
  }
  let _ = @element.div(class=grid_class, items)
  let css = @css.generate_full_css()

  // Verify responsive breakpoints
  assert_true(css.contains("@media(min-width:768px)"))
  assert_true(css.contains("@media(min-width:1024px)"))
  assert_true(css.contains("grid-template-columns:repeat(2, 1fr)"))
  assert_true(css.contains("grid-template-columns:repeat(3, 1fr)"))
}

///|
/// Demo: Complete page with generated CSS
test "demo: complete page generation" {
  @css.reset_all()

  // Header styles
  let header_class = @css.styles([
    ("display", "flex"),
    ("justify-content", "space-between"),
    ("align-items", "center"),
    ("padding", "1rem 2rem"),
    ("background", "#1e293b"),
    ("color", "white"),
  ])

  // Main content
  let main_class = @css.styles([
    ("max-width", "1200px"),
    ("margin", "0 auto"),
    ("padding", "2rem"),
  ])

  // Footer
  let footer_class = @css.styles([
    ("padding", "1rem"),
    ("text-align", "center"),
    ("border-top", "1px solid #e5e7eb"),
  ])

  // Build page
  let page = document(
    lang="en",
    head_children=[
      @element.title("CSS Utilities Demo"),
      @element.meta(charset="UTF-8"),
      @element.meta(
        name="viewport",
        content="width=device-width, initial-scale=1",
      ),
      @element.style_(@css.generate_full_css()),
    ],
    body_children=[
      @element.header_(class=header_class, [
        @element.h1([@element.text("My Site")]),
        @element.nav([@element.text("Home | About | Contact")]),
      ]),
      @element.main_(class=main_class, [
        @element.h2([@element.text("Welcome")]),
        @element.p([@element.text("This page uses CSS utilities for styling.")]),
      ]),
      @element.footer_(class=footer_class, [@element.text("© 2025 My Site")]),
    ],
  )
  let html = render_document(page)

  // Verify document structure
  assert_true(html.has_prefix("<!DOCTYPE html>"))
  assert_true(html.contains("<style>"))
  assert_true(html.contains("<header"))
  assert_true(html.contains("<main"))
  assert_true(html.contains("<footer"))

  // Verify CSS is included
  assert_true(html.contains("display:flex"))
  assert_true(html.contains("max-width:1200px"))
}
