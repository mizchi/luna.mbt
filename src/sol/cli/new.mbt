///| sol new command - Create a new Sol project

///|
fn show_new_help() -> Unit {
  let help =
    #|Usage: sol new <name> [options]
    #|
    #|Arguments:
    #|  <name>              Project name or path
    #|
    #|Options:
    #|  -h, --help          Show help
  println(help)
}

///|
fn run_new_command(args : Array[String]) -> Unit {
  // Parse new command options
  let result = @util.parseArgs(
    args~,
    options=[@util.Boolean(key="help", short="h")],
    allow_positionals=true,
  )
  // Show help if requested
  if result.values.contains("help") && result.values["help"].cast() {
    show_new_help()
    return
  }
  // Require project name
  if result.positionals.is_empty() {
    console_error(@colorette.red("Error: Project name is required"))
    println("")
    show_new_help()
    @process.exit(1)
  }
  let name = result.positionals[0]
  // Get project directory path
  let cwd = @process.cwd()
  let project_dir = if @path.isAbsolute(name) { name } else { @path.join2(cwd, name) }
  // Check if project directory already exists
  if @fs.existsSync(project_dir) {
    console_error(@colorette.red("Error: Directory '\{name}' already exists"))
    @process.exit(1)
  }
  // Get package name from directory
  let package_name = @path.basename(project_dir)
  println(@colorette.cyan("Creating new Sol project: \{project_dir}"))
  // Generate project from embedded templates
  let templates = generate_templates(package_name)
  for tmpl in templates {
    let file_path = @path.join2(project_dir, tmpl.path)
    let dir_path = @path.dirname(file_path)
    // Create parent directories if needed
    try {
      @fs.mkdirSync(dir_path, recursive=true)
      @fs.writeFileSync(file_path, @js.any(tmpl.content))
    } catch {
      e => {
        console_error(@colorette.red("Error creating file \{tmpl.path}: \{e}"))
        @process.exit(1)
      }
    }
  }
  println(@colorette.green("\n✓ Project created successfully!\n"))
  println("Next steps:")
  println(@colorette.cyan("  cd \{name}"))
  println(@colorette.cyan("  npm install"))
  println(@colorette.cyan("  npm run dev"))
}
