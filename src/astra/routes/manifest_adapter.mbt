// Manifest Adapter for Astra
//
// Converts between PageMeta and RouteManifest

// =============================================================================
// PageMeta to RouteManifest
// =============================================================================

///|
/// Convert PageMeta array to RouteManifest
pub fn page_metas_to_manifest(
  pages : Array[@astra.PageMeta],
  config : @astra.SsgConfig,
) -> @sol_routes.RouteManifest {
  let routes : Array[@sol_routes.RouteEntry] = []
  for page in pages {
    let output = @ssg.url_to_output_path(page.url_path)
    let entry = @sol_routes.RouteEntry::Static(@sol_routes.StaticRouteEntry::{
      path: page.url_path,
      source: page.source_path,
      output,
      layout: page.frontmatter.layout,
      title: page.frontmatter.title,
      description: page.frontmatter.description,
      islands: page.frontmatter.islands,
      locale: page.locale,
      generated_params: [],
    })
    routes.push(entry)
  }

  // Determine fallback based on config
  let fallback = @sol_routes.FallbackConfig::NotFound(
    path=@ssg.url_to_output_path("/404/"),
  )
  @sol_routes.RouteManifest::{ routes, fallback } |> ignore
  // Use config for potential SPA fallback
  if config.navigation.spa {
    @sol_routes.RouteManifest::{
      routes,
      fallback: @sol_routes.FallbackConfig::Spa(entry="/index.html"),
    }
  } else {
    @sol_routes.RouteManifest::{ routes, fallback }
  }
}

// =============================================================================
// RouteManifest to PageMeta
// =============================================================================

///|
/// Convert RouteManifest back to PageMeta array
/// Only static routes can be converted
pub fn manifest_to_page_metas(
  manifest : @sol_routes.RouteManifest,
) -> Array[@astra.PageMeta] {
  let pages : Array[@astra.PageMeta] = []
  for route in manifest.routes {
    match route {
      @sol_routes.RouteEntry::Static(static_route) => {
        let frontmatter = @astra.Frontmatter::{
          title: static_route.title,
          description: static_route.description,
          layout: static_route.layout,
          sidebar: true,
          outline: None,
          islands: static_route.islands,
          prev: None,
          next: None,
          image: None,
          og_type: None,
          twitter_card: None,
          ssr: false,
          renderer: None,
          noindex: false,
          revalidate: None,
          date: None,
          author: None,
          tags: [],
          draft: false,
          featured: false,
          cover_image: None,
        }
        let content_type = @astra.ContentType::Markdown
        let renderer_type = determine_renderer_type(content_type, frontmatter)
        let page = @astra.PageMeta::{
          source_path: static_route.source,
          url_path: static_route.path,
          content_type,
          renderer_type,
          frontmatter,
          last_modified: None, // Assume Markdown for manifest-imported routes
          locale: static_route.locale,
          canonical_path: static_route.path, // Simplified
          sort_key: static_route.source, // Use source as sort key
        }
        pages.push(page)
      }
      _ => () // Skip dynamic and API routes
    }
  }
  pages
}

// =============================================================================
// Single Page Conversion
// =============================================================================

///|
/// Convert a single PageMeta to StaticRouteEntry
pub fn page_meta_to_static_route(
  page : @astra.PageMeta,
) -> @sol_routes.StaticRouteEntry {
  @sol_routes.StaticRouteEntry::{
    path: page.url_path,
    source: page.source_path,
    output: @ssg.url_to_output_path(page.url_path),
    layout: page.frontmatter.layout,
    title: page.frontmatter.title,
    description: page.frontmatter.description,
    islands: page.frontmatter.islands,
    locale: page.locale,
    generated_params: [],
  }
}

///|
/// Convert StaticRouteEntry back to PageMeta
pub fn static_route_to_page_meta(
  route : @sol_routes.StaticRouteEntry,
) -> @astra.PageMeta {
  let frontmatter = @astra.Frontmatter::{
    title: route.title,
    description: route.description,
    layout: route.layout,
    sidebar: true,
    outline: None,
    islands: route.islands,
    prev: None,
    next: None,
    image: None,
    og_type: None,
    twitter_card: None,
    ssr: false,
    renderer: None,
    noindex: false,
    revalidate: None,
    date: None,
    author: None,
    tags: [],
    draft: false,
    featured: false,
    cover_image: None,
  }
  let content_type = @astra.ContentType::Markdown
  let renderer_type = determine_renderer_type(content_type, frontmatter)
  @astra.PageMeta::{
    source_path: route.source,
    url_path: route.path,
    content_type,
    renderer_type,
    frontmatter,
    last_modified: None, // Assume Markdown for manifest-imported routes
    locale: route.locale,
    canonical_path: route.path,
    sort_key: route.source,
  }
}
