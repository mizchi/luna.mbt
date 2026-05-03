// Asset Copier - Static asset copying, bundling, and boot runtime

// =============================================================================
// Static Asset Copying
// =============================================================================

///|
/// Copy static assets to output directory (sync version, no CSS extraction)
pub fn copy_static_assets(ctx : @astra.BuildContext) -> Unit {
  copy_static_assets_internal(ctx, "")
}

///|
/// Copy static assets to output directory (async version with CSS extraction)
pub async fn copy_static_assets_async(ctx : @astra.BuildContext) -> Unit {
  // Get CSS utilities config
  let css_config = ctx.config.css_utilities.unwrap_or(
    @astra.CssUtilitiesConfig::default(),
  )

  // Get source directories to scan
  let source_dirs = if css_config.source_dirs.is_empty() {
    ["src/sol/ssg", "src/luna", ctx.config.docs_dir]
  } else {
    css_config.source_dirs
  }

  // Extract CSS utilities from source files
  let utility_css = if css_config.enabled {
    extract_css_utilities(ctx.cwd, source_dirs)
  } else {
    ""
  }

  // Determine if CSS should be inlined based on threshold
  let css_size = utility_css.length()
  let should_inline = css_size <= css_config.inline_threshold
  if should_inline {
    copy_static_assets_internal(ctx, utility_css)
  } else {
    // Write CSS to separate file and reference it
    let output_assets = @path.join2(
      @path.join2(ctx.cwd, ctx.config.output_dir),
      "assets",
    )
    ensure_dir(output_assets)
    let utility_css_path = @path.join2(output_assets, "utilities.css")
    @fs.writeFileSync(utility_css_path, @js.any(utility_css)) catch {
      _ => ()
    }
    println("  Extracted CSS utilities: \{css_size} bytes (external file)")
    copy_static_assets_internal(ctx, "")
  }
}

///|
/// Internal implementation of copy_static_assets
fn copy_static_assets_internal(
  ctx : @astra.BuildContext,
  utility_css : String,
) -> Unit {
  let output_assets = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    "assets",
  )
  ensure_dir(output_assets)

  // Write default CSS
  let css = @assets.get_default_css(ctx.config)

  // Combine with utility CSS if provided
  let full_css = if utility_css.is_empty() {
    css
  } else {
    println("  Extracted CSS utilities from source files")
    css + "\n/* === CSS Utilities (auto-extracted) === */\n" + utility_css
  }
  // Minify CSS only for production builds (skip in dev mode for readability)
  let output_css = if ctx.is_dev { full_css } else { @css_kit.minify_css(full_css) }
  let css_path = @path.join2(output_assets, "style.css")
  @fs.writeFileSync(css_path, @js.any(output_css)) catch {
    _ => ()
  }

  // Write shiki CSS (minified only in production)
  let shiki_raw = @shiki.generate_shiki_css()
  let shiki_css = if ctx.is_dev { shiki_raw } else { @css_kit.minify_css(shiki_raw) }
  let shiki_css_path = @path.join2(output_assets, "shiki.css")
  @fs.writeFileSync(shiki_css_path, @js.any(shiki_css)) catch {
    _ => ()
  }

  // Write github-markdown CSS (minified only in production)
  let github_md_raw = @assets.get_github_markdown_css()
  let github_md_css = if ctx.is_dev {
    github_md_raw
  } else {
    @css_kit.minify_css(github_md_raw)
  }
  let github_md_css_path = @path.join2(output_assets, "github-markdown.css")
  @fs.writeFileSync(github_md_css_path, @js.any(github_md_css)) catch {
    _ => ()
  }

  // Write loader.js (for island hydration)
  let loader_js = @assets.get_island_loader_js()
  let loader_js_path = @path.join2(output_assets, "loader.js")
  @fs.writeFileSync(loader_js_path, @js.any(loader_js)) catch {
    _ => ()
  }

  // Copy public directory if it exists
  copy_public_dir(ctx)

  // Copy islands directory if configured
  copy_islands_dir(ctx)

  // Copy boot runtime files to _luna/
  copy_boot_runtime(ctx)
}

// =============================================================================
// Boot Runtime
// =============================================================================

///|
/// Copy boot runtime files to _luna/ directory
fn copy_boot_runtime(ctx : @astra.BuildContext) -> Unit {
  // Try to find boot files in various locations
  let possible_sources = [
    // Development: monorepo structure
    @path.join2(ctx.cwd, "js/loader/dist"),
    // NPM package: node_modules
    @path.join2(ctx.cwd, "node_modules/@luna_ui/luna-loader/dist"),
  ]

  // Find first existing source
  let mut boot_src : String? = None
  for src in possible_sources {
    let boot_file = @path.join2(src, "boot.iife.js")
    if @fs.existsSync(boot_file) {
      boot_src = Some(src)
      break
    }
  }

  // Skip if no boot files found
  guard boot_src is Some(src_dir) else { return }

  // Create _luna/ directory
  let luna_dir = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    "_luna",
  )
  ensure_dir(luna_dir)

  // Copy boot.iife.js (self-contained boot runtime)
  let boot_src_file = @path.join2(src_dir, "boot.iife.js")
  let boot_dest_file = @path.join2(luna_dir, "boot.js")
  @fs.copyFileSync(boot_src_file, boot_dest_file) catch {
    e => {
      println("  Warning: Failed to copy boot.js: \{e}")
      return
    }
  }
  println("  Copied: /_luna/boot.js")

  // Optionally copy modular boot files for advanced usage
  let boot_dir = @path.join2(src_dir, "boot")
  if @fs.existsSync(boot_dir) {
    let luna_boot_dir = @path.join2(luna_dir, "boot")
    ensure_dir(luna_boot_dir)
    @fs.cpSync(boot_dir, luna_boot_dir, recursive=true) catch {
      _ => ()
    }
    println("  Copied: /_luna/boot/ (modular)")
  }
}

// =============================================================================
// Islands Bundling
// =============================================================================

///|
/// Bundle components directory to output using rolldown (convention: docs/components -> /components/)
fn copy_islands_dir(ctx : @astra.BuildContext) -> Unit {
  // Use config if provided, otherwise use convention (docs/components)
  let (src_dir, base_path) = match ctx.config.islands {
    Some(islands_config) => (islands_config.dir, islands_config.base_path)
    None => {
      // Convention-based: look for docs/components
      let docs_components = @path.join2(ctx.config.docs_dir, "components")
      (docs_components, "/components/")
    }
  }
  let islands_src = @path.join2(ctx.cwd, src_dir)

  // Check if source directory exists
  if !(@fs.existsSync(islands_src)) {
    // Silently skip if using convention and directory doesn't exist
    return
  }

  // Output path: strip leading slash from base_path
  let output_subdir = if base_path.has_prefix("/") {
    base_path.unsafe_substring(start=1, end=base_path.length())
  } else {
    base_path
  }
  // Remove trailing slash for directory path
  let output_subdir_clean = if output_subdir.has_suffix("/") {
    output_subdir.unsafe_substring(start=0, end=output_subdir.length() - 1)
  } else {
    output_subdir
  }
  let islands_dest = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    output_subdir_clean,
  )

  // Ensure destination directory exists
  ensure_dir(islands_dest)

  // Bundle components using rolldown
  bundle_components(islands_src, islands_dest, ctx.cwd)
}

///|
/// Find js/luna/src path by checking current and parent directories
fn find_luna_path(start_dir : String) -> String {
  // Check current directory and up to 3 parent levels
  let mut dir = start_dir
  for _ in 0..<4 {
    // Check js/luna/src first
    let luna_src = @path.join2(dir, "js/luna/src")
    if @fs.existsSync(luna_src) {
      return luna_src
    }
    // Check .mooncakes/mizchi/luna/js/luna/src (mooncakes path)
    let mooncakes_luna = @path.join2(dir, ".mooncakes/mizchi/luna/js/luna/src")
    if @fs.existsSync(mooncakes_luna) {
      return mooncakes_luna
    }
    // Go up one level
    let parent = @path.dirname(dir)
    if parent == dir {
      // Reached root
      break
    }
    dir = parent
  }
  // Fallback - assume it's in the current directory structure
  @path.join2(start_dir, "js/luna/src")
}

///|
/// Bundle components using rolldown
fn bundle_components(src_dir : String, dest_dir : String, cwd : String) -> Unit {
  // Scan for JS/TS files in source directory
  let entries : Array[String] = @fs.readdirSync(src_dir) catch { _ => [] }

  // Filter for bundleable files
  let js_files : Array[String] = []
  for entry in entries {
    if entry.has_suffix(".js") || entry.has_suffix(".ts") {
      js_files.push(entry)
    }
  }
  if js_files.is_empty() {
    return
  }

  // Create rolldown input object
  let input_entries : Array[String] = []
  for file in js_files {
    // Remove .js or .ts extension (3 chars)
    let end_idx = file.length() - 3
    let name = file[:end_idx].to_string() catch {
      _ => file // fallback to original filename
    }
    let entry_path = @path.join2(src_dir, file)
    input_entries.push("\"\{name}\": \"\{entry_path}\"")
  }
  let input_obj = "{ " + input_entries.join(", ") + " }"

  // Generate rolldown build script
  // Find js/luna path by checking current dir and parent dirs
  let luna_path = find_luna_path(cwd)
  let build_script =
    #|import { build } from 'rolldown';
    #|import path from 'node:path';
    #|await build({
    #|  input: __INPUT__,
    #|  output: {
    #|    dir: '__OUTPUT__',
    #|    format: 'esm',
    #|    entryFileNames: '[name].js',
    #|    chunkFileNames: '_shared/[name]-[hash].js'
    #|  },
    #|  resolve: {
    #|    extensions: ['.ts', '.js', '.mjs'],
    #|    alias: {
    #|      '@luna': '__LUNA_PATH__'
    #|    }
    #|  }
    #|});
  let script = build_script
    .replace(old="__INPUT__", new=input_obj)
    .replace(old="__OUTPUT__", new=dest_dir)
    .replace(old="__LUNA_PATH__", new=luna_path)

  // Run rolldown
  println("  Bundling components from \{src_dir}...")
  try {
    let result = @child_process.spawnSync(
      "node",
      args=["--input-type=module", "-e", script],
      stdio="inherit",
      cwd~,
    )
    if result.status() != Some(0) {
      println("  Warning: Failed to bundle components")
    }
  } catch {
    e => println("  Warning: Bundle error: \{e}")
  }
}

///|
/// Copy docs/public directory to output root
fn copy_public_dir(ctx : @astra.BuildContext) -> Unit {
  let public_dir = @path.join2(
    @path.join2(ctx.cwd, ctx.config.docs_dir),
    "public",
  )
  let output_dir = @path.join2(ctx.cwd, ctx.config.output_dir)

  // Check if public directory exists
  if !(@fs.existsSync(public_dir)) {
    return
  }

  // Copy entire public directory contents to output
  println("  Copying public assets...")
  @fs.cpSync(public_dir, output_dir, recursive=true) catch {
    e => println("  Warning: Failed to copy public directory: \{e}")
  }
}
