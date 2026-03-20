///| SSG-only project - minimal routes for build compatibility
pub fn routes() -> Array[@sol.SolRoutes] {
  []
}

///| Action registry (empty for SSG)
pub fn action_registry() -> @action.ActionRegistry {
  @action.ActionRegistry::new(allowed_origins=[])
}

///| Router configuration
pub fn config() -> @sol.RouterConfig {
  @sol.RouterConfig::default()
}
