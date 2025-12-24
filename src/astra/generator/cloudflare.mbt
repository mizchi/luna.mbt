// Cloudflare Pages specific generation
//
// Generates _routes.json for Cloudflare Pages
// See: https://developers.cloudflare.com/pages/functions/routing/

///|
/// Generate _routes.json content for Cloudflare Pages
/// This file controls which routes are handled by Functions vs static assets
pub fn generate_routes_json(pages : Array[@astra.PageMeta]) -> String {
  // For SSG, everything is static by default
  // We exclude all generated paths to serve them as static files
  let exclude : Array[String] = []

  // Add static asset patterns
  exclude.push("/*.html")
  exclude.push("/*.css")
  exclude.push("/*.js")
  exclude.push("/*.json")
  exclude.push("/*.ico")
  exclude.push("/*.png")
  exclude.push("/*.jpg")
  exclude.push("/*.svg")
  exclude.push("/*.woff2")

  // Add _luna runtime directory
  exclude.push("/_luna/*")

  // Add all page URLs as excluded (static files)
  for page in pages {
    let url = page.url_path
    if url.has_suffix("/") {
      // Directory URLs (index.html)
      exclude.push(url + "*")
    } else {
      exclude.push(url)
    }
  }

  // Include patterns - for dynamic routes (Server Actions, API routes)
  // In pure SSG mode, we include nothing (empty array)
  let include_patterns : Array[String] = []

  // Build JSON manually (minimal implementation)
  let exclude_items = exclude.map(fn(s) { "\"" + escape_json_string(s) + "\"" })
  let include_items = include_patterns.map(fn(s) {
    "\"" + escape_json_string(s) + "\""
  })

  let exclude_json = exclude_items.join(", ")
  let include_json = include_items.join(", ")

  "{\n  \"version\": 1,\n  \"include\": [" +
  include_json +
  "],\n  \"exclude\": [" +
  exclude_json +
  "]\n}\n"
}

///|
/// Escape special characters in JSON strings
fn escape_json_string(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    if c == '\\' {
      buf.write_string("\\\\")
    } else if c == '"' {
      buf.write_string("\\\"")
    } else if c == '\n' {
      buf.write_string("\\n")
    } else if c == '\r' {
      buf.write_string("\\r")
    } else if c == '\t' {
      buf.write_string("\\t")
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Write _routes.json to output directory (only if deploy target is Cloudflare)
pub fn write_routes_json(ctx : @astra.BuildContext) -> Unit {
  // Only generate for Cloudflare target
  guard ctx.config.deploy_target == @astra.Cloudflare else { return }

  let content = generate_routes_json(ctx.pages)
  let output_path = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    "_routes.json",
  )

  @fs.writeFileSync(output_path, @js.any(content)) catch {
    err => println("Warning: Failed to write _routes.json: \{err}")
  }
}
