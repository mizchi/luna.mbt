///|
/// Deploy Adapters for Static Site Generation
///
/// Each adapter generates platform-specific configuration files
/// based on the deploy target setting in sol.config.json

///|
/// Run the appropriate deploy adapter based on config
pub fn run_adapter(ctx : @astra.BuildContext) -> Unit {
  match ctx.config.deploy_target {
    @astra.Cloudflare => write_cloudflare_config(ctx)
    @astra.GithubPages => write_github_pages_config(ctx)
    @astra.Vercel => write_vercel_config(ctx)
    @astra.Netlify => write_netlify_config(ctx)
    @astra.Deno => write_deno_config(ctx)
    @astra.Static | @astra.Node => ()
  }
}
