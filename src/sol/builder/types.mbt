// Sol Builder - Generic Worker Pool Types
//
// Provides generic types for parallel build infrastructure.
// Used by sol/builder_pool for SSG and other parallel build tasks.

// =============================================================================
// Pool Configuration
// =============================================================================

///|
/// Configuration for the worker pool
pub(all) struct PoolConfig {
  /// Number of worker processes
  num_workers : Int
  /// Path to the worker script
  worker_script : String
  /// Working directory
  cwd : String
  /// Timeout per job in milliseconds
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
  /// Worker is processing a job
  Busy(Int) // job_id
  /// Worker has terminated
  Terminated
}

// =============================================================================
// Job Result
// =============================================================================

///|
/// Result of a job execution
pub(all) struct JobResult {
  /// Job identifier
  job_id : Int
  /// Output path or identifier
  output_path : String
  /// Whether the job succeeded
  success : Bool
  /// Error message if failed
  error : String?
}

///|
/// Serialize JobResult to JSON object (for worker to send)
pub fn JobResult::to_json(self : JobResult) -> @core.Any {
  let obj = @core.new_object()
  obj["type"] = @core.any("done")
  obj["jobId"] = @core.any(self.job_id)
  obj["outputPath"] = @core.any(self.output_path)
  obj["success"] = @core.any(self.success)
  match self.error {
    Some(e) => obj["error"] = @core.any(e)
    None => ()
  }
  obj
}

// =============================================================================
// IPC Messages: Parent -> Worker
// =============================================================================

///|
/// Messages sent from parent to worker
pub enum ParentMessage {
  /// Initialize worker with custom data
  Init(String) // JSON string with init data
  /// Assign a job
  Job(Int) // job_id
  /// Shutdown the worker
  Shutdown
}

///|
/// Serialize ParentMessage to JSON object
pub fn ParentMessage::to_json(self : ParentMessage) -> @core.Any {
  let obj = @core.new_object()
  match self {
    Init(data) => {
      obj["type"] = @core.any("init")
      obj["data"] = @core.any(data)
    }
    Job(job_id) => {
      obj["type"] = @core.any("job")
      obj["jobId"] = @core.any(job_id)
    }
    Shutdown => obj["type"] = @core.any("shutdown")
  }
  obj
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

///|
/// Deserialize WorkerMessage from JSON object
pub fn WorkerMessage::from_json(obj : @core.Any) -> WorkerMessage? {
  let msg_type : String = obj["type"].cast()
  match msg_type {
    "ready" => Some(Ready)
    "done" => {
      let job_id : Int = obj["jobId"].cast()
      let output_path : String = obj["outputPath"].cast()
      let success : Bool = obj["success"].cast()
      let error : String? = if @core.is_nullish(obj["error"]) {
        None
      } else {
        Some(obj["error"].cast())
      }
      Some(Done(JobResult::{ job_id, output_path, success, error }))
    }
    "error" => {
      let message : String = obj["message"].cast()
      Some(Error(message))
    }
    _ => None
  }
}
