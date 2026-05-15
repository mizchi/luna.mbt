// sol generate command - Generate __gen__ and .sol directories from sol.config.json or sol.config.ts
//
// This module is the main entry point for the generate command.
// The implementation is split across multiple files for better maintainability:
//
// - generate_utils.mbt: Shared utilities, app mode detection
// - config_parser.mbt: Config types, parsing, loading
// - mbti_parser.mbt: MoonBit interface file parsing
// - island_collector.mbt: Island export and Props type collection
// - type_generator.mbt: Types.mbt generation for Props
// - hydrate_generator.mbt: Client hydration code generation
// - server_generator.mbt: Server MoonBit and JS code generation
// - client_generator.mbt: Client entry JS file generation

// =============================================================================
// Main Generate Command
// =============================================================================

///|
async fn run_generate_command(args : Array[String]) -> Unit {
  let fs = @fs_adapter.NodeFsAdapter::new()
  run_generate_command_with_fs(fs, args)
}

///|
async fn[FS : @env.FileSystem] run_generate_command_with_fs(
  fs : FS,
  args : Array[String],
) -> Unit {
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(
        key="config",
        short="c",
        multiple=false,
        default=None, // Auto-detect
      ),
      @util.String(key="mode", short="m", multiple=false, default=Some("prod")),
      @util.Boolean(key="help", short="h"),
    ],
    allow_positionals=false,
  )
  if result.values.contains("help") && result.values["help"].cast() {
    show_generate_help()
    return
  }
  let mode : String = if result.values.contains("mode") {
    result.values["mode"].cast()
  } else {
    "prod"
  }
  let cwd = @process.cwd()

  // Load config - supports both sol.config.ts and sol.config.json
  // If -c flag is provided, use that specific file
  // Otherwise, auto-detect (TS takes priority)
  let (config_opt, config_path) = if result.values.contains("config") {
    let explicit_path : String = result.values["config"].cast()
    let full_path = @path.join2(cwd, explicit_path)
    if explicit_path.has_suffix(".ts") {
      (load_ts_config(full_path), explicit_path)
    } else {
      let content : String = fs.read_file_sync(full_path) catch {
        e => {
          @cli_common.console_error(
            @colorette.red("Error reading config: \{e}"),
          )
          @process.exit(1)
          "" // unreachable
        }
      }
      (parse_sol_config(content), explicit_path)
    }
  } else {
    // Auto-detect
    load_config_with_fs(fs, cwd)
  }
  guard config_opt is Some(config) else {
    @cli_common.console_error(
      @colorette.red("Error: Config file not found or invalid format"),
    )
    @cli_common.console_error(
      @colorette.gray("  Looked for: sol.config.ts or sol.config.json"),
    )
    @process.exit(1)
  }
  println(@colorette.cyan("Generating app/__gen__ and .sol directories..."))
  println(@colorette.gray("  Config: \{config_path}"))
  let runtime_name = match config.runtime {
    RuntimeNode => "node"
    RuntimeCloudflare => "cloudflare"
    RuntimeDeno => "deno"
    RuntimeBun => "bun"
  }
  println(@colorette.gray("  Runtime: \{runtime_name}"))
  let adapter_name = match config.adapter {
    RuntimeNode => "node"
    RuntimeCloudflare => "cloudflare"
    RuntimeDeno => "deno"
    RuntimeBun => "bun"
  }
  if config.adapter != config.runtime {
    println(@colorette.gray("  Adapter: \{adapter_name}"))
  }
  if config.uses_external_client_bundle() {
    println(@colorette.gray("  Client bundle: external"))
  }
  let contract_manifest = match config.contract_manifest {
    Some(manifest_path) =>
      match load_contract_manifest_with_fs(fs, cwd, manifest_path) {
        Some(manifest) => {
          println(@colorette.gray("  Contract manifest: \{manifest_path}"))
          Some(manifest)
        }
        None => {
          @cli_common.console_error(
            @colorette.red(
              "Error: contract manifest not found or invalid: \{manifest_path}",
            ),
          )
          @process.exit(1)
          None
        }
      }
    None =>
      if config.contract_ts.is_empty() {
        None
      } else {
        match load_contract_ts_manifest_with_fs(fs, cwd, config.contract_ts) {
          Ok(manifest) => {
            println(
              @colorette.gray("  Contract manifest: TypeScript interfaces"),
            )
            Some(manifest)
          }
          Err(message) => {
            @cli_common.console_error(
              @colorette.red("Error: invalid contractTs config: \{message}"),
            )
            @process.exit(1)
            None
          }
        }
      }
  }
  let client_assets = match contract_manifest {
    Some(manifest) => manifest.client_assets
    None => []
  }

  // Detect app mode (MoonBit vs TypeScript server)
  let app_mode = detect_app_mode_with_fs(fs, cwd, config)
  let mode_name = match app_mode {
    MoonBitFull => "MoonBit (full)"
    MoonBitClientTsServer => "MoonBit client + TypeScript server (hybrid)"
    TypeScriptFull => "TypeScript (full)"
  }
  println(@colorette.gray("  App mode: \{mode_name}"))

  // Detect user-managed server mode
  let user_managed = app_mode == MoonBitFull &&
    should_use_user_managed_server(fs, cwd, config)
  if user_managed {
    println(@colorette.gray("  Server entry: user-managed (main.mbt)"))
  }

  // Create output directories first (needed for generated types)
  let output_dir = @path.join2(cwd, config.output) // app/__gen__
  let types_dir = @path.join2(output_dir, "types")
  // Step 1: Parse source files to extract Props structs (before moon info)
  let manifest_structs = match contract_manifest {
    Some(manifest) => manifest.to_struct_exports()
    None => []
  }
  let source_structs = if !manifest_structs.is_empty() {
    println(
      @colorette.gray(
        "  Found \{manifest_structs.length()} Props types from contract manifest",
      ),
    )
    manifest_structs
  } else if config.islands.is_empty() {
    []
  } else {
    let scan_label = if config.uses_external_client_bundle() {
      "  Parsing source files for external Props contract..."
    } else {
      "  Parsing source files for Props types..."
    }
    println(@colorette.gray(scan_label))
    let found = collect_island_structs_from_source(cwd, config)
    println(
      @colorette.gray("  Found \{found.length()} Props types from source"),
    )
    found
  }
  // Step 1.5: Load route/action contracts. An explicit manifest avoids source
  // scanning; otherwise MoonBit apps keep the historical routes.mbt scan.
  let route_info = match contract_manifest {
    Some(manifest) => manifest.to_route_info()
    None =>
      if app_mode == MoonBitFull {
        let routes_file_path = @path.join2(
          @path.join2(cwd, config.routes),
          "routes.mbt",
        )
        parse_routes_file(routes_file_path)
      } else {
        {
          _page_components: [],
          _api_handlers: [],
          route_paths: [],
          route_queries: [],
          action_ids: [],
          action_contracts: [],
          api_contracts: [],
          contract_shapes: [],
        }
      }
  }
  let has_routes = !route_info.route_paths.is_empty()
  let has_route_params = route_paths_have_params(route_info.route_paths)
  let has_actions = !route_info.action_ids.is_empty()
  if has_routes || has_actions {
    let route_count = route_info.route_paths.length()
    let action_count = route_info.action_ids.length()
    println(
      @colorette.gray(
        "  Found \{route_count} route paths, \{action_count} action IDs",
      ),
    )
  }
  // Step 2: Generate types package from source (so moon info can resolve imports)
  let should_generate_types = !source_structs.is_empty() ||
    has_routes ||
    has_actions
  if should_generate_types {
    fs.mkdir_sync(types_dir, true) catch {
      e => {
        @cli_common.console_error(
          @colorette.red("Error creating types directory: \{e}"),
        )
        @process.exit(1)
      }
    }
    let types_mbt_content = generate_types_mbt(
      source_structs,
      route_info~,
      static_dirs=config.static_dirs,
      external_client_bundle=config.uses_external_client_bundle(),
      client_assets~,
    )
    let types_pkg_content = generate_types_pkg(
      source_structs,
      has_actions~,
      external_client_bundle=config.uses_external_client_bundle(),
      has_route_params~,
      client_assets~,
      contract_shapes=route_info.contract_shapes,
    )
    let types_mbt_path = @path.join2(types_dir, "types.mbt")
    let types_pkg_path = @path.join2(types_dir, "moon.pkg")
    let types_test_content = generate_types_roundtrip_tests(
      source_structs,
      external_client_bundle=config.uses_external_client_bundle(),
    )
    let types_ts_content = generate_typescript_contract_decl(
      source_structs,
      route_info~,
      client_assets~,
    )
    let types_test_path = @path.join2(types_dir, "types_test.mbt")
    let types_ts_path = @path.join2(types_dir, "types.d.ts")
    try {
      fs.write_file_sync(types_mbt_path, types_mbt_content)
      fs.write_file_sync(types_pkg_path, types_pkg_content)
      if types_test_content.length() > 0 {
        fs.write_file_sync(types_test_path, types_test_content)
      }
      if types_ts_content.length() > 0 {
        fs.write_file_sync(types_ts_path, types_ts_content)
      }
      let generated_label = if config.uses_external_client_bundle() {
        "  Generated __gen__/types/ external Props contract"
      } else {
        "  Generated __gen__/types/ from source"
      }
      println(@colorette.gray(generated_label))
    } catch {
      e => {
        @cli_common.console_error(
          @colorette.red("Error writing types package: \{e}"),
        )
        @process.exit(1)
      }
    }
  } else if !config.uses_external_client_bundle() {
    fs.mkdir_sync(types_dir, true) catch {
      e => {
        @cli_common.console_error(
          @colorette.red("Error creating types directory: \{e}"),
        )
        @process.exit(1)
      }
    }
    // Create empty stub if no Props found
    let stub_types_mbt_path = @path.join2(types_dir, "types.mbt")
    let stub_types_pkg_path = @path.join2(types_dir, "moon.pkg")
    if !fs.exists_sync(stub_types_mbt_path) {
      try {
        fs.write_file_sync(stub_types_mbt_path, "///| No Props types found\n")
        fs.write_file_sync(
          stub_types_pkg_path, "supported_targets = \"js\"\n\nwarnings = \"-29\"\n",
        )
      } catch {
        e => {
          @cli_common.console_error(
            @colorette.red("Error writing stub types: \{e}"),
          )
          @process.exit(1)
        }
      }
    }
  } else {
    println(
      @colorette.gray(
        "  Skipping __gen__/types/ (external client bundle has no Props contract)",
      ),
    )
  }
  // Step 2.5: Pre-create server moon.pkg with warning options (before moon info)
  // This ensures warnings are suppressed during moon info
  // Skip for hybrid mode (TypeScript server) as there's no MoonBit routes package
  // Skip for user-managed mode (user owns server/main.mbt and moon.pkg)
  let server_dir = @path.join2(output_dir, "server")
  let routes_pkg = get_routes_package_path(cwd, config.routes)
  if app_mode == MoonBitFull && !user_managed {
    fs.mkdir_sync(server_dir, true) catch {
      e => {
        @cli_common.console_error(
          @colorette.red("Error creating server directory: \{e}"),
        )
        @process.exit(1)
      }
    }
    let server_pkg = generate_server_pkg(routes_pkg, runtime=config.runtime)
    let server_pkg_path = @path.join2(server_dir, "moon.pkg")
    fs.write_file_sync(server_pkg_path, server_pkg) catch {
      e => {
        @cli_common.console_error(
          @colorette.red("Error writing server/moon.pkg: \{e}"),
        )
        @process.exit(1)
      }
    }
    // Create stub main.mbt so is-main: true doesn't fail
    let stub_main_path = @path.join2(server_dir, "main.mbt")
    fs.write_file_sync(
      stub_main_path, "///| Stub - will be replaced\nfn main { () }\n",
    ) catch {
      e => {
        @cli_common.console_error(
          @colorette.red("Error writing stub main.mbt: \{e}"),
        )
        @process.exit(1)
      }
    }
  }
  // Step 3: Collect island exports
  // If client_auto_exports is true, run moon info and parse mbti
  // If client_auto_exports is false, read exports from moon.pkg or moon.pkg.json (faster)
  let funcs : Array[FuncExport] = if config.uses_external_client_bundle() {
    println(
      @colorette.gray(
        "  Skipping client export collection (external client bundle)",
      ),
    )
    []
  } else if config.client_auto_exports {
    println(@colorette.gray("  Running moon info..."))
    try {
      let info_result = @child_process.spawnSync(
        "moon",
        args=["info", "--target", "js"],
        stdio="inherit",
      )
      if info_result.status() != Some(0) {
        @cli_common.console_error(@colorette.red("moon info failed"))
        @process.exit(1)
      }
    } catch {
      e => {
        @cli_common.console_error(
          @colorette.red("Error running moon info: \{e}"),
        )
        @process.exit(1)
      }
    }
    // Collect all pub functions from island directories (using mbti)
    collect_island_functions(cwd, config)
  } else {
    // User-managed exports mode: read from moon.pkg or moon.pkg.json directly
    println(
      @colorette.gray("  Reading exports from moon.pkg (user-managed)..."),
    )
    let result : Array[FuncExport] = []
    for island_pattern in config.islands {
      let island_dir = @path.join2(cwd, island_pattern)
      let exports = read_exports_from_pkg(island_dir)
      for export_name in exports {
        // Skip __sol_internal__client_* exports (they are generated, not source functions)
        if !export_name.has_prefix("__sol_internal__client_") {
          result.push(func_export_from_name(export_name, island_pattern))
        }
      }
    }
    result
  }
  println(@colorette.gray("  Found \{funcs.length()} island exports"))
  // Create remaining output directories (types_dir and server_dir already created above)
  // Use mode-specific .sol directory: .sol/dev or .sol/prod
  let sol_dir = @path.join2(@path.join2(cwd, ".sol"), mode)
  let sol_client_dir = @path.join2(sol_dir, "client")
  let sol_server_dir = @path.join2(sol_dir, "server")
  try {
    if !config.uses_external_client_bundle() {
      fs.mkdir_sync(sol_client_dir, true)
    }
    fs.mkdir_sync(sol_server_dir, true)
  } catch {
    e => {
      @cli_common.console_error(
        @colorette.red("Error creating directories: \{e}"),
      )
      @process.exit(1)
    }
  }
  // Get module name and source from moon.mod.json (needed for both __gen__/client and JS entries)
  let mod_json_path = @path.join2(cwd, "moon.mod.json")
  let (mod_name, source_dir) = read_mod_info(mod_json_path)
  // Generate hydrate functions in __gen__/client/ directory
  // This separates generated code from user's client code
  if !funcs.is_empty() {
    // Create __gen__/client directory
    let client_gen_dir = @path.join2(output_dir, "client")
    fs.mkdir_sync(client_gen_dir, true) catch {
      _ => ()
    }
    // Group functions by source_pattern (for now assume single client pattern)
    let patterns_seen : Map[String, Bool] = {}
    for f in funcs {
      patterns_seen[f.source_pattern] = true
    }
    // For each island pattern, determine client package path
    for island_pattern in patterns_seen.keys() {
      let island_funcs = funcs.filter(fn(f) {
        f.source_pattern == island_pattern
      })
      if island_funcs.is_empty() {
        continue
      }
      // Construct client package path
      // If source is set (e.g., "app"), remove it from island_pattern
      // island_pattern: "app/client" -> relative_path: "client" (when source="app")
      let relative_path = if source_dir.length() > 0 &&
        island_pattern.has_prefix(source_dir) {
        let prefix_len = source_dir.length()
        // Remove source_dir prefix and leading slash
        if island_pattern.length() > prefix_len + 1 {
          island_pattern.substring(start=prefix_len + 1)
        } else {
          island_pattern
        }
      } else {
        island_pattern
      }
      let client_pkg_path = if mod_name.length() > 0 {
        "\{mod_name}/\{relative_path}"
      } else {
        relative_path
      }
      let client_alias_name = "app_client"
      // Collect export names for __sol_internal__client_* functions only
      let export_names : Array[String] = []
      for f in island_funcs {
        if f.contract.can_hydrate() {
          export_names.push("__sol_internal__client_\{f.name}")
        }
      }
      // Generate __gen__.mbt with client alias references
      let hydrate_content = generate_hydrate_mbt(
        island_funcs, client_alias_name,
      )
      let hydrate_path = @path.join2(client_gen_dir, "__gen__.mbt")
      try {
        fs.write_file_sync(hydrate_path, hydrate_content)
        println(@colorette.gray("  Generated __gen__/client/__gen__.mbt"))
      } catch {
        e => {
          @cli_common.console_error(
            @colorette.red("Error writing __gen__/client/__gen__.mbt: \{e}"),
          )
          @process.exit(1)
        }
      }
      // Generate moon.pkg for __gen__/client/
      let pkg_content = generate_client_gen_pkg(
        client_pkg_path, client_alias_name, export_names,
      )
      let pkg_path = @path.join2(client_gen_dir, "moon.pkg")
      try {
        fs.write_file_sync(pkg_path, pkg_content)
        println(@colorette.gray("  Generated __gen__/client/moon.pkg"))
      } catch {
        e => {
          @cli_common.console_error(
            @colorette.red("Error writing __gen__/client/moon.pkg: \{e}"),
          )
          @process.exit(1)
        }
      }
    }
  }
  // Generate server code based on app mode
  match app_mode {
    MoonBitFull =>
      if user_managed {
        // User-managed mode: user owns server/main.mbt, skip __gen__/server/
        println(
          @colorette.gray("  Skipping __gen__/server/ (user-managed mode)"),
        )
      } else {
        // Use route_info already parsed at Step 1.5
        // Scan for .mbtx files if experimental_mbtx is enabled
        let mbtx_entries : Array[MbtxFileEntry] = if config.has_experimental(
            "experimental_mbtx",
          ) {
          scan_mbtx_dir(fs, "app/mbtx", cwd)
        } else {
          []
        }
        // Generate server main.mbt
        let server_main = generate_server_main_mbt(
          routes_pkg,
          route_info,
          config.static_dirs,
          mbtx_entries~,
          runtime=config.runtime,
        )
        let server_main_path = @path.join2(server_dir, "main.mbt")
        try {
          fs.write_file_sync(server_main_path, server_main)
          println(@colorette.gray("  Generated __gen__/server/main.mbt"))
        } catch {
          e => {
            @cli_common.console_error(
              @colorette.red("Error writing server/main.mbt: \{e}"),
            )
            @process.exit(1)
          }
        }
      }
    MoonBitClientTsServer =>
      // For hybrid mode, skip MoonBit server generation entirely
      // The TypeScript routes.ts will be used directly
      println(@colorette.gray("  Skipping __gen__/server/ (hybrid mode)"))
    TypeScriptFull =>
      // Full TypeScript mode - not yet implemented
      println(
        @colorette.gray("  Skipping __gen__/server/ (full TypeScript mode)"),
      )
  }
  // Note: server/moon.pkg already generated before moon info for MoonBitFull mode
  // Generate client JS entry files in .sol/client/
  if !funcs.is_empty() {
    for func in funcs {
      let include_hydrate = func.contract.can_hydrate()
      // Calculate relative_path by removing source_dir prefix from source_pattern
      let relative_path = if source_dir.length() > 0 &&
        func.source_pattern.has_prefix(source_dir) {
        let prefix_len = source_dir.length()
        if func.source_pattern.length() > prefix_len + 1 {
          func.source_pattern.substring(start=prefix_len + 1)
        } else {
          func.source_pattern
        }
      } else {
        func.source_pattern
      }
      let island_entry_content = generate_island_entry_js_v2(
        func, include_hydrate, relative_path, mode,
      )
      let island_entry_path = @path.join2(sol_client_dir, "\{func.name}.js")
      fs.write_file_sync(island_entry_path, island_entry_content) catch {
        e => {
          @cli_common.console_error(
            @colorette.red("Error writing client entry \{func.name}.js: \{e}"),
          )
          @process.exit(1)
        }
      }
    }
    println(
      @colorette.gray(
        "  Generated \{funcs.length()} client entries in .sol/\{mode}/client/",
      ),
    )
    // Generate island manifest JSON for programmatic rolldown build
    let manifest_content = generate_island_manifest_json(funcs, mode)
    let manifest_path = @path.join2(sol_dir, "manifest.json")
    try {
      fs.write_file_sync(manifest_path, manifest_content)
      println(@colorette.gray("  Generated .sol/\{mode}/manifest.json"))
    } catch {
      e => {
        @cli_common.console_error(
          @colorette.red("Error writing manifest.json: \{e}"),
        )
        @process.exit(1)
      }
    }
  }
  // Generate .sol/{mode}/server/main.js (server entry point)
  let server_main_js = match app_mode {
    MoonBitFull =>
      if user_managed {
        generate_sol_server_main_js_user_managed(
          config.runtime,
          mode,
          config.routes,
        )
      } else {
        generate_sol_server_main_js(routes_pkg, config.runtime, mode)
      }
    MoonBitClientTsServer =>
      generate_sol_server_main_js_hybrid(config.routes, config.runtime)
    TypeScriptFull =>
      generate_sol_server_main_js_hybrid(config.routes, config.runtime)
  }
  let server_main_js_path = @path.join2(sol_server_dir, "main.js")
  try {
    fs.write_file_sync(server_main_js_path, server_main_js)
    let mode_label = match app_mode {
      MoonBitFull => "MoonBit"
      MoonBitClientTsServer => "hybrid"
      TypeScriptFull => "TypeScript"
    }
    println(
      @colorette.gray("  Generated .sol/\{mode}/server/main.js (\{mode_label})"),
    )
  } catch {
    e => {
      @cli_common.console_error(
        @colorette.red("Error writing .sol/\{mode}/server/main.js: \{e}"),
      )
      @process.exit(1)
    }
  }
  // Generate .sol/{mode}/server/serve.js (adapter wrapper) if adapter != runtime
  if config.adapter != config.runtime {
    let serve_js = generate_sol_serve_js(config.adapter)
    let serve_js_path = @path.join2(sol_server_dir, "serve.js")
    try {
      fs.write_file_sync(serve_js_path, serve_js)
      let adapter_label = match config.adapter {
        RuntimeNode => "node"
        RuntimeCloudflare => "cloudflare"
        RuntimeDeno => "deno"
        RuntimeBun => "bun"
      }
      println(
        @colorette.gray(
          "  Generated .sol/\{mode}/server/serve.js (adapter: \{adapter_label})",
        ),
      )
    } catch {
      e => {
        @cli_common.console_error(
          @colorette.red("Error writing .sol/\{mode}/server/serve.js: \{e}"),
        )
        @process.exit(1)
      }
    }
  }
  // Write built-in assets to .sol/prod/__sol__/ for production serving
  if mode == "prod" {
    let sol_asset_dir = @path.join2(cwd, ".sol/prod/__sol__")
    fs.mkdir_sync(sol_asset_dir, true) catch {
      _ => ()
    }
    let mut asset_count = 0
    for file in sol_asset_files {
      match resolve_runtime_asset(cwd, file) {
        Some(content) => {
          let target = @path.join2(sol_asset_dir, file)
          fs.write_file_sync(target, content) catch {
            e => {
              @cli_common.console_error(
                @colorette.red("Error writing __sol__/\{file}: \{e}"),
              )
              continue
            }
          }
          asset_count += 1
        }
        None => ()
      }
    }
    if asset_count > 0 {
      println(
        @colorette.gray(
          "  Written \{asset_count} built-in assets to .sol/prod/__sol__/",
        ),
      )
    }
  }
  println(@colorette.green("✓ Generation complete"))
}
