// CLI command runners exposed for the `astra/cli/main` entry point.
//
// `run_build` parses `--out`, picks up an SSG config from disk
// (`astra.config.json` -> `sol.config.json` -> defaults), constructs
// the middleware in-process, and hands every URL to `build_to_disk`.
//
// `run_dev` is intentionally minimum-viable in T10: it loads the same
// config and instantiates the middleware, but cannot yet bind to a
// real HTTP listener (mars's JS adapter exposes `to_handler`, not a
// node:http listen helper). T11 wires that final hop. Until then the
// command prints the resolved config / port and exits non-zero so a
// caller never thinks the dev server is actually serving.

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
    let content_opt : String? = try {
      Some(@fs.read_file_as_string(astra_path))
    } catch {
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
    let content_opt : String? = try {
      Some(@fs.read_file_as_string(sol_path))
    } catch {
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
    println("Usage: astra build [--out <dir>]")
    return
  }
  let cfg_base = load_config(cwd)
  let output_dir = match get_flag_value(args, "--out") {
    Some(o) => o
    None => cfg_base.output_dir
  }
  let cfg = { ..cfg_base, output_dir }
  let mw = @middleware.create(cfg, cwd~)
  let urls = mw.list_urls()
  println("astra build: \{urls.length()} URL(s) -> \{output_dir}")
  build_to_disk(mw, output_dir)
  println("astra build: done")
}

///|
/// `astra dev [--port <n>]` -- minimum-viable in T10. Logs the
/// resolved config and prints a plan-tracked stub message; T11 will
/// turn this into a real `node:http` listener wired to
/// `mw.handler()` via `Server::to_handler`.
pub fn run_dev(args : Array[String], cwd : String) -> Unit {
  if has_flag(args, "--help") || has_flag(args, "-h") {
    println("Usage: astra dev [--port <n>]")
    return
  }
  let port = match get_flag_value(args, "--port") {
    Some(p) => p
    None => "7777"
  }
  let cfg = load_config(cwd)
  let mw = @middleware.create(cfg, cwd~)
  let urls = mw.list_urls()
  println(
    "astra dev (stub): would listen on :\{port} with \{urls.length()} routes",
  )
  println(
    "astra dev: real listener arrives in T11 (node:http + Server::to_handler)",
  )
}
