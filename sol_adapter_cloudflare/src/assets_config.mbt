///| Convert a Sol route pattern to a Cloudflare `run_worker_first` glob.
pub fn route_pattern_to_worker_glob(path : String) -> String {
  let result = StringBuilder::new()
  let segments = path.split("/")
  let mut first = true
  for segment in segments {
    if segment.is_empty() {
      continue
    }
    if !first {
      result.write_string("/")
    }
    first = false
    if segment.has_prefix(":") {
      result.write_string("*")
    } else if segment.has_prefix("[[...") && segment.has_suffix("]]") {
      result.write_string("*")
    } else if segment.has_prefix("[...") && segment.has_suffix("]") {
      result.write_string("*")
    } else if segment.has_prefix("[") && segment.has_suffix("]") {
      result.write_string("*")
    } else {
      result.write_string(segment.to_owned())
    }
  }
  "/" + result.to_string()
}

///| Extract Cloudflare `run_worker_first` patterns from Sol routes.
pub fn extract_worker_first_patterns(
  routes : Array[@router.SolRoutes],
) -> Array[String] {
  let analyzed = @router.analyze_routes(routes)
  let patterns : Array[String] = []
  for route in analyzed {
    if route.kind is @router.RouteKind::Dynamic {
      let pattern = route_pattern_to_worker_glob(route.pattern)
      if !patterns.contains(pattern) {
        patterns.push(pattern)
      }
    }
  }
  patterns.sort_by(compare_strings_lex)
  patterns
}

///|
fn compare_strings_lex(a : String, b : String) -> Int {
  let a_chars = a.to_array()
  let b_chars = b.to_array()
  let n = if a_chars.length() < b_chars.length() {
    a_chars.length()
  } else {
    b_chars.length()
  }
  for i = 0; i < n; i = i + 1 {
    if a_chars[i] < b_chars[i] {
      return -1
    }
    if a_chars[i] > b_chars[i] {
      return 1
    }
  }
  if a_chars.length() < b_chars.length() {
    -1
  } else if a_chars.length() > b_chars.length() {
    1
  } else {
    0
  }
}

///| Generate a Wrangler `assets` config fragment for Cloudflare Workers.
pub fn generate_wrangler_assets_config(
  routes : Array[@router.SolRoutes],
  output_dir : String,
) -> String {
  let patterns = extract_worker_first_patterns(routes)
  if patterns.is_empty() {
    return "{\n  \"directory\": \"\{output_dir}\",\n  \"html_handling\": \"auto-trailing-slash\",\n  \"not_found_handling\": \"404-page\"\n}"
  }

  let patterns_json = StringBuilder::new()
  patterns_json.write_string("[")
  for i, pattern in patterns {
    if i > 0 {
      patterns_json.write_string(", ")
    }
    patterns_json.write_string("\"")
    patterns_json.write_string(pattern)
    patterns_json.write_string("\"")
  }
  patterns_json.write_string("]")
  "{\n  \"directory\": \"\{output_dir}\",\n  \"html_handling\": \"auto-trailing-slash\",\n  \"not_found_handling\": \"single-page-application\",\n  \"run_worker_first\": \{patterns_json.to_string()}\n}"
}
