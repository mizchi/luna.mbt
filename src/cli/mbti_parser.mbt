// MBTI Parser - Parse MoonBit interface files for code generation

// =============================================================================
// MBTI Parsing
// =============================================================================

///|
/// Parse mbti imports to build alias mapping
pub fn parse_mbti_imports(content : String) -> Map[String, String] {
  // Returns: Map[alias -> package_path]
  let result : Map[String, String] = {}
  let lines = content.split("\n").to_array()
  let mut in_import = false
  for line in lines {
    let line_str = line.to_string()
    let trimmed = line_str.trim_space().to_string()
    if trimmed == "import(" {
      in_import = true
      continue
    }
    if in_import {
      if trimmed == ")" {
        in_import = false
        continue
      }
      // Parse: "package/path" or "package/path" as alias
      if trimmed.has_prefix("\"") {
        // Find second quote
        let after_first = trimmed.unsafe_substring(
          start=1,
          end=trimmed.length(),
        )
        if after_first.find("\"") is Some(end_quote) {
          let pkg_path = after_first.unsafe_substring(start=0, end=end_quote)
          // Extract alias (last part of path)
          let parts = pkg_path.split("/").to_array()
          if parts.length() > 0 {
            let alias_part = parts[parts.length() - 1].to_string()
            result[alias_part] = pkg_path
          }
        }
      }
    }
  }
  result
}

///|
/// Rewrite type references from mbti format to exports format
pub fn rewrite_type_refs(
  sig : String,
  _imports : Map[String, String],
) -> String {
  // mbti uses @alias.Type where alias is the last part of package path
  // We need to map to the correct alias in exports module
  // Use known type patterns for robust mapping
  let mut result = sig
  // Luna types - always rewrite @core.Node/Attr/VNode to @luna
  result = result.replace_all(old="@core.Node", new="@luna.Node")
  result = result.replace_all(old="@core.Attr", new="@luna.Attr")
  result = result.replace_all(old="@core.VNode", new="@luna.VNode")
  // Luna 0.8.1: Node[E] -> Node[E, String], Attr[E] -> Attr[E, String]
  result = result.replace_all(old="@luna.Node[Unit]", new="@luna.Node[Unit, String]")
  result = result.replace_all(old="@luna.Attr[Unit]", new="@luna.Attr[Unit, String]")
  // JS types - always rewrite @core.Any to @js
  result = result.replace_all(old="@core.Any", new="@js.Any")
  result
}

///|
/// Parse mbti file and extract pub fn declarations
pub fn parse_mbti(content : String) -> Array[(String, String)] {
  let result : Array[(String, String)] = []
  let imports = parse_mbti_imports(content)
  let lines = content.split("\n").to_array()
  for line in lines {
    let line_str = line.to_string()
    let trimmed = line_str.trim_start(chars=" \t").to_string()
    // Look for "pub fn name(...) -> RetType"
    if trimmed.has_prefix("pub fn ") {
      let rest = trimmed.unsafe_substring(start=7, end=trimmed.length()) // After "pub fn "
      // Find function name (up to first '(')
      if rest.find("(") is Some(paren_idx) {
        let name = rest.unsafe_substring(start=0, end=paren_idx)
        // Get signature (from '(' to end of line)
        let sig = rest.unsafe_substring(start=paren_idx, end=rest.length())
        // Rewrite type references
        let rewritten_sig = rewrite_type_refs(sig, imports)
        result.push((name, rewritten_sig))
      }
    }
  }
  result
}

///|
/// Find mbti files in directories matching glob patterns
fn find_mbti_files(
  cwd : String,
  patterns : Array[String],
) -> Array[(String, String, String)] {
  let fs = @fs_adapter.NodeFsAdapter::new()
  find_mbti_files_with_fs(fs, cwd, patterns)
}

///|
fn[FS : @env.FileSystem] find_mbti_files_with_fs(
  fs : FS,
  cwd : String,
  patterns : Array[String],
) -> Array[(String, String, String)] {
  // Returns: Array of (pattern, dir_path, mbti_content)
  let result : Array[(String, String, String)] = []
  for pattern in patterns {
    let base_path = @path.join2(cwd, pattern)
    // Check if pattern ends with /* (directory glob)
    if pattern.has_suffix("/*") {
      // List subdirectories
      let parent = base_path.substring(end=base_path.length() - 2)
      if fs.exists_sync(parent) {
        try {
          let entries = fs.readdir_sync(parent)
          for entry in entries {
            let entry_path = @path.join2(parent, entry)
            let mbti_path = @path.join2(entry_path, "pkg.generated.mbti")
            if fs.exists_sync(mbti_path) {
              let content = fs.read_file_sync(mbti_path)
              // For glob patterns, use the actual subdirectory as the pattern
              let sub_pattern = pattern.substring(end=pattern.length() - 2) +
                "/" +
                entry.to_string()
              result.push((sub_pattern, entry_path, content))
            }
          }
        } catch {
          _ => ()
        }
      }
    } else {
      // Direct directory
      let mbti_path = @path.join2(base_path, "pkg.generated.mbti")
      if fs.exists_sync(mbti_path) {
        try {
          let content = fs.read_file_sync(mbti_path)
          result.push((pattern, base_path, content))
        } catch {
          _ => ()
        }
      }
    }
  }
  result
}

///|
/// Extract package path from mbti content
pub fn extract_package_path(mbti_content : String) -> String? {
  let lines = mbti_content.split("\n").to_array()
  for line in lines {
    let line_str = line.to_string()
    let trimmed = line_str.trim_start(chars=" \t").to_string()
    if trimmed.has_prefix("package \"") {
      let start = 9 // len of 'package "'
      let after_prefix = trimmed.unsafe_substring(start~, end=trimmed.length())
      if after_prefix.find("\"") is Some(end_quote) {
        return Some(trimmed.unsafe_substring(start~, end=end_quote + start))
      }
    }
  }
  None
}
