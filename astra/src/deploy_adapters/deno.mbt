///|
/// Deno Deploy Adapter
///
/// For pure static sites, Deno Deploy requires no special configuration.
/// This adapter only generates files when SSR is needed.

///|
/// Write Deno Deploy configuration (currently no-op for static sites)
pub fn write_deno_config(ctx : @astra.BuildContext) -> Unit {
  // Deno Deploy serves static files automatically
  // Only generate config if SSR is needed in the future
  ignore(ctx)
  println("  Deno Deploy: No special config needed for static sites")
}
