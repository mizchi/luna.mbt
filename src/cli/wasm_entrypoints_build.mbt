// Wasm Entrypoints Builder

///|
/// Build all configured wasm entrypoints and emit mount artifacts to `.sol/wasm`.
pub fn build_wasm_entrypoints(
  cwd : String,
  entries : Array[WasmEntrypointConfig],
  runtime_override? : WasmEntrypointRuntime? = None,
  emit_spin_fragment? : Bool = false,
) -> Result[Array[WasmMountEntry], String] {
  let options = WasmEntrypointBuildOptions::for_cli(
    runtime_override~,
    emit_spin_fragment~,
  )
  match build_wasm_entrypoints_with_options(cwd, entries, options~) {
    Ok(result) => Ok(result.mounts)
    Err(e) => Err(e)
  }
}

///|
/// Build wasm entrypoints with facade options and return artifact metadata.
pub fn build_wasm_entrypoints_with_options(
  cwd : String,
  entries : Array[WasmEntrypointConfig],
  options? : WasmEntrypointBuildOptions = WasmEntrypointBuildOptions::default(),
) -> Result[WasmEntrypointBuildResult, String] {
  let fs = @fs_adapter.NodeFsAdapter::new()
  let wasm_root = @path.join2(cwd, ".sol/wasm")
  let entries_root = @path.join2(wasm_root, "entries")
  fs.mkdir_sync(entries_root, true) catch {
    e => return Err("failed to create wasm output directory: \{e}")
  }
  let mounts : Array[WasmMountEntry] = []
  for entry in entries {
    println(@colorette.gray("  wasm entrypoint: \{entry.id} -> \{entry.route}"))
    let runtime = match options.runtime_override {
      Some(rt) => rt
      None => entry.runtime
    }
    let rel_wasm = ".sol/wasm/entries/\{entry.id}/module.wasm"
    let abs_wasm = @path.join2(cwd, rel_wasm)
    let source_kind = detect_wasm_entry_source_kind(entry.source)
    let build = match source_kind {
      MoonEntrypoint => {
        let build_result = @child_process.spawnSync(
          "moon",
          args=[
            "run",
            entry.source,
            "--target",
            "wasm-gc",
            "--release",
            "--build-only",
          ],
          stdio="inherit",
          cwd~,
        ) catch {
          e => return Err("failed to invoke moon for \{entry.source}: \{e}")
        }
        if build_result.status() != Some(0) {
          return Err("moon build failed for wasm entrypoint: \{entry.source}")
        }
        let artifact = ffi_find_wasm_artifact(cwd, entry.source)
        if artifact.is_empty() {
          return Err("wasm artifact not found for source: \{entry.source}")
        }
        if not(ffi_copy_file_sync(artifact, abs_wasm)) {
          return Err("failed to copy wasm artifact: \{artifact}")
        }
        MoonBuild
      }
      DirectWasm => {
        let artifact = resolve_entry_source_path(cwd, entry.source)
        if not(ffi_copy_file_sync(artifact, abs_wasm)) {
          return Err("failed to copy wasm artifact: \{artifact}")
        }
        DirectCopy
      }
      WacFile => {
        let input_wac = resolve_entry_source_path(cwd, entry.source)
        let composed = match @wite_bundle.compose_wac_file(input_wac) {
          Ok(bytes) => bytes
          Err(msg) =>
            return Err("wite compose failed for \{entry.source}: \{msg}")
        }
        if not(ffi_write_bytes_sync(abs_wasm, composed)) {
          return Err(
            "failed to write wite-composed wasm artifact for \{entry.source}",
          )
        }
        WiteCompose
      }
    }
    let env = resolve_wasm_entry_env(entry, runtime)
    let mount : WasmMountEntry = {
      id: entry.id,
      route: entry.route,
      methods: entry.methods,
      runtime,
      wasm: rel_wasm,
      build,
      env,
    }
    mounts.push(mount)
    let metadata_path = @path.join2(
      cwd,
      ".sol/wasm/entries/\{entry.id}/metadata.json",
    )
    match
      write_text_file_with_policy(
        fs,
        metadata_path,
        generate_wasm_entry_metadata_json(entry.source, mount),
        options.write_if_changed,
      ) {
      Ok(_) => ()
      Err(e) => return Err("failed to write metadata for \{entry.id}: \{e}")
    }
  }
  let manifest_rel = ".sol/wasm/manifest.json"
  let manifest_path = @path.join2(cwd, manifest_rel)
  match
    write_text_file_with_policy(
      fs,
      manifest_path,
      generate_wasm_manifest_json(mounts),
      options.write_if_changed,
    ) {
    Ok(_) => ()
    Err(e) => return Err("failed to write wasm manifest: \{e}")
  }
  let env_path = if options.emit_env_json {
    let env_rel = ".sol/wasm/env.json"
    let env_abs = @path.join2(cwd, env_rel)
    match
      write_text_file_with_policy(
        fs,
        env_abs,
        generate_wasm_env_json(mounts),
        options.write_if_changed,
      ) {
      Ok(_) => Some(env_rel)
      Err(e) => return Err("failed to write wasm env map: \{e}")
    }
  } else {
    None
  }
  let spin_fragment_path = if options.emit_spin_fragment {
    let spin_rel = ".sol/wasm/spin.toml.fragment"
    let spin_abs = @path.join2(cwd, spin_rel)
    match
      write_text_file_with_policy(
        fs,
        spin_abs,
        generate_spin_toml_fragment(mounts),
        options.write_if_changed,
      ) {
      Ok(_) => Some(spin_rel)
      Err(e) => return Err("failed to write spin fragment: \{e}")
    }
  } else {
    None
  }
  let mars_hints_path = {
    let hints_rel = ".sol/wasm/mars-adapter.hints"
    let hints_abs = @path.join2(cwd, hints_rel)
    match
      write_text_file_with_policy(
        fs,
        hints_abs,
        generate_mars_adapter_hints(mounts),
        options.write_if_changed,
      ) {
      Ok(_) => Some(hints_rel)
      Err(e) => return Err("failed to write mars adapter hints: \{e}")
    }
  }
  let artifacts : WasmEntrypointBuildArtifacts = {
    manifest_path: manifest_rel,
    env_path,
    spin_fragment_path,
    mars_hints_path,
  }
  Ok({ mounts, artifacts })
}

///|
fn[FS : @env.FileSystem] write_text_file_with_policy(
  fs : FS,
  path : String,
  content : String,
  write_if_changed : Bool,
) -> Result[Unit, String] {
  if write_if_changed && fs.exists_sync(path) {
    let existing = fs.read_file_sync(path) catch { _ => "" }
    if existing == content {
      return Ok(())
    }
  }
  fs.write_file_sync(path, content) catch {
    e => return Err("\{e}")
  }
  Ok(())
}

///|
fn detect_wasm_entry_source_kind(source : String) -> WasmEntrypointSourceKind {
  if source.has_suffix(".wac") {
    WacFile
  } else if source.has_suffix(".wasm") {
    DirectWasm
  } else {
    MoonEntrypoint
  }
}

///|
fn resolve_entry_source_path(cwd : String, source : String) -> String {
  if @path.isAbsolute(source) {
    source
  } else {
    @path.join2(cwd, source)
  }
}

///|
fn resolve_wasm_entry_env(
  entry : WasmEntrypointConfig,
  runtime : WasmEntrypointRuntime,
) -> Map[String, String] {
  let env : Map[String, String] = {}
  for item in entry.env {
    env[item.0] = item.1
  }
  if not(env.contains("SOL_ENTRYPOINT_ID")) {
    env["SOL_ENTRYPOINT_ID"] = entry.id
  }
  if not(env.contains("SOL_ROUTE")) {
    env["SOL_ROUTE"] = entry.route
  }
  if not(env.contains("SOL_METHODS")) {
    env["SOL_METHODS"] = entry.methods.join(",")
  }
  if not(env.contains("SOL_RUNTIME")) {
    env["SOL_RUNTIME"] = wasm_entrypoint_runtime_to_string(runtime)
  }
  if runtime == Wagi {
    if not(env.contains("SERVER_PROTOCOL")) {
      env["SERVER_PROTOCOL"] = "HTTP/1.1"
    }
    if not(env.contains("GATEWAY_INTERFACE")) {
      env["GATEWAY_INTERFACE"] = "CGI/1.1"
    }
  }
  env
}

///|
/// Find built wasm artifact path for a source entrypoint.
extern "js" fn ffi_find_wasm_artifact(cwd : String, source : String) -> String =
  #| (cwd, source) => {
  #|   try {
  #|     const fs = require('node:fs');
  #|     const path = require('node:path');
  #|     const cacheKey = '__SOL_WASM_ARTIFACT_SCAN_CACHE__';
  #|     if (!globalThis[cacheKey]) {
  #|       globalThis[cacheKey] = new Map();
  #|     }
  #|     const scanCache = globalThis[cacheKey];
  #|     const resolve = (p) => path.isAbsolute(p) ? p : path.join(cwd, p);
  #|     if (source.endsWith('.wasm')) {
  #|       const direct = resolve(source);
  #|       if (fs.existsSync(direct)) return direct;
  #|     }
  #|     const root = path.join(cwd, '_build', 'wasm-gc', 'release', 'build');
  #|     if (!fs.existsSync(root)) return '';
  #|     const stem = path.basename(source).replace(/\.[^.]+$/, '');
  #|     const scanMatches = () => {
  #|       const matches = [];
  #|       const walk = (dir) => {
  #|         let entries = [];
  #|         try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch (_) { return; }
  #|         for (const entry of entries) {
  #|           const abs = path.join(dir, entry.name);
  #|           if (entry.isDirectory()) {
  #|             walk(abs);
  #|           } else if (entry.isFile() && entry.name.endsWith('.wasm')) {
  #|             matches.push(abs);
  #|           }
  #|         }
  #|       };
  #|       walk(root);
  #|       return matches;
  #|     };
  #|     const pickCandidate = (matches) => {
  #|       if (!matches || matches.length === 0) return '';
  #|       const exact = matches.filter((p) => path.basename(p, '.wasm') === stem);
  #|       const fuzzy = matches.filter((p) => p.includes(stem));
  #|       const pool = exact.length > 0 ? exact : (fuzzy.length > 0 ? fuzzy : matches);
  #|       pool.sort((a, b) => {
  #|         try {
  #|           return fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs;
  #|         } catch (_) {
  #|           return 0;
  #|         }
  #|       });
  #|       return pool[0] || '';
  #|     };
  #|     let matches = scanCache.get(root);
  #|     if (!matches) {
  #|       matches = scanMatches();
  #|       scanCache.set(root, matches);
  #|     }
  #|     let selected = pickCandidate(matches);
  #|     if (selected) return selected;
  #|     matches = scanMatches();
  #|     scanCache.set(root, matches);
  #|     selected = pickCandidate(matches);
  #|     return selected || '';
  #|   } catch (_) {
  #|     return '';
  #|   }
  #| }

///|
extern "js" fn ffi_copy_file_sync(src : String, dest : String) -> Bool =
  #| (src, dest) => {
  #|   try {
  #|     const fs = require('node:fs');
  #|     const path = require('node:path');
  #|     fs.mkdirSync(path.dirname(dest), { recursive: true });
  #|     fs.copyFileSync(src, dest);
  #|     return true;
  #|   } catch (_) {
  #|     return false;
  #|   }
  #| }

///|
extern "js" fn ffi_write_bytes_sync(dest : String, bytes : Bytes) -> Bool =
  #| (dest, bytes) => {
  #|   try {
  #|     const fs = require('node:fs');
  #|     const path = require('node:path');
  #|     fs.mkdirSync(path.dirname(dest), { recursive: true });
  #|     fs.writeFileSync(dest, Buffer.from(bytes));
  #|     return true;
  #|   } catch (_) {
  #|     return false;
  #|   }
  #| }
