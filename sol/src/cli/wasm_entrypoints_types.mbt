// Wasm Entrypoints Types/Parser (mbtx + wasip2/wagi)

///|
/// Supported wasm runtime kinds
pub enum WasmEntrypointRuntime {
  Wagi
  WasiCli
  Component
} derive(Eq, Show, Debug)

///|
/// Source kinds accepted by wasm entrypoint builder.
pub enum WasmEntrypointSourceKind {
  MoonEntrypoint
  DirectWasm
  WacFile
} derive(Eq, Show, Debug)

///|
/// Build path used for final mounted wasm artifact.
pub enum WasmBuildKind {
  MoonBuild
  DirectCopy
  WiteCompose
} derive(Eq, Show, Debug)

///|
/// Build options for wasm entrypoint facade API.
pub struct WasmEntrypointBuildOptions {
  runtime_override : WasmEntrypointRuntime?
  emit_spin_fragment : Bool
  emit_env_json : Bool
  write_if_changed : Bool
}

///|
/// Output artifact paths from wasm entrypoint build.
pub struct WasmEntrypointBuildArtifacts {
  manifest_path : String
  env_path : String?
  spin_fragment_path : String?
  mars_hints_path : String?
}

///|
/// High-level build result for wasm entrypoint facade API.
pub struct WasmEntrypointBuildResult {
  mounts : Array[WasmMountEntry]
  artifacts : WasmEntrypointBuildArtifacts
}

///|
pub fn WasmEntrypointBuildOptions::default() -> WasmEntrypointBuildOptions {
  {
    runtime_override: None,
    emit_spin_fragment: false,
    emit_env_json: true,
    write_if_changed: true,
  }
}

///|
/// Compatibility helper for legacy `build_wasm_entrypoints` flags.
pub fn WasmEntrypointBuildOptions::for_cli(
  runtime_override? : WasmEntrypointRuntime? = None,
  emit_spin_fragment? : Bool = false,
) -> WasmEntrypointBuildOptions {
  {
    runtime_override,
    emit_spin_fragment,
    emit_env_json: true,
    write_if_changed: true,
  }
}

///|
/// Config entry for one .mbtx wasm entrypoint
pub struct WasmEntrypointConfig {
  id : String
  route : String
  source : String
  runtime : WasmEntrypointRuntime
  methods : Array[String]
  env : Map[String, String]
}

///|
/// Built wasm route mount entry
pub struct WasmMountEntry {
  id : String
  route : String
  methods : Array[String]
  runtime : WasmEntrypointRuntime
  wasm : String
  build : WasmBuildKind
  env : Map[String, String]
}

///|
pub fn WasmMountEntry::new(
  id : String,
  route : String,
  methods : Array[String],
  runtime : WasmEntrypointRuntime,
  wasm : String,
  build? : WasmBuildKind = MoonBuild,
  env? : Map[String, String] = {},
) -> WasmMountEntry {
  { id, route, methods, runtime, wasm, build, env }
}

///|
/// Parse runtime string for config/CLI.
/// Unknown values default to Wagi for safe fallback.
pub fn parse_wasm_entrypoint_runtime(s : String) -> WasmEntrypointRuntime {
  match s.to_lower().trim_space() {
    "wagi" => Wagi
    "wasi-cli" | "wasi" | "wasip2" => WasiCli
    "component" | "wasm-component" => Component
    _ => Wagi
  }
}

///|
/// Parse runtime string strictly (returns None for unknown values).
pub fn parse_wasm_entrypoint_runtime_opt(s : String) -> WasmEntrypointRuntime? {
  match s.to_lower().trim_space() {
    "wagi" => Some(Wagi)
    "wasi-cli" | "wasi" | "wasip2" => Some(WasiCli)
    "component" | "wasm-component" => Some(Component)
    _ => None
  }
}

///|
pub fn wasm_entrypoint_runtime_to_string(
  runtime : WasmEntrypointRuntime,
) -> String {
  match runtime {
    Wagi => "wagi"
    WasiCli => "wasi-cli"
    Component => "component"
  }
}

///|
pub fn wasm_build_kind_to_string(kind : WasmBuildKind) -> String {
  match kind {
    MoonBuild => "moon-build"
    DirectCopy => "direct-copy"
    WiteCompose => "wite-compose"
  }
}

///|
/// Parse `wasmEntryPoints` from sol config object.
/// Supports both `method` and `methods` keys for HTTP methods.
pub fn parse_wasm_entrypoints(
  obj : Map[String, Json],
) -> Array[WasmEntrypointConfig] {
  let result : Array[WasmEntrypointConfig] = []
  let entries = extract_wasm_entrypoint_array(obj)
  for entry in entries {
    guard entry is Object(entry_obj) else { continue }
    let id = match @json_utils.extract_string_opt(entry_obj, "id") {
      Some(v) => v
      None => continue
    }
    let route = match @json_utils.extract_string_opt(entry_obj, "route") {
      Some(v) => v
      None => continue
    }
    let source = match @json_utils.extract_string_opt(entry_obj, "source") {
      Some(v) => v
      None => continue
    }
    if id.is_empty() || route.is_empty() || source.is_empty() {
      continue
    }
    let runtime = match @json_utils.extract_string_opt(entry_obj, "runtime") {
      Some(v) => parse_wasm_entrypoint_runtime(v)
      None => Wagi
    }
    let methods = parse_wasm_methods(entry_obj)
    let env = parse_env_map(entry_obj)
    result.push({ id, route, source, runtime, methods, env })
  }
  result
}

///|
fn extract_wasm_entrypoint_array(obj : Map[String, Json]) -> Array[Json] {
  match obj.get("wasmEntryPoints") {
    Some(Array(arr)) => arr
    _ =>
      match obj.get("wasm_entrypoints") {
        Some(Array(arr)) => arr
        _ => []
      }
  }
}

///|
fn parse_wasm_methods(entry_obj : Map[String, Json]) -> Array[String] {
  let from_method = parse_method_field(entry_obj.get("method"))
  if !from_method.is_empty() {
    return from_method
  }
  let from_methods = parse_method_field(entry_obj.get("methods"))
  if !from_methods.is_empty() {
    return from_methods
  }
  ["GET"]
}

///|
fn parse_method_field(value : Json?) -> Array[String] {
  let parsed : Array[String] = []
  match value {
    Some(String(s)) =>
      match normalize_http_method(s) {
        Some(v) => parsed.push(v)
        None => ()
      }
    Some(Array(arr)) =>
      for item in arr {
        match item {
          String(s) =>
            match normalize_http_method(s) {
              Some(v) => if !parsed.contains(v) { parsed.push(v) }
              None => ()
            }
          _ => ()
        }
      }
    _ => ()
  }
  parsed
}

///|
fn parse_env_map(entry_obj : Map[String, Json]) -> Map[String, String] {
  let env : Map[String, String] = {}
  match entry_obj.get("env") {
    Some(Object(env_obj)) =>
      for item in env_obj {
        if item.1 is String(v) {
          env[item.0] = v
        }
      }
    _ => ()
  }
  env
}

///|
fn normalize_http_method(raw : String) -> String? {
  let normalized = raw.trim_space().to_string().to_upper()
  if normalized == "GET" ||
    normalized == "POST" ||
    normalized == "PUT" ||
    normalized == "PATCH" ||
    normalized == "DELETE" ||
    normalized == "HEAD" ||
    normalized == "OPTIONS" {
    Some(normalized)
  } else {
    None
  }
}
