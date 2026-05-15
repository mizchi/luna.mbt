// sol doctor command - Diagnose project configuration and adapter wiring.

///|
/// Version of the JS-side sol CLI bundled with this build. Used to compare
/// against the version of `mizchi/sol` actually resolved into the project's
/// `.mooncakes/` (and the native launcher, when reachable on PATH).
///
/// Keep this in sync with `sol/moon.mod.json` `version` and the literal in
/// `sol/src/cmd/sol/main.mbt`.
const SOL_JS_CLI_VERSION : String = "0.22.3"

///|
priv enum DoctorSeverity {
  DoctorInfo
  DoctorWarning
  DoctorError
} derive(Eq)

///|
priv struct DoctorFinding {
  severity : DoctorSeverity
  title : String
  detail : String
  hint : String
}

///|
/// A single resolved mooncake entry under `.mooncakes/<owner>/<pkg>/`.
///
/// `version` is `None` when either the package directory or its
/// `moon.mod.json` could not be read / parsed.
priv struct MooncakeEntry {
  name : String
  version : String?
}

///|
priv struct DoctorReport {
  cwd : String
  runtime : String
  config_path : String
  findings : Array[DoctorFinding]
  js_cli_version : String
  launcher_version : String?
  mooncakes : Array[MooncakeEntry]
}

///|
fn doctor_info(
  title : String,
  detail : String,
  hint? : String = "",
) -> DoctorFinding {
  { severity: DoctorInfo, title, detail, hint }
}

///|
fn doctor_warning(
  title : String,
  detail : String,
  hint : String,
) -> DoctorFinding {
  { severity: DoctorWarning, title, detail, hint }
}

///|
fn doctor_error(
  title : String,
  detail : String,
  hint : String,
) -> DoctorFinding {
  { severity: DoctorError, title, detail, hint }
}

///|
fn DoctorSeverity::label(self : DoctorSeverity) -> String {
  match self {
    DoctorInfo => "info"
    DoctorWarning => "warning"
    DoctorError => "error"
  }
}

///|
fn DoctorReport::count(self : DoctorReport, severity : DoctorSeverity) -> Int {
  let mut total = 0
  for finding in self.findings {
    if finding.severity == severity {
      total += 1
    }
  }
  total
}

///|
fn DoctorReport::has_errors(self : DoctorReport) -> Bool {
  self.count(DoctorError) > 0
}

///|
fn DoctorReport::has_warnings(self : DoctorReport) -> Bool {
  self.count(DoctorWarning) > 0
}

///|
fn DoctorReport::summary(self : DoctorReport) -> String {
  "\{self.count(DoctorError)} error, \{self.count(DoctorWarning)} warning"
}

///|
fn DoctorReport::render(self : DoctorReport) -> String {
  let buf = StringBuilder::new()
  buf.write_string("Sol doctor\n")
  buf.write_string("cwd: \{self.cwd}\n")
  buf.write_string("runtime: \{self.runtime}\n")
  if self.config_path != "" {
    buf.write_string("config: \{self.config_path}\n")
  }
  buf.write_string("\n")
  buf.write_string("Versions:\n")
  buf.write_string("  sol JS CLI (bundled): \{self.js_cli_version}\n")
  match self.launcher_version {
    Some(v) => buf.write_string("  sol native launcher:  \{v}\n")
    None => buf.write_string("  sol native launcher:  (not detected)\n")
  }
  buf.write_string("\n")
  buf.write_string("Mooncake versions:\n")
  let mut printed = 0
  for entry in self.mooncakes {
    match entry.version {
      Some(v) => {
        buf.write_string("  \{entry.name} @ \{v}\n")
        printed += 1
      }
      None => ()
    }
  }
  if printed == 0 {
    buf.write_string("  (no resolved mooncakes — run `moon install`)\n")
  }
  buf.write_string("\n")
  if self.findings.is_empty() {
    buf.write_string("[ok] No issues found\n")
  } else {
    for finding in self.findings {
      buf.write_string("[\{finding.severity.label()}] \{finding.title}\n")
      buf.write_string("  \{finding.detail}\n")
      if finding.hint != "" {
        buf.write_string("  fix: \{finding.hint}\n")
      }
    }
  }
  buf.write_string("\n")
  buf.write_string("Summary: \{self.summary()}\n")
  buf.to_string()
}

///|
fn runtime_label(runtime : ServerRuntime) -> String {
  match runtime {
    RuntimeNode => "node"
    RuntimeCloudflare => "cloudflare"
    RuntimeDeno => "deno"
    RuntimeBun => "bun"
  }
}

///|
fn moon_mod_has_dep(content : String, dep : String) -> Bool {
  try {
    let parsed = @json.parse(content.view())
    guard parsed is Object(obj) else { return false }
    match obj.get("deps") {
      Some(Object(deps)) => deps.get(dep) is Some(_)
      _ => false
    }
  } catch {
    _ => false
  }
}

///|
/// Extract the top-level `version` field from a moon.mod.json string.
fn moon_mod_version(content : String) -> String? {
  try {
    let parsed = @json.parse(content.view())
    guard parsed is Object(obj) else { return None }
    match obj.get("version") {
      Some(String(v)) => Some(v)
      _ => None
    }
  } catch {
    _ => None
  }
}

///|
/// Read the version of a mooncake under `.mooncakes/<owner>/<pkg>/`.
///
/// Returns `None` if the package or its `moon.mod.json` is missing /
/// unparseable. The package directory missing is a normal case for
/// optional deps (e.g. sol_adapter_cloudflare on a Node project).
fn[FS : @env.FileSystem] read_mooncake_version(
  fs : FS,
  cwd : String,
  qualified : String,
) -> String? {
  let mod_path = @path.join2(
    @path.join2(cwd, ".mooncakes"),
    qualified + "/moon.mod.json",
  )
  if !fs.exists_sync(mod_path) {
    return None
  }
  let content = fs.read_file_sync(mod_path) catch { _ => "" }
  if content == "" {
    return None
  }
  moon_mod_version(content)
}

///|
/// Collect the resolved versions of sol-stack mooncakes in user's project.
fn[FS : @env.FileSystem] collect_mooncake_versions(
  fs : FS,
  cwd : String,
) -> Array[MooncakeEntry] {
  let names = [
    "mizchi/sol", "mizchi/luna", "mizchi/astra", "mizchi/sol_adapter_cloudflare",
    "mizchi/sol_adapter_node",
  ]
  let out : Array[MooncakeEntry] = []
  for name in names {
    out.push({ name, version: read_mooncake_version(fs, cwd, name) })
  }
  out
}

///|
/// Best-effort detection of the native `sol` launcher version by running
/// `sol --version`. Returns `None` if the binary is not on PATH or the
/// output is unexpected (e.g. recursion guard prints something else).
fn detect_launcher_version() -> String? {
  let out = try? @child_process.execSync(
    "sol --version",
    encoding="utf8",
    timeout=2000,
  )
  match out {
    Ok(raw) => {
      let trimmed = raw.trim_space().to_string()
      // Expect "sol 0.22.3" or just "0.22.3".
      if trimmed.has_prefix("sol ") {
        Some(trimmed.substring(start=4).trim_space().to_string())
      } else if trimmed == "" {
        None
      } else {
        Some(trimmed)
      }
    }
    Err(_) => None
  }
}

///|
/// Add a warning when the JS CLI version and the resolved
/// `.mooncakes/mizchi/sol/` version diverge — the typical symptom is "user
/// updated sol but a fix in the new version is not picked up".
fn add_version_skew_findings(
  findings : Array[DoctorFinding],
  js_cli_version : String,
  launcher_version : String?,
  mooncakes : Array[MooncakeEntry],
) -> Unit {
  let mut sol_version : String? = None
  for entry in mooncakes {
    if entry.name == "mizchi/sol" {
      sol_version = entry.version
    }
  }
  match sol_version {
    Some(v) =>
      if v != js_cli_version {
        findings.push(
          doctor_warning(
            "Sol JS CLI / .mooncakes version diverge",
            "Bundled sol JS CLI is \{js_cli_version}, but .mooncakes/mizchi/sol/moon.mod.json is \{v}.",
            "Run `moon update && moon install` to refresh `.mooncakes/`.",
          ),
        )
      }
    None => ()
  }
  match (launcher_version, sol_version) {
    (Some(l), Some(m)) =>
      if l != m {
        findings.push(
          doctor_warning(
            "Launcher and delegated JS CLI versions diverge",
            "Native `sol` launcher is \{l}, but .mooncakes/mizchi/sol/ is \{m}.",
            "Run `moon update && moon install` to refresh `.mooncakes/`, or reinstall the launcher via `moon install mizchi/sol/cmd/sol`.",
          ),
        )
      }
    _ => ()
  }
}

///|
fn add_adapter_findings(
  findings : Array[DoctorFinding],
  runtime : ServerRuntime,
  moon_mod_path : String,
  moon_mod_content : String,
) -> Unit {
  let has_node = moon_mod_has_dep(moon_mod_content, "mizchi/sol_adapter_node")
  let has_cloudflare = moon_mod_has_dep(
    moon_mod_content, "mizchi/sol_adapter_cloudflare",
  )
  match runtime {
    RuntimeNode =>
      if !has_node {
        findings.push(
          doctor_error(
            "Missing Node adapter dependency",
            "\{moon_mod_path} does not declare mizchi/sol_adapter_node for runtime=node.",
            "Add \"mizchi/sol_adapter_node\" to moon.mod.json deps.",
          ),
        )
      }
    RuntimeCloudflare => {
      if !has_cloudflare {
        findings.push(
          doctor_error(
            "Missing Cloudflare adapter dependency",
            "\{moon_mod_path} does not declare mizchi/sol_adapter_cloudflare for runtime=cloudflare.",
            "Add \"mizchi/sol_adapter_cloudflare\" to moon.mod.json deps.",
          ),
        )
      }
      if has_node {
        findings.push(
          doctor_error(
            "Cloudflare project depends on Node adapter",
            "\{moon_mod_path} still declares mizchi/sol_adapter_node, which can pull Node-specific runtime assumptions into a Worker project.",
            "Remove mizchi/sol_adapter_node and keep Cloudflare-specific code in sol_adapter_cloudflare.",
          ),
        )
      }
    }
    RuntimeDeno | RuntimeBun =>
      findings.push(
        doctor_info(
          "Runtime has no dedicated adapter package yet",
          "runtime=\{runtime_label(runtime)} currently uses Sol's generated entry fallback.",
        ),
      )
  }
}

///|
fn[FS : @env.FileSystem] add_generated_output_findings(
  fs : FS,
  findings : Array[DoctorFinding],
  cwd : String,
  output : String,
) -> Unit {
  let output_path = @path.join2(cwd, output)
  if !fs.exists_sync(output_path) {
    findings.push(
      doctor_warning(
        "Generated MoonBit output is missing",
        "\{output_path} was not found.",
        "Run `sol generate` before `moon build`.",
      ),
    )
  }
  let prod_server = @path.join2(cwd, ".sol/prod/server")
  let prod_main = @path.join2(prod_server, "main.js")
  let prod_serve = @path.join2(prod_server, "serve.js")
  if !(fs.exists_sync(prod_main) || fs.exists_sync(prod_serve)) {
    findings.push(
      doctor_warning(
        "Production server entry is missing",
        "\{prod_server}/main.js or serve.js was not found.",
        "Run `sol build` before `sol serve` or deploy.",
      ),
    )
  }
}

///|
fn[FS : @env.FileSystem] diagnose_project_with_fs(
  fs : FS,
  cwd : String,
  launcher_version? : String? = None,
) -> DoctorReport {
  let findings : Array[DoctorFinding] = []
  let json_config_path = @path.join2(cwd, "sol.config.json")
  let ts_config_path = @path.join2(cwd, "sol.config.ts")
  let moon_mod_path = @path.join2(cwd, "moon.mod.json")
  let mut config_path = ""
  let mut runtime = "unknown"
  let mut routes = "app/server"
  let mut output = "app/__gen__"
  let mut config_loaded = false

  if fs.exists_sync(json_config_path) {
    config_path = json_config_path
    let content = fs.read_file_sync(json_config_path) catch { _ => "" }
    match parse_sol_config(content) {
      Some(config) => {
        config_loaded = true
        runtime = runtime_label(config.runtime)
        routes = config.routes
        output = config.output
        let routes_dir = @path.join2(cwd, routes)
        let routes_file = @path.join2(routes_dir, "routes.mbt")
        if !fs.exists_sync(routes_file) {
          findings.push(
            doctor_error(
              "Routes file is missing",
              "\{routes_file} was not found.",
              "Create \{routes}/routes.mbt or update the routes field in sol.config.json.",
            ),
          )
        }
        if fs.exists_sync(moon_mod_path) {
          let moon_mod_content = fs.read_file_sync(moon_mod_path) catch {
            _ => ""
          }
          add_adapter_findings(
            findings,
            config.runtime,
            moon_mod_path,
            moon_mod_content,
          )
        } else {
          findings.push(
            doctor_error(
              "moon.mod.json is missing",
              "\{moon_mod_path} was not found.",
              "Create a MoonBit module or run `sol new`.",
            ),
          )
        }
      }
      None =>
        findings.push(
          doctor_error(
            "Sol config could not be parsed",
            "\{json_config_path} is not valid sol.config.json.",
            "Fix the JSON file or run `sol new` to regenerate a starter config.",
          ),
        )
    }
  } else if fs.exists_sync(ts_config_path) {
    config_path = ts_config_path
    findings.push(
      doctor_warning(
        "TypeScript config requires runtime loading",
        "Static doctor checks cannot inspect \{ts_config_path} without executing it.",
        "Run `sol generate` to validate sol.config.ts, or keep sol.config.json for static checks.",
      ),
    )
  } else {
    findings.push(
      doctor_error(
        "Sol config is missing",
        "No sol.config.json or sol.config.ts was found in \{cwd}.",
        "Run `sol new <name>` or add sol.config.json.",
      ),
    )
  }

  if config_loaded {
    add_generated_output_findings(fs, findings, cwd, output)
  }
  let mooncakes = collect_mooncake_versions(fs, cwd)
  add_version_skew_findings(
    findings,
    SOL_JS_CLI_VERSION,
    launcher_version,
    mooncakes,
  )
  DoctorReport::{
    cwd,
    runtime,
    config_path,
    findings,
    js_cli_version: SOL_JS_CLI_VERSION,
    launcher_version,
    mooncakes,
  }
}

///|
fn show_doctor_help() -> Unit {
  let help =
    #|Usage: sol doctor [options]
    #|
    #|Diagnose Sol project configuration and adapter wiring.
    #|
    #|Options:
    #|  --strict        Exit non-zero when warnings are present
    #|  -h, --help      Show help
  println(help)
}

///|
fn run_doctor_command(args : Array[String]) -> Unit {
  if args.contains("--help") || args.contains("-h") {
    show_doctor_help()
    return
  }
  let strict = args.contains("--strict")
  let fs = @fs_adapter.NodeFsAdapter::new()
  let launcher_version = detect_launcher_version()
  let report = diagnose_project_with_fs(fs, @process.cwd(), launcher_version~)
  println(report.render())
  if report.has_errors() || (strict && report.has_warnings()) {
    @process.exit(1)
  }
}
