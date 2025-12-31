///|
/// SSG-specific Hash Utilities
///
/// Uses fnv_hash.mbt for underlying hash functions.

///|
/// Compute hash for a page's cache key
pub fn compute_page_hash(
  source_content : String,
  frontmatter_json : String,
  config_hash : String,
) -> String {
  hash_strings([source_content, frontmatter_json, config_hash])
}

///|
/// Compute hash for config (used to invalidate all caches on config change)
pub fn compute_config_hash(config : @ssg.SsgConfig) -> String {
  // Hash key config fields that affect rendering
  let parts = [
    config.title,
    config.base_url,
    if config.trailing_slash {
      "true"
    } else {
      "false"
    },
    config.theme.primary_color.unwrap_or(""),
  ]
  fnv1a(parts.join("\u0000"))
}

///|
/// Compute hash for all content files in docs directory
/// Uses file paths and their content hashes
pub fn compute_content_hash(
  docs_dir : String,
  cwd : String,
  exclude : Array[String],
) -> String {
  let full_docs_dir = @path.join2(cwd, docs_dir)
  let hashes : Array[String] = []
  collect_file_hashes(full_docs_dir, full_docs_dir, exclude, hashes)
  // Sort for deterministic hash
  hashes.sort_by(fn(a, b) { a.compare(b) })
  fnv1a_64(hashes.join("\u0000"))
}

///|
/// Recursively collect file hashes from directory
fn collect_file_hashes(
  dir : String,
  base_dir : String,
  exclude : Array[String],
  hashes : Array[String],
) -> Unit {
  guard @fs.existsSync(dir) else { return }
  let entries = @fs.readdirSync(dir) catch { _ => return }
  for entry in entries {
    // Skip excluded directories
    if exclude.contains(entry) {
      continue
    }
    let full_path = @path.join2(dir, entry)
    let is_dir = @fs.statSync(full_path).isDirectory() catch { _ => continue }
    if is_dir {
      collect_file_hashes(full_path, base_dir, exclude, hashes)
    } else if entry.has_suffix(".md") || entry.has_suffix(".mdx") {
      // Hash file path relative to base + content
      let base_len = base_dir.length()
      let rel_path = full_path[base_len:].to_string() catch { _ => continue }
      let content : String = @fs.readFileSync(full_path).to_string() catch {
        _ => continue
      }
      let file_hash = hash_content(content, rel_path)
      hashes.push(file_hash)
    }
  }
}

///|
/// Compute hash for asset files (CSS, JS) in a directory
/// Used to detect changes in src/astra/assets that should invalidate cache
/// Searches multiple paths similar to load_asset in loader.mbt
pub fn compute_assets_hash(cwd : String) -> String {
  // Try multiple paths to find assets directory
  let paths = [
    @path.join2(cwd, "src/astra/assets"),
    "src/astra/assets",
    @path.join2(cwd, "../src/astra/assets"),
    @path.join2(cwd, "../../src/astra/assets"),
    @path.join2(cwd, "node_modules/@luna_ui/sol/assets"),
  ]
  for assets_dir in paths {
    if @fs.existsSync(assets_dir) {
      let hashes : Array[String] = []
      collect_asset_hashes(assets_dir, assets_dir, hashes)
      hashes.sort_by(fn(a, b) { a.compare(b) })
      return fnv1a_64(hashes.join("\u0000"))
    }
  }
  fnv1a_64("")
}

///|
/// Recursively collect asset file hashes
fn collect_asset_hashes(
  dir : String,
  base_dir : String,
  hashes : Array[String],
) -> Unit {
  guard @fs.existsSync(dir) else { return }
  let entries = @fs.readdirSync(dir) catch { _ => return }
  for entry in entries {
    let full_path = @path.join2(dir, entry)
    let is_dir = @fs.statSync(full_path).isDirectory() catch { _ => continue }
    if is_dir {
      collect_asset_hashes(full_path, base_dir, hashes)
    } else if entry.has_suffix(".css") ||
      entry.has_suffix(".js") ||
      entry.has_suffix(".json") {
      let base_len = base_dir.length()
      let rel_path = full_path[base_len:].to_string() catch { _ => continue }
      let content : String = @fs.readFileSync(full_path).to_string() catch {
        _ => continue
      }
      let file_hash = hash_content(content, rel_path)
      hashes.push(file_hash)
    }
  }
}
