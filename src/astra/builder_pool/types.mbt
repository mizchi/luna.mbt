// Astra Builder Pool - Types and IPC Protocol
//
// Parallel page generation using child_process.fork()

// =============================================================================
// Pool Configuration
// =============================================================================

///|
/// Configuration for the builder pool
pub(all) struct PoolConfig {
  /// Number of worker processes
  num_workers : Int
  /// Path to the worker script
  worker_script : String
  /// Working directory
  cwd : String
  /// Timeout per page in milliseconds
  timeout_ms : Int
}

///|
/// Default pool configuration
pub fn PoolConfig::default(worker_script : String, cwd : String) -> PoolConfig {
  PoolConfig::{ num_workers: 4, worker_script, cwd, timeout_ms: 60000 }
}

// =============================================================================
// Worker State
// =============================================================================

///|
/// State of a worker process
pub enum WorkerState {
  /// Worker is initializing (not ready for jobs yet)
  Initializing
  /// Worker is ready for work
  Idle
  /// Worker is processing a page
  Busy(Int) // page_index
  /// Worker has terminated
  Terminated
}

// =============================================================================
// Job Result
// =============================================================================

///|
/// Result of a page generation job
pub(all) struct JobResult {
  /// Index of the page in the pages array
  page_index : Int
  /// URL path of the generated page
  url_path : String
  /// Whether the job succeeded
  success : Bool
  /// Error message if failed
  error : String?
}

// =============================================================================
// IPC Messages: Parent -> Worker
// =============================================================================

///|
/// Messages sent from parent to worker
pub enum ParentMessage {
  /// Initialize worker with build context
  Init(WorkerInitData)
  /// Assign a page to generate
  Job(Int) // page_index
  /// Shutdown the worker
  Shutdown
}

///|
/// Data sent to worker during initialization
pub(all) struct WorkerInitData {
  /// SsgConfig serialized as JSON
  config_json : String
  /// Array of PageMeta serialized as JSON
  pages_json : String
  /// Array of SidebarGroup serialized as JSON
  sidebar_json : String
  /// Working directory
  cwd : String
}

// =============================================================================
// IPC Messages: Worker -> Parent
// =============================================================================

///|
/// Messages sent from worker to parent
pub enum WorkerMessage {
  /// Worker is ready to accept jobs
  Ready
  /// Job completed
  Done(JobResult)
  /// Worker encountered an error
  Error(String) // message
}

// =============================================================================
// JSON Serialization for IPC
// =============================================================================

///|
/// Serialize ParentMessage to JSON object
pub fn ParentMessage::to_json(self : ParentMessage) -> @core.Any {
  let obj = @core.new_object()
  match self {
    Init(data) => {
      obj["type"] = @core.any("init")
      obj["configJson"] = @core.any(data.config_json)
      obj["pagesJson"] = @core.any(data.pages_json)
      obj["sidebarJson"] = @core.any(data.sidebar_json)
      obj["cwd"] = @core.any(data.cwd)
    }
    Job(page_index) => {
      obj["type"] = @core.any("job")
      obj["pageIndex"] = @core.any(page_index)
    }
    Shutdown => obj["type"] = @core.any("shutdown")
  }
  obj
}

///|
/// Deserialize WorkerMessage from JSON object
pub fn WorkerMessage::from_json(obj : @core.Any) -> WorkerMessage? {
  let msg_type : String = obj["type"].cast()
  match msg_type {
    "ready" => Some(Ready)
    "done" => {
      let page_index : Int = obj["pageIndex"].cast()
      let url_path : String = obj["urlPath"].cast()
      let success : Bool = obj["success"].cast()
      let error : String? = if @core.is_nullish(obj["error"]) {
        None
      } else {
        Some(obj["error"].cast())
      }
      Some(Done(JobResult::{ page_index, url_path, success, error }))
    }
    "error" => {
      let message : String = obj["message"].cast()
      Some(Error(message))
    }
    _ => None
  }
}

///|
/// Serialize JobResult to JSON object (for worker to send)
pub fn JobResult::to_json(self : JobResult) -> @core.Any {
  let obj = @core.new_object()
  obj["type"] = @core.any("done")
  obj["pageIndex"] = @core.any(self.page_index)
  obj["urlPath"] = @core.any(self.url_path)
  obj["success"] = @core.any(self.success)
  match self.error {
    Some(e) => obj["error"] = @core.any(e)
    None => ()
  }
  obj
}
