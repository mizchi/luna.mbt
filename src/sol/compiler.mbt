///| Sol Compiler - Rolldown-based bundler for Islands

// ============================================================================
// Rolldown Bindings
// ============================================================================

///|
extern "js" fn ffi_rolldown_build(options : @js.Any) -> @js.Promise[RolldownOutput] =
  #| async (options) => {
  #|   const { build } = await import('rolldown');
  #|   return await build(options);
  #| }

///|
/// Rolldown build output
#external
pub type RolldownOutput

///|
pub fn RolldownOutput::as_any(self : RolldownOutput) -> @js.Any = "%identity"

///|
/// Get output chunks from build result
pub fn RolldownOutput::output(self : RolldownOutput) -> Array[RolldownChunk] {
  let output_arr = self.as_any()._get("output")
  if @js.is_undefined(output_arr) || @js.is_null(output_arr) {
    return []
  }
  let len : Int = @js.identity(output_arr._get("length"))
  let result : Array[RolldownChunk] = []
  for i = 0; i < len; i = i + 1 {
    result.push(output_arr._get(i.to_string()).cast())
  }
  result
}

///|
/// Rolldown output chunk
#external
pub type RolldownChunk

///|
pub fn RolldownChunk::as_any(self : RolldownChunk) -> @js.Any = "%identity"

///|
/// Get the file name
pub fn RolldownChunk::file_name(self : RolldownChunk) -> String {
  @js.identity(self.as_any()._get("fileName"))
}

///|
/// Get the chunk code
pub fn RolldownChunk::code(self : RolldownChunk) -> String {
  let code = self.as_any()._get("code")
  if @js.is_undefined(code) {
    ""
  } else {
    @js.identity(code)
  }
}

///|
/// Check if this is an entry chunk
pub fn RolldownChunk::is_entry(self : RolldownChunk) -> Bool {
  let is_entry = self.as_any()._get("isEntry")
  if @js.is_undefined(is_entry) {
    false
  } else {
    @js.identity(is_entry)
  }
}

// ============================================================================
// Build Configuration
// ============================================================================

///|
/// Output format for bundled code
pub enum OutputFormat {
  Esm
  Cjs
  Iife
}

///|
pub fn OutputFormat::to_string(self : OutputFormat) -> String {
  match self {
    Esm => "esm"
    Cjs => "cjs"
    Iife => "iife"
  }
}

///|
/// Bundle configuration
pub struct BundleConfig {
  /// Input entries: Map of output name -> input path
  input : Array[(String, String)]
  /// Output directory
  output_dir : String
  /// Output format (default: esm)
  format : OutputFormat
  /// Entry file name pattern (default: "[name].js")
  entry_file_names : String
  /// Chunk file name pattern (default: "_shared/[name]-[hash].js")
  chunk_file_names : String
  /// Whether to minify output
  minify : Bool
  /// Whether to generate source maps
  sourcemap : Bool
}

///|
/// Create default bundle configuration
pub fn BundleConfig::new(
  input : Array[(String, String)],
  output_dir : String,
) -> BundleConfig {
  {
    input,
    output_dir,
    format: Esm,
    entry_file_names: "[name].js",
    chunk_file_names: "_shared/[name]-[hash].js",
    minify: false,
    sourcemap: false,
  }
}

///|
/// Builder: set output format
pub fn BundleConfig::with_format(
  self : BundleConfig,
  format : OutputFormat,
) -> BundleConfig {
  { ..self, format }
}

///|
/// Builder: set minification
pub fn BundleConfig::with_minify(
  self : BundleConfig,
  minify : Bool,
) -> BundleConfig {
  { ..self, minify }
}

///|
/// Builder: set source map generation
pub fn BundleConfig::with_sourcemap(
  self : BundleConfig,
  sourcemap : Bool,
) -> BundleConfig {
  { ..self, sourcemap }
}

// ============================================================================
// Build API
// ============================================================================

///|
fn make_rolldown_options(config : BundleConfig) -> @js.Any {
  let opts = @js.new_object()

  // Build input object
  let input_obj = @js.new_object()
  for entry in config.input {
    let (name, path) = entry
    input_obj._set(name, @js.any(path))
  }
  opts._set("input", input_obj)

  // Build output object
  let output_obj = @js.new_object()
  output_obj._set("dir", @js.any(config.output_dir))
  output_obj._set("format", @js.any(config.format.to_string()))
  output_obj._set("entryFileNames", @js.any(config.entry_file_names))
  output_obj._set("chunkFileNames", @js.any(config.chunk_file_names))
  if config.sourcemap {
    output_obj._set("sourcemap", @js.any(true))
  }
  opts._set("output", output_obj)

  opts
}

///|
/// Build with rolldown (async)
pub async fn build(config : BundleConfig) -> RolldownOutput {
  let opts = make_rolldown_options(config)
  ffi_rolldown_build(opts).wait()
}

///|
/// Build islands from configuration
/// Takes a list of (island_name, entry_path) pairs and outputs to static directory
pub async fn bundle_islands(
  islands : Array[(String, String)],
  output_dir : String,
) -> RolldownOutput {
  let config = BundleConfig::new(islands, output_dir)
  build(config)
}

///|
/// Build islands with minification for production
pub async fn bundle_islands_prod(
  islands : Array[(String, String)],
  output_dir : String,
) -> RolldownOutput {
  let config = BundleConfig::new(islands, output_dir).with_minify(true)
  build(config)
}

// ============================================================================
// Result helpers
// ============================================================================

///|
/// Bundle result with success/failure info
pub struct BundleResult {
  success : Bool
  output : Array[String]
  errors : Array[String]
}

///|
/// Build islands and return simplified result
pub async fn bundle_islands_result(
  islands : Array[(String, String)],
  output_dir : String,
) -> BundleResult {
  try {
    let result = bundle_islands(islands, output_dir)
    let chunks = result.output()
    let files : Array[String] = []
    for chunk in chunks {
      files.push(chunk.file_name())
    }
    { success: true, output: files, errors: [] }
  } catch {
    e => { success: false, output: [], errors: [e.to_string()] }
  }
}

// ============================================================================
// Manifest-based build
// ============================================================================

///|
/// Island manifest entry
pub struct IslandManifestEntry {
  name : String
  entry_path : String
}

///|
/// Island manifest (written by generate, read by compiler)
pub struct IslandManifest {
  islands : Array[IslandManifestEntry]
  output_dir : String
}

///|
/// Parse island manifest from JSON string
pub fn parse_island_manifest(json_str : String) -> IslandManifest? {
  try {
    let json = @json.parse(json_str.view())
    guard json is Object(obj) else { return None }
    let output_dir = match obj.get("output_dir") {
      Some(String(s)) => s
      _ => "static"
    }
    let islands : Array[IslandManifestEntry] = []
    match obj.get("islands") {
      Some(Array(arr)) =>
        for item in arr {
          guard item is Object(island_obj) else { continue }
          let name = match island_obj.get("name") {
            Some(String(s)) => s
            _ => continue
          }
          let entry_path = match island_obj.get("entry_path") {
            Some(String(s)) => s
            _ => continue
          }
          islands.push({ name, entry_path })
        }
      _ => ()
    }
    Some({ islands, output_dir })
  } catch {
    _ => None
  }
}

///|
/// Generate island manifest JSON
pub fn generate_island_manifest(
  islands : Array[(String, String)],
  output_dir : String,
) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")
  buf.write_string("  \"output_dir\": \"")
  buf.write_string(output_dir)
  buf.write_string("\",\n")
  buf.write_string("  \"islands\": [\n")
  for i, entry in islands {
    let (name, entry_path) = entry
    buf.write_string("    { \"name\": \"")
    buf.write_string(name)
    buf.write_string("\", \"entry_path\": \"")
    buf.write_string(entry_path)
    buf.write_string("\" }")
    if i < islands.length() - 1 {
      buf.write_string(",")
    }
    buf.write_string("\n")
  }
  buf.write_string("  ]\n")
  buf.write_string("}\n")
  buf.to_string()
}

///|
/// Build islands from manifest
pub async fn build_from_manifest(manifest : IslandManifest) -> RolldownOutput {
  let entries : Array[(String, String)] = []
  for island in manifest.islands {
    entries.push((island.name, island.entry_path))
  }
  bundle_islands(entries, manifest.output_dir)
}

///|
/// Build islands from manifest file path (convenience for CLI)
/// Returns a promise that resolves when build is complete
/// cwd: working directory where rolldown should be resolved from
pub fn build_from_manifest_file(
  manifest_path : String,
  cwd : String,
  on_success : (Array[String]) -> Unit,
  on_error : (String) -> Unit,
) -> Unit {
  let _ = ffi_build_from_manifest(manifest_path, cwd, on_success, on_error)
}

///|
extern "js" fn ffi_build_from_manifest(
  manifest_path : String,
  cwd : String,
  on_success : (Array[String]) -> Unit,
  on_error : (String) -> Unit,
) -> @js.Promise[Unit] =
  #| async (manifestPath, cwd, onSuccess, onError) => {
  #|   try {
  #|     const fs = await import('node:fs');
  #|     const path = await import('node:path');
  #|     const { createRequire } = await import('node:module');
  #|     const manifestContent = fs.readFileSync(manifestPath, 'utf-8');
  #|     const manifest = JSON.parse(manifestContent);
  #|     // Resolve rolldown from the project's node_modules
  #|     const require = createRequire(path.join(cwd, 'package.json'));
  #|     const { build } = require('rolldown');
  #|     const input = {};
  #|     for (const island of manifest.islands) {
  #|       input[island.name] = island.entry_path;
  #|     }
  #|     // Change to cwd for relative path resolution
  #|     const originalCwd = process.cwd();
  #|     process.chdir(cwd);
  #|     try {
  #|       const result = await build({
  #|         input,
  #|         output: {
  #|           dir: manifest.output_dir,
  #|           format: 'esm',
  #|           entryFileNames: '[name].js',
  #|           chunkFileNames: '_shared/[name]-[hash].js',
  #|         },
  #|       });
  #|       const files = result.output.map(chunk => chunk.fileName);
  #|       onSuccess(files);
  #|     } finally {
  #|       process.chdir(originalCwd);
  #|     }
  #|   } catch (e) {
  #|     onError(e.message || String(e));
  #|   }
  #| }
