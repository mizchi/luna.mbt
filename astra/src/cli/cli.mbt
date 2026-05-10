// CLI command runners exposed for the `astra/cli/main` entry point.
//
// `run_build` parses `--out`, picks up an SSG config from disk
// (`astra.config.json` -> `sol.config.json` -> defaults), constructs
// the middleware in-process, and hands every URL to `build_to_disk`.
//
// `run_dev` (T11) binds the middleware to a real `node:http` listener
// via `Server::to_handler`; the bridge lives in `dev.mbt` next to its
// FFI shim.

///|
/// Discover an astra/sol config file in `cwd` and load it into an
/// `SsgConfig`. Returns `SsgConfig::default()` when no file is found
/// or parsing fails -- callers can treat the result as authoritative
/// without needing to handle a None branch.
///
/// File-absent and file-malformed are treated differently: an absent
/// file falls through quietly (the project simply hasn't opted into a
/// config), but a malformed file prints a `WARN` line to stderr-style
/// output before falling through. Without that distinction a typo in
/// `astra.config.json` would silently produce a default-config build,
/// which is the easiest kind of misconfiguration to miss.
pub fn load_config(cwd : String) -> @astra.SsgConfig {
  // Astra's own config takes precedence so projects can opt into
  // astra-specific fields without disturbing an existing sol setup.
  let astra_path = @path.join2(cwd, "astra.config.json")
  if @fs.existsSync(astra_path) {
    let content_opt : String? = Some(@fs.read_file_as_string(astra_path)) catch {
      _ => {
        println(
          "astra: WARN failed to read astra.config.json -- falling through to sol.config.json",
        )
        None
      }
    }
    if content_opt is Some(content) {
      match @astra.parse_ssg_config(content) {
        Some(cfg) => return cfg
        None =>
          println(
            "astra: WARN astra.config.json failed to parse -- falling through to sol.config.json",
          )
      }
    }
  }
  let sol_path = @path.join2(cwd, "sol.config.json")
  if @fs.existsSync(sol_path) {
    let content_opt : String? = Some(@fs.read_file_as_string(sol_path)) catch {
      _ => {
        println(
          "astra: WARN failed to read sol.config.json -- using default config",
        )
        None
      }
    }
    if content_opt is Some(content) {
      match @astra.parse_ssg_from_sol_config(content) {
        Some(cfg) => return cfg
        None =>
          println(
            "astra: WARN sol.config.json failed to parse -- using default config",
          )
      }
    }
  }
  @astra.SsgConfig::default()
}

///|
/// Tiny argv flag scanner for `--key value` / `--key=value`. Returns
/// `None` when the flag is absent. Boolean flags should be checked
/// with `has_flag` instead.
pub fn get_flag_value(args : Array[String], flag : String) -> String? {
  let prefix = flag + "="
  for i = 0; i < args.length(); i = i + 1 {
    let a = args[i]
    if a == flag && i + 1 < args.length() {
      return Some(args[i + 1])
    }
    if a.has_prefix(prefix) {
      return Some(a[prefix.length():].to_string())
    }
  }
  None
}

///|
pub fn has_flag(args : Array[String], flag : String) -> Bool {
  for a in args {
    if a == flag {
      return true
    }
  }
  false
}

///|
/// `astra build [--out <dir>]`.
///
/// `--out` overrides `SsgConfig.output_dir`. The default is read from
/// the loaded config (which itself defaults to `dist`). Any I/O errors
/// during the crawl propagate up and abort the build with a non-zero
/// exit through the caller.
///
/// A `--config <path>` flag is intentionally not advertised here: T10
/// only auto-discovers `astra.config.json` / `sol.config.json` in `cwd`,
/// and the unwired flag was previously mentioned in help text. T11 will
/// either wire it or document the lookup explicitly.
pub async fn run_build(args : Array[String], cwd : String) -> Unit {
  if has_flag(args, "--help") || has_flag(args, "-h") {
    println("Usage: astra build [--out <dir>] [--mode middleware|ssg]")
    println("  --mode middleware (default): crawl URLs through Mars handler")
    println("  --mode ssg: invoke render.generate_site_async (full SSG path)")
    return
  }
  let cfg_base = load_config(cwd)
  let output_dir = match get_flag_value(args, "--out") {
    Some(o) => o
    None => cfg_base.output_dir
  }
  let cfg = { ..cfg_base, output_dir, }
  // T11 parity test entry point: `--mode ssg` skips the middleware crawl
  // and runs the canonical `generate_site_async` pipeline (the same one
  // sol's old SSG build called). Used by `astra/docs/parity-notes.md` to
  // diff middleware-served output against the static-build pipeline.
  let mode = match get_flag_value(args, "--mode") {
    Some(m) => m
    None => "middleware"
  }
  if mode == "ssg" {
    println("astra build (mode=ssg): generate_site_async -> \{output_dir}")
    match @render.generate_site_async(cfg, cwd) {
      Ok(_) => println("astra build: done")
      Err(e) => {
        println("astra build: FAILED: \{e}")
        @process.exit(1)
      }
    }
    return
  }
  // Production build: minify CSS and run Shiki so the middleware-served
  // bytes match the canonical SSG output (`build_combined_css` ->
  // `minify_css`, plus syntax-highlighted code blocks).
  let highlighter = @shiki.create_default_highlighter()
  let mw = @middleware.create(
    cfg,
    cwd~,
    minify_css=true,
    highlighter=Some(highlighter),
  )
  let urls = mw.list_urls()
  println("astra build: \{urls.length()} URL(s) -> \{output_dir}")
  build_to_disk(mw, output_dir)
  let build_ctx : @astra.BuildContext = {
    config: cfg,
    pages: [],
    sidebar: [],
    cwd,
    doc_tree: None,
    is_dev: false,
  }
  @render.copy_static_assets(build_ctx)
  println("astra build: done")
}

///|
/// `astra dev [--port <n>]` -- start a real node:http listener mounted on
/// the in-process middleware. Implementation lives in `dev.mbt` so the FFI
/// bridge stays paired with its caller.
pub fn run_dev(args : Array[String], cwd : String) -> Unit {
  run_dev_listen(args, cwd)
}
