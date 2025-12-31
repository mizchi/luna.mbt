// Cloudflare Pages specific generation
//
// Generates _routes.json for Cloudflare Pages
// See: https://developers.cloudflare.com/pages/functions/routing/

///|
/// Generate _routes.json content for Cloudflare Pages
/// This file controls which routes are handled by Functions vs static assets
pub fn generate_routes_json(pages : Array[@ssg.PageMeta]) -> String {
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

  // Include patterns - for dynamic routes that need Worker fallback
  // Dynamic routes are detected by source_path containing "?" (param marker)
  let include_patterns = extract_dynamic_route_patterns(pages)

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
/// Extract dynamic route patterns from pages
/// Pages from dynamic routes have source_path like "posts/_id_.md?id=value"
/// Returns patterns like "/posts/*" for Worker fallback
pub fn extract_dynamic_route_patterns(
  pages : Array[@ssg.PageMeta],
) -> Array[String] {
  let patterns : Map[String, Bool] = {} // Use map for deduplication
  for page in pages {
    // Check if this page is from a dynamic route (has ? in source_path)
    guard page.source_path.find("?") is Some(query_idx) else { continue }

    // Extract the dynamic file path before the query string
    // e.g., "posts/_id_.md?id=hello" -> "posts/_id_.md"
    let dynamic_source = extract_substring_before(page.source_path, query_idx)

    // Get the parent directory of the dynamic file
    // e.g., "posts/_id_.md" -> "posts"
    let parent_path = get_parent_dir(dynamic_source)

    // Build the pattern: /parent/* for catchable routes
    let pattern = if parent_path.is_empty() {
      "/*"
    } else {
      "/" + parent_path + "/*"
    }

    // Add to patterns (deduplication via map)
    patterns[pattern] = true
  }

  // Convert map keys to array
  patterns.keys().collect()
}

///|
/// Get parent directory from path
fn get_parent_dir(path : String) -> String {
  let chars = path.to_array()
  let mut last_slash = -1
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '/' {
      last_slash = i
    }
  }
  if last_slash > 0 {
    String::from_array(chars[0:last_slash])
  } else {
    ""
  }
}

///|
/// Extract substring before given index
fn extract_substring_before(s : String, idx : Int) -> String {
  let chars = s.to_array()
  if idx <= 0 {
    ""
  } else if idx >= chars.length() {
    s
  } else {
    String::from_array(chars[0:idx])
  }
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
pub fn write_routes_json(ctx : @ssg.BuildContext) -> Unit {
  // Only generate for Cloudflare target
  guard ctx.config.deploy_target == @ssg.Cloudflare else { return }
  let content = generate_routes_json(ctx.pages)
  let output_path = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    "_routes.json",
  )
  @fs.writeFileSync(output_path, @js.any(content)) catch {
    err => println("Warning: Failed to write _routes.json: \{err}")
  }
}
