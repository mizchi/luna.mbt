// Manifest Adapter for SSG
//
// Converts between PageMeta and RouteManifest

// =============================================================================
// PageMeta to RouteManifest
// =============================================================================

///|
/// Convert PageMeta array to RouteManifest
pub fn page_metas_to_manifest(
  pages : Array[@ssg.PageMeta],
  config : @ssg.SsgConfig,
) -> RouteManifest {
  let routes : Array[RouteEntry] = []
  for page in pages {
    let output = @ssg.url_to_output_path(page.url_path)
    let entry = RouteEntry::Static(StaticRouteEntry::{
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
  let fallback = FallbackConfig::NotFound(path=@ssg.url_to_output_path("/404/"))
  RouteManifest::{ routes, fallback } |> ignore
  // Use config for potential SPA fallback
  if config.navigation.spa {
    RouteManifest::{
      routes,
      fallback: FallbackConfig::Spa(entry="/index.html"),
    }
  } else {
    RouteManifest::{ routes, fallback }
  }
}

// =============================================================================
// RouteManifest to PageMeta
// =============================================================================

///|
/// Convert RouteManifest back to PageMeta array
/// Only static routes can be converted
pub fn manifest_to_page_metas(manifest : RouteManifest) -> Array[@ssg.PageMeta] {
  let pages : Array[@ssg.PageMeta] = []
  for route in manifest.routes {
    match route {
      RouteEntry::Static(static_route) => {
        let frontmatter = @ssg.Frontmatter::{
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
        let content_type = @ssg.ContentType::Markdown
        let renderer_type = determine_renderer_type(content_type, frontmatter)
        let page = @ssg.PageMeta::{
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
pub fn page_meta_to_static_route(page : @ssg.PageMeta) -> StaticRouteEntry {
  StaticRouteEntry::{
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
pub fn static_route_to_page_meta(route : StaticRouteEntry) -> @ssg.PageMeta {
  let frontmatter = @ssg.Frontmatter::{
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
  let content_type = @ssg.ContentType::Markdown
  let renderer_type = determine_renderer_type(content_type, frontmatter)
  @ssg.PageMeta::{
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
