///|
/// Vercel Deploy Adapter
///
/// Generates vercel.json with:
/// - trailingSlash: URL trailing slash behavior
/// - cleanUrls: Remove .html extension
/// - headers: Cache headers for assets
/// - rewrites: SPA fallback (optional)

///|
/// Write Vercel configuration
pub fn write_vercel_config(ctx : @astra.BuildContext) -> Unit {
  let output_dir = @path.join2(ctx.cwd, ctx.config.output_dir)
  let config = build_vercel_json(ctx)
  let path = @path.join2(output_dir, "vercel.json")
  @fs.writeFileSync(path, @js.any(config)) catch {
    err => println("Warning: Failed to write vercel.json: \{err}")
  }
  println("  Generated: vercel.json (Vercel)")
}

///|
/// Build vercel.json content
fn build_vercel_json(ctx : @astra.BuildContext) -> String {
  let parts : Array[String] = []

  // Trailing slash setting
  let trailing = if ctx.config.trailing_slash { "true" } else { "false" }
  parts.push("  \"trailingSlash\": \{trailing}")

  // Clean URLs (remove .html)
  parts.push("  \"cleanUrls\": true")

  // Headers for caching
  let headers =
    #|  "headers": [
    #|    {
    #|      "source": "/assets/(.*)",
    #|      "headers": [
    #|        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
    #|      ]
    #|    },
    #|    {
    #|      "source": "/_luna/(.*)",
    #|      "headers": [
    #|        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
    #|      ]
    #|    }
    #|  ]
  parts.push(headers)

  // SPA fallback rewrite (if SPA mode enabled)
  if ctx.config.navigation.spa {
    let rewrites =
      #|  "rewrites": [
      #|    { "source": "/(.*)", "destination": "/404.html" }
      #|  ]
    parts.push(rewrites)
  }
  "{\n" + parts.join(",\n") + "\n}\n"
}
