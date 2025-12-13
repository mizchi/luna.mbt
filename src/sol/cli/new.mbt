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
    #|  -t, --template <t>  Template to use (default: "")
    #|  -h, --help          Show help
  println(help)
}

///|
fn run_new_command(args : Array[String]) -> Unit {
  // Parse new command options
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(key="template", short="t", multiple=false, default=Some("")),
      @util.Boolean(key="help", short="h"),
    ],
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
  let template : String = if result.values.contains("template") {
    result.values["template"].cast()
  } else {
    ""
  }
  // Get project directory path
  let cwd = @process.cwd()
  let project_dir = if @path.isAbsolute(name) {
    name
  } else {
    @path.join2(cwd, name)
  }
  // Check if project directory already exists
  if @fs.existsSync(project_dir) {
    console_error(@colorette.red("Error: Directory '\{name}' already exists"))
    @process.exit(1)
  }
  // Get template directory (relative to CLI script location)
  // For now, we use a fixed path - this should be configurable later
  let templates_dir = get_templates_dir()
  let template_dir = @path.join2(templates_dir, template)
  // Check if template exists
  if not(@fs.existsSync(template_dir)) {
    console_error(@colorette.red("Error: Template '\{template}' not found"))
    @process.exit(1)
  }
  // Get package name from directory
  let package_name = @path.basename(project_dir)
  println(@colorette.cyan("Creating new Sol project: \{project_dir}"))
  // Copy template with variable substitution (synchronous)
  copy_template_sync(template_dir, project_dir, package_name) catch {
    e => {
      console_error(@colorette.red("Error creating project: \{e}"))
      @process.exit(1)
    }
  }
  // Update moon.mod.json with project name
  let moon_mod_path = @path.join2(project_dir, "moon.mod.json")
  if @fs.existsSync(moon_mod_path) {
    try {
      let content = @fs.read_file_as_string(moon_mod_path)
      let updated = replace_name_in_json(content, package_name)
      @fs.writeFileSync(moon_mod_path, @js.any(updated))
    } catch {
      _ => ()
    }
  }
  // Update package.json with project name
  let package_json_path = @path.join2(project_dir, "package.json")
  if @fs.existsSync(package_json_path) {
    try {
      let content = @fs.read_file_as_string(package_json_path)
      let updated = replace_name_in_json(content, package_name)
      @fs.writeFileSync(package_json_path, @js.any(updated))
    } catch {
      _ => ()
    }
  }
  println(@colorette.green("\n✓ Project created successfully!\n"))
  println("Next steps:")
  println(@colorette.cyan("  cd \{name}"))
  println(@colorette.cyan("  npm install"))
  println(@colorette.cyan("  npm run dev"))
}

///|
/// Get templates directory path
/// This needs to be adjusted based on how the CLI is installed
fn get_templates_dir() -> String {
  // For development, templates are in src/sol/cli/templates
  // This path needs to be determined at runtime based on the script location
  // For now, we use process.cwd() as a fallback
  let cwd = @process.cwd()
  @path.join2(cwd, "src/sol/cli/templates")
}

///|
/// Copy template directory recursively (synchronous version)
fn copy_template_sync(
  src : String,
  dest : String,
  package_name : String,
) -> Unit raise @js.ThrowError {
  @fs.mkdirSync(dest, recursive=true)
  let entries = @fs.readdirSync(src)
  for entry in entries {
    let src_path = @path.join2(src, entry)
    // Remove .template extension if present
    let dest_name : String = if entry.has_suffix(".template") {
      let len = entry.length() - 9
      entry.substring(end=len)
    } else {
      entry
    }
    let dest_path = @path.join2(dest, dest_name)
    let stat = @fs.statSync(src_path)
    if stat.isDirectory() {
      copy_template_sync(src_path, dest_path, package_name)
    } else {
      let content = @fs.read_file_as_string(src_path)
      // Replace template variables
      let replaced = content
        .replace(old="{{PACKAGE_NAME}}", new=package_name)
        .replace(old="{{ PACKAGE_NAME }}", new=package_name)
      @fs.writeFileSync(dest_path, @js.any(replaced))
    }
  }
}

///|
/// Replace "name" field in JSON content using JS regex
extern "js" fn replace_name_in_json(
  content : String,
  new_name : String,
) -> String =
  #| (content, newName) => content.replace(/"name"\s*:\s*"[^"]*"/, `"name": "${newName}"`)
