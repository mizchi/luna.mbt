///|
/// APG Landmarks Pattern
/// https://www.w3.org/WAI/ARIA/apg/patterns/landmarks/
///
/// Landmarks are a set of eight roles that identify the major sections of a page.
/// They enable assistive technology users to perceive page structure and
/// facilitate efficient keyboard navigation.
///
/// The 8 Landmark Roles:
/// 1. banner - Site header (usually <header> in <body>)
/// 2. navigation - Navigation links (use <nav>)
/// 3. main - Main content (use <main>)
/// 4. complementary - Supporting content (use <aside>)
/// 5. contentinfo - Footer with site info (usually <footer> in <body>)
/// 6. search - Search functionality
/// 7. form - Form region (when it has accessible name)
/// 8. region - Generic landmark (requires accessible name)
///
/// Best Practices:
/// - Keep landmarks to 7 or fewer per page
/// - Ensure all content is within a landmark
/// - Use semantic HTML elements when possible

///|
/// Create a banner landmark (site header).
/// Use at top of page for site-oriented content like logo, site name, search.
/// Implicit for <header> when not nested in article/section.
///
/// Parameters:
/// - aria_label: Accessible label (optional, use when multiple banners exist)
/// - children: Header content
pub fn[E] banner(
  aria_label? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = []
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  @luna.h("header", attrs, children)
}

///|
/// Create a navigation landmark.
/// Use for major navigation blocks.
/// Implicit for <nav> element.
///
/// Parameters:
/// - aria_label: Accessible label (required when multiple nav landmarks exist)
/// - children: Navigation links
///
/// Example:
/// ```
/// nav(aria_label="Main navigation", [link("/", [text("Home")]), ...])
/// ```
pub fn[E] nav(
  aria_label? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = []
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  @luna.h("nav", attrs, children)
}

///|
/// Create a main landmark.
/// Contains the primary content of the page.
/// There should be only one main landmark per page.
/// Implicit for <main> element.
///
/// Parameters:
/// - children: Main content
pub fn[E] main_content(children : Array[@luna.Node[E]]) -> @luna.Node[E] {
  @luna.h("main", [], children)
}

///|
/// Create a complementary landmark (sidebar/aside).
/// Supporting content that complements the main content.
/// Implicit for <aside> element.
///
/// Parameters:
/// - aria_label: Accessible label (recommended)
/// - children: Complementary content
pub fn[E] aside(
  aria_label? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = []
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  @luna.h("aside", attrs, children)
}

///|
/// Create a contentinfo landmark (site footer).
/// Contains information about the parent document (copyright, privacy, etc.).
/// Implicit for <footer> when not nested in article/section.
///
/// Parameters:
/// - aria_label: Accessible label (optional)
/// - children: Footer content
pub fn[E] contentinfo(
  aria_label? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = []
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  @luna.h("footer", attrs, children)
}

///|
/// Create a search landmark.
/// Contains search functionality.
/// Use <search> element (HTML5.2+) or role="search" on a form.
///
/// Parameters:
/// - aria_label: Accessible label (recommended when multiple search regions)
/// - children: Search form content
pub fn[E] search(
  aria_label? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = []
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  @luna.h("search", attrs, children)
}

///|
/// Create a search landmark using role attribute (fallback for older browsers).
///
/// Parameters:
/// - aria_label: Accessible label
/// - children: Search form content
pub fn[E] search_role(
  aria_label? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = [
    ("role", @luna.attr_static("search")),
  ]
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  @luna.h("form", attrs, children)
}

///|
/// Create a form landmark.
/// A form becomes a landmark when it has an accessible name.
///
/// Parameters:
/// - aria_label: Accessible label (required for form to be a landmark)
/// - aria_labelledby: ID of labelling element (alternative to aria_label)
/// - children: Form content
pub fn[E] form_landmark(
  aria_label? : String,
  aria_labelledby? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = []
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", @luna.attr_static(id)))
  }
  @luna.h("form", attrs, children)
}

///|
/// Create a region landmark.
/// A generic landmark that requires an accessible name.
/// Use <section> with aria-label or aria-labelledby.
///
/// Parameters:
/// - aria_label: Accessible label (required)
/// - aria_labelledby: ID of labelling element (alternative to aria_label)
/// - children: Region content
///
/// Example:
/// ```
/// region(aria_label="Quick Stats", [text("...")])
/// ```
pub fn[E] region(
  aria_label? : String,
  aria_labelledby? : String,
  children : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let attrs : Array[(String, @luna.Attr[E])] = []
  if aria_label is Some(label) {
    attrs.push(("aria-label", @luna.attr_static(label)))
  }
  if aria_labelledby is Some(id) {
    attrs.push(("aria-labelledby", @luna.attr_static(id)))
  }
  @luna.h("section", attrs, children)
}

///|
/// Create a page layout with standard landmarks structure.
/// Provides a complete accessible page structure.
///
/// Parameters:
/// - header: Banner content (optional)
/// - nav: Navigation content (optional)
/// - main_content: Main content (required)
/// - aside_content: Complementary content (optional)
/// - footer: Contentinfo content (optional)
///
/// Example:
/// ```
/// page_layout(
///   header=[text("Site Name")],
///   nav=[link("/", [text("Home")])],
///   main_content=[text("Welcome")],
///   footer=[text("© 2024")]
/// )
/// ```
pub fn[E] page_layout(
  header? : Array[@luna.Node[E]],
  nav_content? : Array[@luna.Node[E]],
  main_children : Array[@luna.Node[E]],
  aside_content? : Array[@luna.Node[E]],
  footer_content? : Array[@luna.Node[E]],
) -> @luna.Node[E] {
  let children : Array[@luna.Node[E]] = []
  if header is Some(h) {
    children.push(banner(h))
  }
  if nav_content is Some(n) {
    children.push(nav(n))
  }
  children.push(main_content(main_children))
  if aside_content is Some(a) {
    children.push(aside(a))
  }
  if footer_content is Some(f) {
    children.push(contentinfo(f))
  }
  @luna.fragment(children)
}
