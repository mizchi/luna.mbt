// Astra Builder Pool - Worker Entry Point
//
// This module is the entry point for worker processes spawned by the WorkerPool.
// Uses sol/builder for IPC infrastructure.

// =============================================================================
// Worker State
// =============================================================================

///|
/// Worker context after initialization
priv struct WorkerContext {
  /// Build configuration
  config : @ssg.SsgConfig
  /// All pages to generate
  pages : Array[@ssg.PageMeta]
  /// Generated sidebar
  sidebar : Array[@ssg.SidebarGroup]
  /// Working directory
  cwd : String
  /// Shiki highlighter instance
  highlighter : @shiki.Highlighter
}

///|
/// Mutable reference to worker context
let worker_ctx : Ref[WorkerContext?] = Ref::new(None)

// =============================================================================
// Message Handlers
// =============================================================================

///|
/// Handle Init message
async fn handle_init(data_json : String) -> Unit {
  // Parse init data JSON
  let obj = parse_json_string(data_json)
  guard WorkerInitData::from_json(obj) is Some(data) else {
    @builder.send_error("Failed to parse init data JSON")
    return
  }

  // Parse config JSON
  let config = ssg_config_from_json(data.config_json)
  guard config is Some(cfg) else {
    @builder.send_error("Failed to parse config JSON")
    return
  }

  // Parse pages JSON
  let pages = pages_from_json(data.pages_json)

  // Parse sidebar JSON
  let sidebar = sidebar_from_json(data.sidebar_json)

  // Create Shiki highlighter (this is the expensive operation)
  let highlighter = @shiki.create_default_highlighter().wait()

  // Store context
  worker_ctx.val = Some(WorkerContext::{
    config: cfg,
    pages,
    sidebar,
    cwd: data.cwd,
    highlighter,
  })

  // Notify parent we're ready
  @builder.send_ready()
}

///|
/// Handle Job message
fn handle_job(job_id : Int) -> Unit {
  guard worker_ctx.val is Some(ctx) else {
    @builder.send_error("Worker not initialized")
    return
  }

  // job_id is the page index
  let page_index = job_id

  // Validate page index
  if page_index < 0 || page_index >= ctx.pages.length() {
    @builder.send_done(@builder.JobResult::{
      job_id,
      output_path: "",
      success: false,
      error: Some("Invalid page index: \{page_index}"),
    })
    return
  }
  let page = ctx.pages[page_index]

  // Create build context
  let build_ctx = @ssg.BuildContext::{
    config: ctx.config,
    pages: ctx.pages,
    sidebar: ctx.sidebar,
    cwd: ctx.cwd,
    doc_tree: None, // Built lazily if needed
    is_dev: false, // Workers are for production builds
  }

  // Generate the page
  match @generator.generate_single_page(build_ctx, page, ctx.highlighter) {
    Ok(_) =>
      @builder.send_done(@builder.JobResult::{
        job_id,
        output_path: page.url_path,
        success: true,
        error: None,
      })
    Err(e) =>
      @builder.send_done(@builder.JobResult::{
        job_id,
        output_path: page.url_path,
        success: false,
        error: Some(e),
      })
  }
}

///|
/// Handle Shutdown message
fn handle_shutdown() -> Unit {
  @builder.exit(0)
}

// =============================================================================
// Message Router
// =============================================================================

///|
/// Parse and route incoming IPC message (async wrapper)
async fn handle_message_async(msg : @core.Any) -> Unit {
  let msg_type : String = msg["type"].cast()
  match msg_type {
    "init" => {
      let data_json : String = msg["data"].cast()
      handle_init(data_json)
    }
    "job" => {
      let job_id : Int = msg["jobId"].cast()
      handle_job(job_id)
    }
    "shutdown" => handle_shutdown()
    _ => @builder.send_error("Unknown message type: \{msg_type}")
  }
}

// =============================================================================
// Worker Entry Point
// =============================================================================

///|
/// Start the worker and listen for IPC messages
pub fn start_worker() -> Unit {
  // Set up message handler using sol/builder IPC
  @builder.on_message(fn(msg) {
    // Handle message - spawn async task using Promise
    let _ = @core.from_async(async fn() { handle_message_async(msg) })

  })
}

// =============================================================================
// Helpers
// =============================================================================

///|
/// Parse JSON string to Any object
extern "js" fn parse_json_string(json : String) -> @core.Any =
  #| (json) => JSON.parse(json)
