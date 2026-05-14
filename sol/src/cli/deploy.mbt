// sol deploy command - Deployment preflight and guidance
//

///|
fn show_deploy_help() -> Unit {
  let help =
    #|Usage: sol deploy [options]
    #|
    #|Runs deployment preflight and prints provider-specific next commands.
    #|Current behavior is safe-by-default dry-run guidance.
    #|
    #|Options:
    #|  -r, --provider <name>   Deploy provider (default: cloudflare-workers)
    #|  -j, --project <name>    Provider project name (default: sol-docs)
    #|  -u, --prod-url <url>    Production URL hint (optional)
    #|  -d, --dry-run           Print commands only (default behavior)
    #|  -x, --execute           Execute deploy command
    #|  -h, --help              Show help
    #|
    #|Examples:
    #|  sol deploy
    #|  sol deploy --provider cloudflare-workers --project my-worker
    #|  sol deploy --provider cloudflare-pages --project my-docs
    #|  sol deploy --dry-run --prod-url https://example.com
    #|  pnpm dlx wrangler@4 deploy .sol/prod/server/main.js --name=my-worker
    #|
    #|Providers:
    #|  cloudflare-workers (recommended)
    #|  cloudflare-pages (compatibility)
  println(help)
}

///|
fn normalize_provider(raw : String) -> String {
  match raw.to_lower() {
    "cloudflare-workers" | "workers" | "worker" | "cloudflare" | "cf-workers" =>
      "cloudflare-workers"
    "cloudflare-pages" | "pages" => "cloudflare-pages"
    _ => raw.to_lower()
  }
}

///|
fn run_deploy_command(args : Array[String]) -> Unit {
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(
        key="provider",
        short="r",
        multiple=false,
        default=Some("cloudflare-workers"),
      ),
      @util.String(
        key="project",
        short="j",
        multiple=false,
        default=Some("sol-docs"),
      ),
      @util.String(key="prod-url", short="u", multiple=false, default=None),
      @util.Boolean(key="dry-run", short="d"),
      @util.Boolean(key="execute", short="x"),
      @util.Boolean(key="help", short="h"),
    ],
    allow_positionals=false,
  )

  if result.values.contains("help") && result.values["help"].cast() {
    show_deploy_help()
    return
  }

  let provider_raw : String = if result.values.contains("provider") {
    result.values["provider"].cast()
  } else {
    "cloudflare-workers"
  }
  let provider = normalize_provider(provider_raw)
  let project_name : String = if result.values.contains("project") {
    result.values["project"].cast()
  } else {
    "sol-docs"
  }
  let prod_url : String = if result.values.contains("prod-url") {
    result.values["prod-url"].cast()
  } else {
    ""
  }
  let dry_run = if result.values.contains("dry-run") {
    result.values["dry-run"].cast()
  } else {
    false
  }
  let execute = if result.values.contains("execute") {
    result.values["execute"].cast()
  } else {
    false
  }
  if execute && dry_run {
    @cli_common.console_error(
      @colorette.red("Error: --execute and --dry-run cannot be used together."),
    )
    @process.exit(1)
  }

  let cwd = @process.cwd()
  let moon_mod_path = @path.join2(cwd, "moon.mod.json")
  if !@fs.existsSync(moon_mod_path) {
    @cli_common.console_error(
      @colorette.red("Error: Not a MoonBit project (moon.mod.json not found)"),
    )
    @process.exit(1)
  }

  let docs_dist = @path.join2(cwd, "website/dist-docs")
  let static_dir = @path.join2(cwd, ".sol/prod/static")
  let worker_entry = @path.join2(cwd, ".sol/prod/server/main.js")

  println(@colorette.cyan("Running deploy preflight..."))
  println(@colorette.gray("  provider: \{provider}"))
  println(@colorette.gray("  project: \{project_name}"))
  if prod_url != "" {
    println(@colorette.gray("  production_url: \{prod_url}"))
  }

  let deploy_target = if provider == "cloudflare-workers" {
    if !@fs.existsSync(worker_entry) {
      @cli_common.console_error(
        @colorette.red(
          "Error: Worker entry not found (.sol/prod/server/main.js). Run `sol build` first.",
        ),
      )
      @process.exit(1)
      ""
    } else {
      ".sol/prod/server/main.js"
    }
  } else if provider == "cloudflare-pages" {
    if @fs.existsSync(docs_dist) {
      "website/dist-docs"
    } else if @fs.existsSync(static_dir) {
      ".sol/prod/static"
    } else {
      @cli_common.console_error(
        @colorette.red(
          "Error: Pages target not found. Run docs build (or `sol build`) first.",
        ),
      )
      @process.exit(1)
      ""
    }
  } else {
    @cli_common.console_error(
      @colorette.red(
        "Error: Unsupported provider '\{provider_raw}'. Use cloudflare-workers or cloudflare-pages.",
      ),
    )
    @process.exit(1)
    ""
  }
  println(@colorette.gray("  target: \{deploy_target}"))

  let deploy_cmd = if provider == "cloudflare-workers" {
    "pnpm dlx wrangler@4 deploy \{deploy_target} --name=\{project_name}"
  } else {
    "pnpm dlx wrangler@4 pages deploy \{deploy_target} --project-name=\{project_name}"
  }

  println("")
  println("Next command:")
  println(@colorette.cyan("  \{deploy_cmd}"))
  if provider == "cloudflare-pages" {
    println(
      @colorette.yellow("  Note: cloudflare-pages mode is compatibility path."),
    )
  }
  if prod_url != "" {
    println(@colorette.gray("  expected_url: \{prod_url}"))
  }

  if execute {
    println("")
    println(@colorette.cyan("Executing deploy command..."))
    try {
      let result = @child_process.spawnSync(
        "sh",
        args=["-c", deploy_cmd],
        cwd~,
        stdio="inherit",
      )
      let exit_code = result.status().unwrap_or(1)
      if exit_code != 0 {
        @process.exit(exit_code)
      }
    } catch {
      e => {
        @cli_common.console_error(@colorette.red("Deploy command error: \{e}"))
        @process.exit(1)
      }
    }
    println("")
    println(@colorette.green("✓ Deploy command completed"))
    return
  }

  println("")
  println(
    @colorette.green("✓ Deploy preflight completed (dry-run guidance mode)"),
  )
}
