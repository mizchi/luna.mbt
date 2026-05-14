// sol doctor command - Diagnose project configuration and adapter wiring.

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
priv struct DoctorReport {
  cwd : String
  runtime : String
  config_path : String
  findings : Array[DoctorFinding]
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

  DoctorReport::{ cwd, runtime, config_path, findings }
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
  let report = diagnose_project_with_fs(fs, @process.cwd())
  println(report.render())
  if report.has_errors() || (strict && report.has_warnings()) {
    @process.exit(1)
  }
}
