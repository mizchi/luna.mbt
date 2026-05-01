///|
/// Deploy Adapters for Static Site Generation
///
/// Each adapter generates platform-specific configuration files
/// based on the deploy target setting in sol.config.json

///|
/// Run the appropriate deploy adapter based on config
pub fn run_adapter(ctx : @ssg.BuildContext) -> Unit {
  match ctx.config.deploy_target {
    @ssg.Cloudflare => write_cloudflare_config(ctx)
    @ssg.GithubPages => write_github_pages_config(ctx)
    @ssg.Vercel => write_vercel_config(ctx)
    @ssg.Netlify => write_netlify_config(ctx)
    @ssg.Deno => write_deno_config(ctx)
    @ssg.Static | @ssg.Node => ()
  }
}
