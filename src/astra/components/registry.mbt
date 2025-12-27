// Astra Components - Pluggable Component Registry
// Allows custom components to override defaults via convention

// =============================================================================
// Component Registry
// =============================================================================

///|
/// Registry holding component renderers
/// None = use default, Some = use custom
pub struct ComponentRegistry {
  header : ((@astra.BuildContext, @astra.PageMeta) -> @luna.Node[Unit])?
  footer : ((@astra.BuildContext) -> @luna.Node[Unit])?
  toc : ((Array[@markdown.TocItem]) -> @luna.Node[Unit])?
  breadcrumb : ((@astra.BuildContext, @astra.PageMeta) -> @luna.Node[Unit])?
  prev_next : ((@astra.BuildContext, @astra.PageMeta) -> @luna.Node[Unit])?
}

///|
/// Create empty registry (all defaults)
pub fn ComponentRegistry::new() -> ComponentRegistry {
  { header: None, footer: None, toc: None, breadcrumb: None, prev_next: None }
}

///|
/// Create registry with all default components
pub fn ComponentRegistry::defaults() -> ComponentRegistry {
  {
    header: Some(build_nav),
    footer: Some(build_footer),
    toc: Some(build_toc),
    breadcrumb: Some(build_breadcrumb),
    prev_next: Some(build_prev_next),
  }
}

// =============================================================================
// Builder Pattern for Registry
// =============================================================================

///|
/// Set custom header renderer
pub fn ComponentRegistry::with_header(
  self : ComponentRegistry,
  renderer : (@astra.BuildContext, @astra.PageMeta) -> @luna.Node[Unit],
) -> ComponentRegistry {
  { ..self, header: Some(renderer) }
}

///|
/// Set custom footer renderer
pub fn ComponentRegistry::with_footer(
  self : ComponentRegistry,
  renderer : (@astra.BuildContext) -> @luna.Node[Unit],
) -> ComponentRegistry {
  { ..self, footer: Some(renderer) }
}

///|
/// Set custom TOC renderer
pub fn ComponentRegistry::with_toc(
  self : ComponentRegistry,
  renderer : (Array[@markdown.TocItem]) -> @luna.Node[Unit],
) -> ComponentRegistry {
  { ..self, toc: Some(renderer) }
}

///|
/// Set custom breadcrumb renderer
pub fn ComponentRegistry::with_breadcrumb(
  self : ComponentRegistry,
  renderer : (@astra.BuildContext, @astra.PageMeta) -> @luna.Node[Unit],
) -> ComponentRegistry {
  { ..self, breadcrumb: Some(renderer) }
}

///|
/// Set custom prev/next renderer
pub fn ComponentRegistry::with_prev_next(
  self : ComponentRegistry,
  renderer : (@astra.BuildContext, @astra.PageMeta) -> @luna.Node[Unit],
) -> ComponentRegistry {
  { ..self, prev_next: Some(renderer) }
}

// =============================================================================
// Render Functions - Use registry with fallback to defaults
// =============================================================================

///|
/// Render header using registry (fallback to default)
pub fn ComponentRegistry::render_header(
  self : ComponentRegistry,
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
) -> @luna.Node[Unit] {
  match self.header {
    Some(render) => render(ctx, page)
    None => build_nav(ctx, page)
  }
}

///|
/// Render footer using registry (fallback to default)
pub fn ComponentRegistry::render_footer(
  self : ComponentRegistry,
  ctx : @astra.BuildContext,
) -> @luna.Node[Unit] {
  match self.footer {
    Some(render) => render(ctx)
    None => build_footer(ctx)
  }
}

///|
/// Render TOC using registry (fallback to default)
pub fn ComponentRegistry::render_toc(
  self : ComponentRegistry,
  toc : Array[@markdown.TocItem],
) -> @luna.Node[Unit] {
  match self.toc {
    Some(render) => render(toc)
    None => build_toc(toc)
  }
}

///|
/// Render breadcrumb using registry (fallback to default)
pub fn ComponentRegistry::render_breadcrumb(
  self : ComponentRegistry,
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
) -> @luna.Node[Unit] {
  match self.breadcrumb {
    Some(render) => render(ctx, page)
    None => build_breadcrumb(ctx, page)
  }
}

///|
/// Render prev/next using registry (fallback to default)
pub fn ComponentRegistry::render_prev_next(
  self : ComponentRegistry,
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
) -> @luna.Node[Unit] {
  match self.prev_next {
    Some(render) => render(ctx, page)
    None => build_prev_next(ctx, page)
  }
}
