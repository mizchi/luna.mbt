// Wiki - Client-side dynamic routing example with Luna router
//
// URL patterns:
//   /wiki/              → Wiki Home (index)
//   /wiki/:slug         → Wiki Page (dynamic parameter)
//
// This demonstrates:
// - BrowserRouter for client-side navigation
// - Dynamic :slug parameter
// - Signal-based reactive updates

///|
using @luna_dom {
  a,
  events,
  div,
  h1,
  h2,
  h3,
  text,
  p,
  ul,
  li,
  article,
  aside,
  main_,
  text_dyn,
}

// =============================================================================
// Wiki Data
// =============================================================================

///|
struct WikiPage {
  slug : String
  title : String
  content : String
}

///|
fn get_wiki_pages() -> Array[WikiPage] {
  [
    {
      slug: "index",
      title: "Wiki Home",
      content: "Welcome to the wiki! Select a page from the sidebar.",
    },
    {
      slug: "getting-started",
      title: "Getting Started",
      content: "Install dependencies with `pnpm install`, then run `pnpm dev`.",
    },
    {
      slug: "configuration",
      title: "Configuration",
      content: "Edit luna.json to configure your project settings.",
    },
    {
      slug: "api-reference",
      title: "API Reference",
      content: "See the API documentation for available endpoints.",
    },
    {
      slug: "components",
      title: "Components",
      content: "Luna provides signal-based reactive components with SSR support.",
    },
  ]
}

///|
fn find_page(slug : String) -> WikiPage? {
  let pages = get_wiki_pages()
  for page in pages {
    if page.slug == slug {
      return Some(page)
    }
  }
  None
}

// =============================================================================
// Route Definitions
// =============================================================================

///|
fn create_routes() -> Array[@routes.Routes] {
  [
    // Wiki Home
    Page(path="", component="wiki_index", title="Wiki Home", meta=[]),
    // Wiki Page (dynamic parameter)
    Page(path="/:slug", component="wiki_page", title="Wiki Page", meta=[]),
  ]
}

// =============================================================================
// Components
// =============================================================================

///|
fn sidebar_component(router : @router.BrowserRouter) -> @luna_dom.DomNode {
  let base = router.get_base()
  let pages = get_wiki_pages()
  fn nav_link(href : String, label : String) -> @luna_dom.DomNode {
    a(
      href~,
      class="wiki-link",
      style="display: block; padding: 0.5rem; text-decoration: none; color: inherit;",
      on=events().click(fn(e) {
        e.preventDefault()
        router.navigate(href)
      }),
      [text(label)],
    )
  }

  aside(
    class="wiki-sidebar",
    style="min-width: 200px; border-right: 1px solid #e5e7eb; padding-right: 1rem;",
    [
      h3(style="margin-top: 0;", [text("Wiki Pages")]),
      ul(
        style="list-style: none; padding: 0; margin: 0;",
        pages.map(fn(page) {
          let href = if page.slug == "index" {
            base
          } else {
            base + "/" + page.slug
          }
          li([nav_link(href, page.title)])
        }),
      ),
    ],
  )
}

///|
fn wiki_index_component(_router : @router.BrowserRouter) -> @luna_dom.DomNode {
  let pages = get_wiki_pages()
  article(class="wiki-page", [
    h1([text("Wiki Home")]),
    p([
      text(
        "Welcome to the wiki! Select a page from the sidebar or choose from the list below:",
      ),
    ]),
    h2([text("Available Pages")]),
    ul(
      pages
      .iter()
      .filter(fn(p) { p.slug != "index" })
      .map(fn(page) { li([text(page.title)]) })
      .collect(),
    ),
  ])
}

///|
fn wiki_page_component(
  _router : @router.BrowserRouter,
  m : @routes.RoutesMatch,
) -> @luna_dom.DomNode {
  let slug = m.get_param("slug").unwrap_or("index")
  match find_page(slug) {
    Some(page) =>
      article(class="wiki-page", [
        h1([text(page.title)]),
        p([text(page.content)]),
      ])
    None =>
      article(class="wiki-page wiki-not-found", [
        h1([text("Page Not Found")]),
        p([text("The page '" + slug + "' does not exist.")]),
      ])
  }
}

///|
fn not_found_component(router : @router.BrowserRouter) -> @luna_dom.DomNode {
  let base = router.get_base()
  article(class="wiki-page wiki-not-found", [
    h1([text("404 - Not Found")]),
    p([text("Page not found: "), text_dyn(fn() { router.get_path() })]),
    p([
      a(
        href=base,
        on=events().click(fn(e) {
          e.preventDefault()
          router.navigate(base)
        }),
        [text("← Back to Wiki Home")],
      ),
    ]),
  ])
}

// =============================================================================
// Component Resolver
// =============================================================================

///|
fn resolve_component(
  router : @router.BrowserRouter,
  m : @routes.RoutesMatch,
) -> @luna_dom.DomNode {
  let component_id = m.component()
  match component_id {
    "wiki_index" => wiki_index_component(router)
    "wiki_page" => wiki_page_component(router, m)
    _ => not_found_component(router)
  }
}

// =============================================================================
// Router Renderer
// =============================================================================

///|
fn render_wiki(
  router : @router.BrowserRouter,
  container : @luna_dom.DomElement,
) -> Unit {
  let _ = @signal.effect(fn() {
    let match_result = router.match_signal().get()

    // Clear container
    @luna_dom.clear(container)

    // Create components untracked
    let (sidebar, content) = @signal.untracked(fn() {
      let sidebar = sidebar_component(router)
      let content = match match_result {
        Some(m) => resolve_component(router, m)
        None => not_found_component(router)
      }
      (sidebar, content)
    })

    // Build wiki layout
    let app = @signal.untracked(fn() {
      div(
        class="wiki-container",
        style="display: flex; gap: 2rem; min-height: 400px;",
        [sidebar, main_(class="wiki-content", style="flex: 1;", [content])],
      )
    })
    @luna_dom.mount(container, app)
  })

}

// =============================================================================
// Hydrate Export (for Island loading)
// =============================================================================

///|
/// Hydrate function - called by Luna loader
/// Element is the island container, state is parsed from luna:state
pub fn hydrate(el : @dom.Element, _state : @js.Any) -> Unit {
  // Router with base path /wiki
  let base = "/wiki"
  let routes = create_routes()
  let router = @router.BrowserRouter::new(routes, base~)

  // Start rendering
  let dom_container = el |> @luna_dom.DomElement::from_dom
  render_wiki(router, dom_container)
}

// =============================================================================
// Main (Standalone Entry Point)
// =============================================================================

///|
fn main {
  let doc = @dom.document()
  // Try wiki-app first (for island), fallback to app
  let container = match doc.getElementById("wiki-app") {
    Some(el) => Some(el)
    None => doc.getElementById("app")
  }
  match container {
    Some(el) => {
      // Router with base path /wiki
      let base = "/wiki"
      let routes = create_routes()
      let router = @router.BrowserRouter::new(routes, base~)

      // Start rendering
      let dom_container = el |> @luna_dom.DomElement::from_dom
      render_wiki(router, dom_container)
    }
    None => ()
  }
}
