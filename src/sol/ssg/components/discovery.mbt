// Component Discovery for Sol SSG
// Convention-based component file detection

// =============================================================================
// Component Discovery Types
// =============================================================================

///|
/// Component types that can be discovered
pub(all) enum ComponentType {
  Header
  Footer
  Toc
  Breadcrumb
  PrevNext
} derive(Eq, Show)

///|
/// Get the conventional filename for a component type
pub fn ComponentType::filename(self : ComponentType) -> String {
  match self {
    Header => "header.mbt"
    Footer => "footer.mbt"
    Toc => "toc.mbt"
    Breadcrumb => "breadcrumb.mbt"
    PrevNext => "prev_next.mbt"
  }
}

///|
/// Get all component types
pub fn all_component_types() -> Array[ComponentType] {
  [Header, Footer, Toc, Breadcrumb, PrevNext]
}

///|
/// Result of component discovery
pub(all) struct DiscoveryResult {
  /// Directory that was scanned
  scanned_dir : String
  /// Components that were found
  found : Array[ComponentType]
  /// Components that are missing (using defaults)
  missing : Array[ComponentType]
}

///|
/// Create empty discovery result
pub fn DiscoveryResult::new(dir : String) -> DiscoveryResult {
  { scanned_dir: dir, found: [], missing: [] }
}

// =============================================================================
// Discovery Functions
// =============================================================================

///|
/// Get the components directory path from config
/// Returns `<docs_dir>/components` if not explicitly configured
pub fn get_components_dir(config : @ssg.SsgConfig) -> String {
  match config.components_dir {
    Some(dir) => dir
    None => config.docs_dir + "/components"
  }
}

///|
/// Discover components in the configured directory
/// Returns which components exist and which are missing
pub fn discover_components(
  config : @ssg.SsgConfig,
  cwd : String,
) -> DiscoveryResult {
  let components_dir = get_components_dir(config)
  let full_path = @path.join2(cwd, components_dir)
  let result = DiscoveryResult::new(components_dir)

  // Check if directory exists
  if not(@fs.existsSync(full_path)) {
    // Directory doesn't exist - all components are "missing" (using defaults)
    for ct in all_component_types() {
      result.missing.push(ct)
    }
    return result
  }

  // Check each component type
  for ct in all_component_types() {
    let file_path = @path.join2(full_path, ct.filename())
    if @fs.existsSync(file_path) {
      result.found.push(ct)
    } else {
      result.missing.push(ct)
    }
  }
  result
}

///|
/// Format discovery result for display
pub fn DiscoveryResult::to_string(self : DiscoveryResult) -> String {
  let lines : Array[String] = []
  lines.push("Components directory: " + self.scanned_dir)
  lines.push("")
  if self.found.length() > 0 {
    lines.push("Found components:")
    for ct in self.found {
      lines.push("  + " + ct.filename())
    }
  }
  if self.missing.length() > 0 {
    if self.found.length() > 0 {
      lines.push("")
    }
    lines.push("Using defaults:")
    for ct in self.missing {
      lines.push("  - " + ct.filename() + " (default)")
    }
  }
  lines.join("\n")
}
