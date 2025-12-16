///| Route Definitions
///|
///| This is the single source of truth for all routes.
///| Both server (SSR) and client (CSR) use these definitions.
///|
///| IMPORTANT: This is a magic file - sol generate reads this to:
///| - Generate server entry point
///| - Generate client hydration router
///| - Setup route handlers

///| Application routes - defines all pages and API endpoints
pub fn routes() -> Array[@routes.Routes] {
  [
    // Home page with counter island
    @routes.Island(
      path="/",
      component="home",
      url="/static/hydrate_counter.js",
      trigger=@luna.Load,
      title="Home",
      meta=[],
    ),
    // About page (static, no hydration)
    @routes.Page(path="/about", component="about", title="About", meta=[]),
    // Contact form page with contact_form island
    @routes.Island(
      path="/form",
      component="form_page",
      url="/static/contact_form.js",
      trigger=@luna.Load,
      title="Contact Form",
      meta=[],
    ),
    // WC Counter page - Web Components based island (Declarative Shadow DOM)
    @routes.Page(
      path="/wc-counter",
      component="wc_counter",
      title="WC Counter",
      meta=[],
    ),
    // API endpoint
    @routes.Get(path="/api/health", handler="health"),
  ]
}

///| Router configuration
pub fn config() -> @router.RouterConfig {
  @router.RouterConfig::default()
    .with_default_head(head())
    .with_loader_url("/static/loader.js")
}

///| API handler: health check
pub fn api_health(_props : @router.PageProps) -> @core.Any {
  @sol.json_obj([("status", @core.any("ok"))])
}
