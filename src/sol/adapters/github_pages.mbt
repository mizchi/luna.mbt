///|
/// GitHub Pages Deploy Adapter
///
/// Generates:
/// - .nojekyll: Disables Jekyll processing (required for _luna/ directory)
/// - CNAME: Custom domain file (optional, from config)

///|
/// Write GitHub Pages specific files
pub fn write_github_pages_config(ctx : @ssg.BuildContext) -> Unit {
  let output_dir = @path.join2(ctx.cwd, ctx.config.output_dir)

  // Always write .nojekyll to disable Jekyll processing
  // This is required because _luna/ directory starts with underscore
  write_nojekyll(output_dir)

  // Write CNAME if custom domain is configured in ogp.site_url
  match ctx.config.ogp.site_url {
    Some(site_url) => {
      let domain = extract_domain(site_url)
      if not(domain.is_empty()) {
        write_cname(output_dir, domain)
      }
    }
    None => ()
  }
  println("  Generated: .nojekyll (GitHub Pages)")
}

///|
/// Write .nojekyll file (empty file to disable Jekyll)
fn write_nojekyll(output_dir : String) -> Unit {
  let path = @path.join2(output_dir, ".nojekyll")
  @fs.writeFileSync(path, @js.any("")) catch {
    err => println("Warning: Failed to write .nojekyll: \{err}")
  }
}

///|
/// Write CNAME file for custom domain
fn write_cname(output_dir : String, domain : String) -> Unit {
  let path = @path.join2(output_dir, "CNAME")
  @fs.writeFileSync(path, @js.any(domain + "\n")) catch {
    err => println("Warning: Failed to write CNAME: \{err}")
  }
  println("  Generated: CNAME (\{domain})")
}

///|
/// Extract domain from URL (e.g., "https://docs.example.com" -> "docs.example.com")
fn extract_domain(url : String) -> String {
  // Remove protocol
  let chars = url.to_array()
  let start_idx = if url.has_prefix("https://") {
    8
  } else if url.has_prefix("http://") {
    7
  } else {
    0
  }

  // Find end of domain (first / after protocol)
  let mut end_idx = chars.length()
  for i = start_idx; i < chars.length(); i = i + 1 {
    if chars[i] == '/' {
      end_idx = i
      break
    }
  }
  if end_idx > start_idx {
    String::from_array(chars[start_idx:end_idx])
  } else if start_idx > 0 {
    String::from_array(chars[start_idx:])
  } else {
    url
  }
}
