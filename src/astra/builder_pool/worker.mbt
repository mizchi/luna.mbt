// Astra Builder Pool - Worker Entry Point
//
// This module is the entry point for worker processes spawned by the BuilderPool.
// It receives IPC messages from the parent process and generates pages.

// =============================================================================
// FFI for IPC Communication
// =============================================================================

///|
/// Listen for IPC messages from parent process
/// Callback receives the message object
extern "js" fn ffi_on_message(callback : (@core.Any) -> Unit) -> Unit =
  #| (callback) => {
  #|   process.on("message", (msg) => callback(msg));
  #| }

///|
/// Send IPC message to parent process
extern "js" fn ffi_send_message(message : @core.Any) -> Bool =
  #| (message) => {
  #|   return process.send(message);
  #| }

///|
/// Exit the worker process
extern "js" fn ffi_exit(code : Int) -> Unit =
  #| (code) => {
  #|   process.exit(code);
  #| }

// =============================================================================
// Worker State
// =============================================================================

///|
/// Worker context after initialization
priv struct WorkerContext {
  /// Build configuration
  config : @astra.SsgConfig
  /// All pages to generate
  pages : Array[@astra.PageMeta]
  /// Generated sidebar
  sidebar : Array[@astra.SidebarGroup]
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
/// Send ready message to parent
fn send_ready() -> Unit {
  let obj = @core.new_object()
  obj["type"] = @core.any("ready")
  ffi_send_message(obj) |> ignore
}

///|
/// Send done message to parent
fn send_done(result : JobResult) -> Unit {
  ffi_send_message(result.to_json()) |> ignore
}

///|
/// Send error message to parent
fn send_error(message : String) -> Unit {
  let obj = @core.new_object()
  obj["type"] = @core.any("error")
  obj["message"] = @core.any(message)
  ffi_send_message(obj) |> ignore
}

///|
/// Handle Init message
async fn handle_init(data : WorkerInitData) -> Unit {
  // Parse config JSON
  let config = ssg_config_from_json(data.config_json)
  guard config is Some(cfg) else {
    send_error("Failed to parse config JSON")
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
  send_ready()
}

///|
/// Handle Job message
fn handle_job(page_index : Int) -> Unit {
  guard worker_ctx.val is Some(ctx) else {
    send_error("Worker not initialized")
    return
  }

  // Validate page index
  if page_index < 0 || page_index >= ctx.pages.length() {
    send_done(JobResult::{
      page_index,
      url_path: "",
      success: false,
      error: Some("Invalid page index: \{page_index}"),
    })
    return
  }
  let page = ctx.pages[page_index]

  // Create build context
  let build_ctx = @astra.BuildContext::{
    config: ctx.config,
    pages: ctx.pages,
    sidebar: ctx.sidebar,
    cwd: ctx.cwd,
  }

  // Generate the page
  match @generator.generate_single_page(build_ctx, page, ctx.highlighter) {
    Ok(_) =>
      send_done(JobResult::{
        page_index,
        url_path: page.url_path,
        success: true,
        error: None,
      })
    Err(e) =>
      send_done(JobResult::{
        page_index,
        url_path: page.url_path,
        success: false,
        error: Some(e),
      })
  }
}

///|
/// Handle Shutdown message
fn handle_shutdown() -> Unit {
  ffi_exit(0)
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
      let config_json : String = msg["configJson"].cast()
      let pages_json : String = msg["pagesJson"].cast()
      let sidebar_json : String = msg["sidebarJson"].cast()
      let cwd : String = msg["cwd"].cast()
      let init_data = WorkerInitData::{
        config_json,
        pages_json,
        sidebar_json,
        cwd,
      }
      handle_init(init_data)
    }
    "job" => {
      let page_index : Int = msg["pageIndex"].cast()
      handle_job(page_index)
    }
    "shutdown" => handle_shutdown()
    _ => send_error("Unknown message type: \{msg_type}")
  }
}

// =============================================================================
// Worker Entry Point
// =============================================================================

///|
/// Start the worker and listen for IPC messages
pub fn start_worker() -> Unit {
  // Set up message handler
  ffi_on_message(fn(msg) {
    // Handle message - spawn async task using Promise
    let _ = @core.from_async(async fn() { handle_message_async(msg) })

  })
}
