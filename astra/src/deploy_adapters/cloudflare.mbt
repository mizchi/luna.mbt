///|
/// Cloudflare Pages Deploy Adapter
///
/// Generates _routes.json for Cloudflare Pages
/// This is a wrapper around the existing cloudflare.mbt in generator/

///|
/// Write Cloudflare Pages configuration
pub fn write_cloudflare_config(ctx : @astra.BuildContext) -> Unit {
  let content = generate_routes_json(ctx.pages)
  let output_path = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    "_routes.json",
  )
  @fs.writeFileSync(output_path, @js.any(content)) catch {
    err => println("Warning: Failed to write _routes.json: \{err}")
  }
  println("  Generated: _routes.json (Cloudflare Pages)")
}

///|
/// Generate _routes.json content for Cloudflare Pages
fn generate_routes_json(pages : Array[@astra.PageMeta]) -> String {
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
      exclude.push(url + "*")
    } else {
      exclude.push(url)
    }
  }

  // Include patterns for dynamic routes
  let include_patterns = extract_dynamic_route_patterns(pages)

  // Build JSON
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
fn extract_dynamic_route_patterns(
  pages : Array[@astra.PageMeta],
) -> Array[String] {
  let patterns : Map[String, Bool] = {}
  for page in pages {
    guard page.source_path.find("?") is Some(query_idx) else { continue }
    let dynamic_source = extract_substring_before(page.source_path, query_idx)
    let parent_path = get_parent_dir(dynamic_source)
    let pattern = if parent_path.is_empty() {
      "/*"
    } else {
      "/" + parent_path + "/*"
    }
    patterns[pattern] = true
  }
  patterns.keys().collect()
}

///|
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
