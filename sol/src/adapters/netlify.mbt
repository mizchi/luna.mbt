///|
/// Netlify Deploy Adapter
///
/// Generates:
/// - _headers: HTTP header configuration
/// - _redirects: Redirect and rewrite rules

///|
/// Write Netlify configuration files
pub fn write_netlify_config(ctx : @astra.BuildContext) -> Unit {
  let output_dir = @path.join2(ctx.cwd, ctx.config.output_dir)

  // Write _headers
  write_headers(output_dir)

  // Write _redirects
  write_redirects(output_dir, ctx.config.navigation.spa)
  println("  Generated: _headers, _redirects (Netlify)")
}

///|
/// Write _headers file
fn write_headers(output_dir : String) -> Unit {
  let content =
    #|# Asset caching
    #|/assets/*
    #|  Cache-Control: public, max-age=31536000, immutable
    #|
    #|/_luna/*
    #|  Cache-Control: public, max-age=31536000, immutable
    #|
    #|# Security headers
    #|/*
    #|  X-Frame-Options: DENY
    #|  X-Content-Type-Options: nosniff
    #|  Referrer-Policy: strict-origin-when-cross-origin
    #|
  let path = @path.join2(output_dir, "_headers")
  @fs.writeFileSync(path, @js.any(content)) catch {
    err => println("Warning: Failed to write _headers: \{err}")
  }
}

///|
/// Write _redirects file
fn write_redirects(output_dir : String, spa_mode : Bool) -> Unit {
  let content = if spa_mode {
    // SPA fallback: serve 404.html with 200 status for client-side routing
    let spa_content =
      #|# SPA fallback
      #|/*  /404.html  200
      #|
    spa_content
  } else {
    // Standard 404 fallback
    let fallback_content =
      #|# 404 fallback
      #|/*  /404.html  404
      #|
    fallback_content
  }
  let path = @path.join2(output_dir, "_redirects")
  @fs.writeFileSync(path, @js.any(content)) catch {
    err => println("Warning: Failed to write _redirects: \{err}")
  }
}
