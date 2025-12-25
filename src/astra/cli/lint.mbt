// Astra Lint - Check documentation for common issues
//

///|
/// Lint issue severity
pub(all) enum LintSeverity {
  Error
  Warning
  Info
}

///|
/// Lint issue
pub(all) struct LintIssue {
  severity : LintSeverity
  file : String
  line : Int?
  message : String
  rule : String
}

///|
/// Lint result
pub(all) struct LintResult {
  issues : Array[LintIssue]
  files_checked : Int
  errors : Int
  warnings : Int
}

///|
/// Run lint command
pub fn run_lint_command(args : Array[String]) -> Unit {
  // Parse options
  let mut fix = false
  for arg in args {
    if arg == "--fix" {
      fix = arg == "--fix"
    }
  }
  let _ = fix // TODO: implement fix mode

  // Load config
  let cwd = @process.cwd()
  let config = load_config(cwd)
  println(@colorette.cyan("Linting documentation..."))
  println("")

  // Run linter
  let result = lint_docs(config, cwd)

  // Print results
  print_lint_results(result)

  // Exit with error if any errors found
  if result.errors > 0 {
    @process.exit(1)
  }
}

///|
/// Load configuration
fn load_config(cwd : String) -> @astra.SsgConfig {
  let config_path = @path.join2(cwd, "astra.json")
  if @fs.existsSync(config_path) {
    let content : String = @fs.readFileSync(config_path).to_string() catch {
      _ => return @astra.SsgConfig::default()
    }
    @astra.parse_ssg_config(content).unwrap_or(@astra.SsgConfig::default())
  } else {
    @astra.SsgConfig::default()
  }
}

///|
/// Main lint function
pub fn lint_docs(config : @astra.SsgConfig, cwd : String) -> LintResult {
  let issues : Array[LintIssue] = []

  // Scan docs directory
  let pages = @routes.scan_docs_dir(
    config.docs_dir,
    cwd,
    i18n=config.i18n,
    exclude=config.exclude,
    trailing_slash=config.trailing_slash,
  )

  // Check components in pages directory
  let pages_dir = @path.join2(cwd, config.docs_dir)
  check_components(pages_dir, issues)

  // Check for duplicate pages (static paths take priority over dynamic)
  let (_, unresolved) = @routes.resolve_duplicate_pages(pages)
  for dup in unresolved {
    issues.push(LintIssue::{
      severity: Error,
      file: dup.sources[0],
      line: None,
      message: @routes.format_duplicate_error(dup),
      rule: "duplicate-page",
    })
  }

  // Build URL set for dead link detection
  let valid_urls : Map[String, Bool] = {}
  for page in pages {
    valid_urls[page.url_path] = true
    // Also add without trailing slash
    let without_slash = page.url_path.trim_end(chars="/").to_string()
    if not(without_slash.is_empty()) {
      valid_urls[without_slash] = true
    }
  }

  // Check each page
  for page in pages {
    let source_path = @path.join2(
      @path.join2(cwd, config.docs_dir),
      page.source_path,
    )

    // Read file content
    let content : String = @fs.readFileSync(source_path).to_string() catch {
      _ => continue
    }

    // Parse markdown
    let (frontmatter, nodes) = @markdown.parse_markdown(content)

    // Check frontmatter
    check_frontmatter(page.source_path, frontmatter, issues)

    // Check links - pass source_path to determine if it's an index page
    let is_index = page.source_path.has_suffix("index.md")
    check_links(
      page.source_path,
      page.url_path,
      is_index,
      nodes,
      valid_urls,
      issues,
    )

    // Check images
    check_images(page.source_path, nodes, issues)
  }

  // Count by severity
  let mut errors = 0
  let mut warnings = 0
  for issue in issues {
    match issue.severity {
      Error => errors = errors + 1
      Warning => warnings = warnings + 1
      Info => ()
    }
  }
  LintResult::{ issues, files_checked: pages.length(), errors, warnings }
}

///|
/// Check frontmatter for issues
fn check_frontmatter(
  file : String,
  fm : @astra.Frontmatter,
  issues : Array[LintIssue],
) -> Unit {
  // Check title
  if fm.title is None {
    issues.push(LintIssue::{
      severity: Warning,
      file,
      line: None,
      message: "Missing 'title' in frontmatter",
      rule: "missing-title",
    })
  }

  // Check description (warning only since we auto-generate)
  if fm.description is None {
    issues.push(LintIssue::{
      severity: Info,
      file,
      line: None,
      message: "Missing 'description' in frontmatter (will be auto-generated from content)",
      rule: "missing-description",
    })
  }
}

///|
/// Check links in markdown content
fn check_links(
  file : String,
  current_url : String,
  is_index : Bool,
  nodes : Array[@astra.MdNode],
  valid_urls : Map[String, Bool],
  issues : Array[LintIssue],
) -> Unit {
  check_links_recursive(file, current_url, is_index, nodes, valid_urls, issues)
}

///|
/// Recursively check links in nodes
fn check_links_recursive(
  file : String,
  current_url : String,
  is_index : Bool,
  nodes : Array[@astra.MdNode],
  valid_urls : Map[String, Bool],
  issues : Array[LintIssue],
) -> Unit {
  for node in nodes {
    match node {
      @astra.MdNode::Link(href~, children~, ..) => {
        // Check if internal link
        if is_internal_link(href) {
          let resolved = resolve_link(current_url, href, is_index)
          if not(is_valid_internal_link(resolved, valid_urls)) {
            issues.push(LintIssue::{
              severity: Error,
              file,
              line: None,
              message: "Dead link: '\{href}' (resolved to '\{resolved}')",
              rule: "dead-link",
            })
          }
        }
        // Check children
        check_links_recursive(
          file, current_url, is_index, children, valid_urls, issues,
        )
      }
      @astra.MdNode::Paragraph(children~) =>
        check_links_recursive(
          file, current_url, is_index, children, valid_urls, issues,
        )
      @astra.MdNode::Heading(children~, ..) =>
        check_links_recursive(
          file, current_url, is_index, children, valid_urls, issues,
        )
      @astra.MdNode::Bold(children~) =>
        check_links_recursive(
          file, current_url, is_index, children, valid_urls, issues,
        )
      @astra.MdNode::Italic(children~) =>
        check_links_recursive(
          file, current_url, is_index, children, valid_urls, issues,
        )
      @astra.MdNode::Blockquote(children~) =>
        check_links_recursive(
          file, current_url, is_index, children, valid_urls, issues,
        )
      @astra.MdNode::List(items~, ..) =>
        for item in items {
          check_links_recursive(
            file, current_url, is_index, item, valid_urls, issues,
          )
        }
      _ => ()
    }
  }
}

///|
/// Check if href is an internal link
fn is_internal_link(href : String) -> Bool {
  // External links
  if href.has_prefix("http://") || href.has_prefix("https://") {
    return false
  }
  // Mailto links
  if href.has_prefix("mailto:") {
    return false
  }
  // Hash-only links (anchors)
  if href.has_prefix("#") {
    return false
  }
  // JavaScript links
  if href.has_prefix("javascript:") {
    return false
  }
  true
}

///|
/// Resolve relative link to absolute path
/// - For index pages: use standard browser behavior (./foo = child)
/// - For content pages: use sibling behavior (./foo = sibling in parent dir)
fn resolve_link(current_url : String, href : String, is_index : Bool) -> String {
  // Already absolute
  if href.has_prefix("/") {
    return normalize_url(href)
  }

  // Handle ./ prefix
  let clean_href = if href.has_prefix("./") {
    let slice_result : String = href[2:].to_string() catch { _ => href }
    slice_result
  } else {
    href
  }

  // For index pages, use the current URL as base (standard browser behavior)
  // For content pages, use parent directory (sibling behavior)
  let base = if is_index {
    // Index page: /luna/api-js/ + signals = /luna/api-js/signals/
    current_url
  } else {
    // Content page: /luna/tutorial-js/introduction_basics/ -> parent /luna/tutorial-js/
    get_parent_directory(current_url)
  }
  normalize_url(base + clean_href)
}

///|
/// Get parent directory of a URL path
/// /luna/tutorial-js/introduction_basics/ -> /luna/tutorial-js/
fn get_parent_directory(url_path : String) -> String {
  // Remove trailing slash if present
  let trimmed = if url_path.has_suffix("/") {
    let slice_result : String = url_path[:url_path.length() - 1].to_string() catch {
      _ => url_path
    }
    slice_result
  } else {
    url_path
  }

  // Find last slash
  let chars = trimmed.to_array()
  let mut last_slash = 0
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '/' {
      last_slash = i
    }
  }
  if last_slash > 0 {
    String::from_array(chars[:last_slash + 1].to_array())
  } else {
    "/"
  }
}

///|
/// Normalize URL path
fn normalize_url(url : String) -> String {
  // Handle ./ and ../
  let mut result = url

  // Remove ./
  result = result.replace(old="/./", new="/")
  if result.has_prefix("./") {
    result = result.replace(old="./", new="/")
  }

  // Simple normalization - ensure ends with / or has extension
  if not(result.has_suffix("/")) && not(has_extension(result)) {
    result = result + "/"
  }
  result
}

///|
/// Check if URL has a file extension
fn has_extension(url : String) -> Bool {
  let parts = url.to_array()
  let mut last_dot = -1
  let mut last_slash = -1
  for i = 0; i < parts.length(); i = i + 1 {
    if parts[i] == '.' {
      last_dot = i
    }
    if parts[i] == '/' {
      last_slash = i
    }
  }
  last_dot > last_slash && last_dot > 0
}

///|
/// Check if resolved URL is valid
fn is_valid_internal_link(url : String, valid_urls : Map[String, Bool]) -> Bool {
  // Direct match
  if valid_urls.contains(url) {
    return true
  }

  // Try with trailing slash
  if not(url.has_suffix("/")) {
    if valid_urls.contains(url + "/") {
      return true
    }
  }

  // Try without trailing slash
  if url.has_suffix("/") {
    let without = url.trim_end(chars="/").to_string()
    if valid_urls.contains(without) {
      return true
    }
  }
  false
}

///|
/// Check images for alt text
fn check_images(
  file : String,
  nodes : Array[@astra.MdNode],
  issues : Array[LintIssue],
) -> Unit {
  check_images_recursive(file, nodes, issues)
}

///|
/// Recursively check images
fn check_images_recursive(
  file : String,
  nodes : Array[@astra.MdNode],
  issues : Array[LintIssue],
) -> Unit {
  for node in nodes {
    match node {
      @astra.MdNode::Image(src~, alt~, ..) =>
        if alt.is_empty() {
          issues.push(LintIssue::{
            severity: Warning,
            file,
            line: None,
            message: "Image missing alt text: '\{src}'",
            rule: "missing-alt",
          })
        }
      @astra.MdNode::Paragraph(children~) =>
        check_images_recursive(file, children, issues)
      @astra.MdNode::Heading(children~, ..) =>
        check_images_recursive(file, children, issues)
      @astra.MdNode::Bold(children~) =>
        check_images_recursive(file, children, issues)
      @astra.MdNode::Italic(children~) =>
        check_images_recursive(file, children, issues)
      @astra.MdNode::Blockquote(children~) =>
        check_images_recursive(file, children, issues)
      @astra.MdNode::List(items~, ..) =>
        for item in items {
          check_images_recursive(file, item, issues)
        }
      _ => ()
    }
  }
}

// =============================================================================
// Component Linting
// =============================================================================

///|
/// Check component directories for issues
fn check_components(base_dir : String, issues : Array[LintIssue]) -> Unit {
  if not(@fs.existsSync(base_dir)) {
    return
  }
  check_components_recursive(base_dir, "", issues)
}

///|
/// Recursively check component directories
fn check_components_recursive(
  base_dir : String,
  rel_path : String,
  issues : Array[LintIssue],
) -> Unit {
  let current_path = if rel_path.is_empty() {
    base_dir
  } else {
    @path.join2(base_dir, rel_path)
  }

  // Read directory entries
  let entries : Array[String] = @fs.readdirSync(current_path) catch { _ => [] }
  for entry in entries {
    let entry_path = @path.join2(current_path, entry)

    // Check if it's a directory
    let is_dir : Bool = @fs.statSync(entry_path).isDirectory() catch {
      _ => false
    }
    if is_dir {
      let entry_rel = if rel_path.is_empty() {
        entry
      } else {
        rel_path + "/" + entry
      }

      // Check if it's a component directory (has moon.pkg.json)
      let moon_pkg_path = @path.join2(entry_path, "moon.pkg.json")
      if @fs.existsSync(moon_pkg_path) {
        // It's a component directory - check for issues
        check_component_dir(entry_path, entry_rel, issues)
      } else {
        // Recurse into subdirectory
        check_components_recursive(base_dir, entry_rel, issues)
      }
    }
  }
}

///|
/// Check a component directory for lint issues
fn check_component_dir(
  dir_path : String,
  rel_path : String,
  issues : Array[LintIssue],
) -> Unit {
  // Check for client/ and server/ directories
  let client_path = @path.join2(dir_path, "client")
  let server_path = @path.join2(dir_path, "server")
  let has_client = @fs.existsSync(client_path) && is_dir(client_path)
  let has_server = @fs.existsSync(server_path) && is_dir(server_path)

  // Load page.json if exists
  let page_json_path = @path.join2(dir_path, "page.json")
  let page_config = if @fs.existsSync(page_json_path) {
    let content : String = @fs.readFileSync(page_json_path).to_string() catch {
      _ => ""
    }
    @core_routes.parse_page_config(content)
  } else {
    None
  }

  // Rule: orphan-client
  // Client-only component (no server directory) - warning
  if has_client && not(has_server) {
    issues.push(LintIssue::{
      severity: Warning,
      file: rel_path,
      line: None,
      message: "Component has client/ but no server/ directory (client-only, no SSR)",
      rule: "orphan-client",
    })
  }

  // Rule: orphan-server
  // Server-only component (no client directory) - info
  if has_server && not(has_client) {
    issues.push(LintIssue::{
      severity: Info,
      file: rel_path,
      line: None,
      message: "Component has server/ but no client/ directory (server-only, no hydration)",
      rule: "orphan-server",
    })
  }

  // Rule: missing-props
  // Component with client/ should have props_type defined
  if has_client {
    match page_config {
      Some(cfg) =>
        match cfg.component {
          Some(comp) =>
            if comp.props_type is None {
              issues.push(LintIssue::{
                severity: Warning,
                file: rel_path + "/page.json",
                line: None,
                message: "Component with client/ should define 'component.props_type' in page.json",
                rule: "missing-props",
              })
            }
          None =>
            issues.push(LintIssue::{
              severity: Warning,
              file: rel_path,
              line: None,
              message: "Component with client/ should have 'component' config in page.json",
              rule: "missing-props",
            })
        }
      None =>
        issues.push(LintIssue::{
          severity: Warning,
          file: rel_path,
          line: None,
          message: "Component directory should have page.json with component configuration",
          rule: "missing-props",
        })
    }
  }

  // Rule: empty-static-params
  // Dynamic route component should have static_params for pre-generation
  let is_dynamic = rel_path.contains("_") // Contains dynamic segment like _slug_
  if is_dynamic {
    match page_config {
      Some(cfg) =>
        if cfg.static_params.is_empty() && cfg.mode != Some("ssr") {
          issues.push(LintIssue::{
            severity: Warning,
            file: rel_path + "/page.json",
            line: None,
            message: "Dynamic route component should define 'static_params' for static generation",
            rule: "empty-static-params",
          })
        }
      None =>
        issues.push(LintIssue::{
          severity: Warning,
          file: rel_path,
          line: None,
          message: "Dynamic route should have page.json with static_params",
          rule: "empty-static-params",
        })
    }
  }
}

///|
/// Check if path is a directory
fn is_dir(path : String) -> Bool {
  @fs.statSync(path).isDirectory() catch {
    _ => false
  }
}

///|
/// Print lint results
fn print_lint_results(result : LintResult) -> Unit {
  // Group issues by file
  let by_file : Map[String, Array[LintIssue]] = {}
  for issue in result.issues {
    match by_file.get(issue.file) {
      Some(arr) => arr.push(issue)
      None => by_file[issue.file] = [issue]
    }
  }

  // Print issues by file
  for file in by_file.keys() {
    let issues = by_file.get(file).unwrap()
    println(@colorette.bold(file))
    for issue in issues {
      let severity_str = match issue.severity {
        Error => @colorette.red("error")
        Warning => @colorette.yellow("warning")
        Info => @colorette.blue("info")
      }
      let line_str = match issue.line {
        Some(n) => ":\{n}"
        None => ""
      }
      println("  \{severity_str}\{line_str}: \{issue.message} [\{issue.rule}]")
    }
    println("")
  }

  // Print summary
  println(@colorette.bold("Summary:"))
  println("  Files checked: \{result.files_checked}")
  if result.errors > 0 {
    println("  Errors: \{@colorette.red(result.errors.to_string())}")
  }
  if result.warnings > 0 {
    println("  Warnings: \{@colorette.yellow(result.warnings.to_string())}")
  }
  if result.errors == 0 && result.warnings == 0 {
    let msg = @colorette.green("No issues found!")
    println("  \{msg}")
  }
}
