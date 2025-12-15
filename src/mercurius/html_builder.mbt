///| HTML Builder for Shards

///|

///| Generates portable HTML snippets for resumable components (shards)

///|
/// Generate the complete shard HTML
pub fn generate_shard(config : ShardConfig) -> ShardOutput {
  let sb = StringBuilder::new(size_hint=512)
  let head_scripts : Array[String] = []
  let state_scripts : Array[String] = []

  // 1. Loader script (if requested)
  if config.include_loader {
    sb.write_string("<script type=\"module\" src=\"")
    sb.write_string(config.loader_url)
    sb.write_string("\"></script>\n")
    head_scripts.push(config.loader_url)
  }

  // 2. State script (if using ScriptRef)
  // Note: actual script generation is done by generate_shard_with_state_script

  // 3. Main container div
  sb.write_string("<div ln:id=\"")
  sb.write_string(config.id)
  sb.write_char('"')

  // ln:url attribute
  sb.write_string(" ln:url=\"")
  sb.write_string(config.script_url)
  sb.write_char('"')

  // ln:trigger attribute (only if not default)
  if not(config.trigger is Load) {
    sb.write_string(" ln:trigger=\"")
    sb.write_string(config.trigger.to_string())
    sb.write_char('"')
  }

  // ln:state attribute
  if format_state_attr(config.state) is Some(state_value) {
    sb.write_string(" ln:state=\"")
    sb.write_string(state_value)
    sb.write_char('"')
  }
  sb.write_char('>')

  // 4. SSR content (if any)
  if config.ssr_content is Some(content) {
    sb.write_string(content)
  }

  // 5. Close container
  sb.write_string("</div>")
  { html: sb.to_string(), head_scripts, state_scripts }
}

///|
/// Generate shard with automatic state script
/// Use this when you have large state that should be in a separate script tag
pub fn generate_shard_with_state_script(
  config : ShardConfig,
  state_json : String,
) -> ShardOutput {
  let state_script_id = "ln-state-" + config.id
  let state_script = generate_state_script(state_script_id, state_json)

  // Update config to use script reference
  let updated_config = { ..config, state: ScriptRef(state_script_id) }
  let base_output = generate_shard(updated_config)

  // Append state script to HTML
  let combined_html = base_output.html + "\n" + state_script
  let state_scripts = base_output.state_scripts
  state_scripts.push(state_script)
  { html: combined_html, head_scripts: base_output.head_scripts, state_scripts }
}

///|
/// Generate minimal shard (no loader, inline state)
pub fn generate_minimal_shard(
  id : String,
  script_url : String,
  state_json : String,
  ssr_content : String,
) -> String {
  let config = ShardConfig::new(id, script_url)
    .with_state(state_json)
    .with_ssr_content(ssr_content)
  generate_shard(config).html
}

///|
/// Generate standalone shard (with loader)
pub fn generate_standalone_shard(
  id : String,
  script_url : String,
  loader_url : String,
  state_json : String,
  ssr_content : String,
) -> String {
  let config = ShardConfig::new(id, script_url)
    .with_loader(loader_url)
    .with_state(state_json)
    .with_ssr_content(ssr_content)
  generate_shard(config).html
}

///|
/// Generate shard with visible trigger
pub fn generate_lazy_shard(
  id : String,
  script_url : String,
  state_json : String,
  ssr_content : String,
) -> String {
  let config = ShardConfig::new(id, script_url)
    .with_trigger(Visible)
    .with_state(state_json)
    .with_ssr_content(ssr_content)
  generate_shard(config).html
}

///|
/// Generate multiple shards that share a single loader
pub fn generate_shard_group(
  loader_url : String,
  configs : Array[ShardConfig],
) -> String {
  let sb = StringBuilder::new(size_hint=1024)

  // Single loader for all
  sb.write_string("<script type=\"module\" src=\"")
  sb.write_string(loader_url)
  sb.write_string("\"></script>\n")

  // Each shard without its own loader
  for config in configs {
    let no_loader_config = { ..config, include_loader: false }
    let output = generate_shard(no_loader_config)
    sb.write_string(output.html)
    sb.write_char('\n')
  }
  sb.to_string()
}

///|
/// Estimate the recommended state format based on JSON size
pub fn auto_select_state_format(
  json : String,
  base_config : ShardConfig,
) -> ShardConfig {
  let size = json.length()
  if size < 1024 {
    // Small: inline in attribute
    { ..base_config, state: Inline(json) }
  } else if size < 102400 {
    // Medium: script reference (caller should also call generate_state_script)
    let script_id = "ln-state-" + base_config.id
    { ..base_config, state: ScriptRef(script_id) }
  } else {
    // Large: would need URL, but we can't generate that here
    // Default to script reference with a warning
    let script_id = "ln-state-" + base_config.id
    { ..base_config, state: ScriptRef(script_id) }
  }
}
