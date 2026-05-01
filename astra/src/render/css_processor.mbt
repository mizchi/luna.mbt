// CSS Processor - CSS extraction, minification, and utility processing.
// Minification (`@css_kit.minify_css`) and theme-overrides
// (`@css_kit.build_theme_overrides`) live in `astra/internal/css_kit` so
// the static-build path here and the middleware-served path in
// `astra/assets/lookup.mbt` share one canonical implementation.

// =============================================================================
// CSS Utilities Extraction
// =============================================================================

///|
/// Extract CSS utilities from source files using static analysis
/// Returns the extracted CSS string or empty string on failure
async fn extract_css_utilities(
  cwd : String,
  source_dirs : Array[String],
) -> String {
  ffi_extract_css_utilities(cwd, source_dirs).wait()
}

///|
/// FFI to run CSS extraction script (async version for ESM)
/// Uses child_process.execSync to run node src/luna/css/extract.js
extern "js" fn ffi_extract_css_utilities(
  cwd : String,
  source_dirs : Array[String],
) -> @js.Promise[String] =
  #| async (cwd, sourceDirs) => {
  #|   try {
  #|     const cp = await import('child_process');
  #|     const path = await import('path');
  #|     const fs = await import('fs');
  #|
  #|     // Find extract.js script - try multiple locations
  #|     const possiblePaths = [
  #|       // Development: direct path in monorepo
  #|       path.join(cwd, 'src/luna/css/extract.js'),
  #|       // NPM package: bundled with sol
  #|       path.join(cwd, 'node_modules/@luna_ui/sol/css/extract.js'),
  #|       // Parent project (when running from examples/)
  #|       path.join(cwd, '../src/luna/css/extract.js'),
  #|       path.join(cwd, '../../src/luna/css/extract.js'),
  #|     ];
  #|
  #|     let extractScript = null;
  #|     for (const p of possiblePaths) {
  #|       if (fs.existsSync(p)) {
  #|         extractScript = p;
  #|         break;
  #|       }
  #|     }
  #|
  #|     if (!extractScript) {
  #|       // Script not found - silently return empty
  #|       return '';
  #|     }
  #|
  #|     // Build command with all source directories
  #|     const dirs = sourceDirs.filter(d => {
  #|       const fullPath = path.join(cwd, d);
  #|       return fs.existsSync(fullPath);
  #|     });
  #|
  #|     if (dirs.length === 0) {
  #|       return '';
  #|     }
  #|
  #|     // Run extraction for each directory and combine results
  #|     let allCss = '';
  #|     for (const dir of dirs) {
  #|       try {
  #|         const fullDir = path.join(cwd, dir);
  #|         const result = cp.execSync(`node "${extractScript}" "${fullDir}" --no-warn`, {
  #|           cwd: cwd,
  #|           encoding: 'utf-8',
  #|           stdio: ['pipe', 'pipe', 'pipe'],
  #|         });
  #|         if (result && result.trim()) {
  #|           allCss += result.trim() + '\n';
  #|         }
  #|       } catch (e) {
  #|         // Ignore errors for individual directories
  #|       }
  #|     }
  #|
  #|     return allCss.trim();
  #|   } catch (e) {
  #|     console.error('CSS extraction failed:', e.message);
  #|     return '';
  #|   }
  #| }

// =============================================================================
// Parallel CSS Extraction using Process Pool
// =============================================================================

///|
/// Configuration for parallel CSS extraction
pub struct ParallelCssConfig {
  /// Maximum number of concurrent processes
  max_workers : Int
  /// Timeout per job in milliseconds
  timeout_ms : Int
}

///|
pub fn ParallelCssConfig::default() -> ParallelCssConfig {
  { max_workers: 4, timeout_ms: 30000 }
}

///|
/// Find the extract.js script path
fn find_extract_script(cwd : String) -> String? {
  let possible_paths = [
    @path.join2(cwd, "src/luna/css/extract.js"),
    @path.join2(cwd, "node_modules/@luna_ui/sol/css/extract.js"),
    @path.join2(cwd, "../src/luna/css/extract.js"),
    @path.join2(cwd, "../../src/luna/css/extract.js"),
  ]
  for p in possible_paths {
    if ffi_exists_sync(p) {
      return Some(p)
    }
  }
  None
}

///|
extern "js" fn ffi_exists_sync(path : String) -> Bool =
  #| (path) => {
  #|   try {
  #|     const fs = require('fs');
  #|     return fs.existsSync(path);
  #|   } catch {
  #|     return false;
  #|   }
  #| }

///|
/// Extract CSS utilities from source files in parallel
/// Uses process_pool for concurrent execution
pub async fn extract_css_utilities_parallel(
  cwd : String,
  source_dirs : Array[String],
  config : ParallelCssConfig,
) -> String {
  // Find extract script
  guard find_extract_script(cwd) is Some(extract_script) else { return "" }

  // Filter to existing directories
  let valid_dirs : Array[String] = []
  for dir in source_dirs {
    let full_path = @path.join2(cwd, dir)
    if ffi_exists_sync(full_path) {
      valid_dirs.push(full_path)
    }
  }
  if valid_dirs.is_empty() {
    return ""
  }

  // Create process pool
  let pool = @process_pool.ProcessPool::new(max_workers=config.max_workers)

  // Create jobs for each directory
  let jobs = valid_dirs.map(fn(dir) {
    @process_pool.job(
      "node",
      [extract_script, dir, "--no-warn"],
      cwd~,
      timeout=config.timeout_ms,
    )
  })

  // Run all jobs in parallel
  let results = pool.run_all(jobs)

  // Combine results
  let css_parts : Array[String] = []
  for result in results {
    if result.exit_code == 0 && !(result.stdout.is_empty()) {
      let trimmed = result.stdout.trim().to_string()
      if !(trimmed.is_empty()) {
        css_parts.push(trimmed)
      }
    }
  }
  css_parts.join("\n")
}

///|
/// Extract CSS with automatic parallelization based on directory count
pub async fn extract_css_utilities_auto(
  cwd : String,
  source_dirs : Array[String],
) -> String {
  // Use parallel extraction if multiple directories
  if source_dirs.length() > 1 {
    extract_css_utilities_parallel(
      cwd,
      source_dirs,
      ParallelCssConfig::default(),
    )
  } else {
    // Fall back to sequential for single directory
    ffi_extract_css_utilities(cwd, source_dirs).wait()
  }
}

///|
/// CSS manifest entry from split extraction
pub(all) struct CssManifestEntry {
  css : String
  size : Int
} derive(FromJson, ToJson)

///|
/// CSS split manifest result
pub(all) struct CssSplitManifest {
  entries : Map[String, CssManifestEntry]
  shared_css : String
  shared_size : Int
} derive(FromJson, ToJson)

// =============================================================================
// CSS Building
// =============================================================================

///|
/// Build combined CSS with optional minification (skip in dev mode)
fn build_combined_css(
  config : @astra.SsgConfig,
  is_dev? : Bool = false,
) -> String {
  // Clear cache in dev mode to always read fresh CSS files
  if is_dev {
    @assets.clear_cache()
  }
  let main_css = @assets.get_default_css(config)
  let markdown_css = @assets.get_github_markdown_css()
  let shiki_css = @shiki.generate_shiki_css()
  let all_css = main_css + "\n" + markdown_css + "\n" + shiki_css
  let output_css = if is_dev { all_css } else { @css_kit.minify_css(all_css) }
  let theme_vars = @css_kit.build_theme_overrides(config.theme)
  if theme_vars.is_empty() {
    output_css
  } else {
    "\{output_css}:root{\{theme_vars}}"
  }
}
