// Sol Builder - Generic Worker Pool Implementation
//
// Manages worker processes for parallel job execution.
// Domain-specific job handling is delegated to worker scripts.

// =============================================================================
// Types
// =============================================================================

///|
/// Handle to a worker process
struct WorkerHandle {
  /// Child process reference
  process : @child_process.ChildProcess
  /// Current state
  mut state : WorkerState
}

///|
/// The worker pool manages multiple worker processes
pub struct WorkerPool {
  /// Pool configuration
  config : PoolConfig
  /// Worker handles
  workers : Array[WorkerHandle]
  /// Pending job IDs
  mut pending_jobs : Array[Int]
  /// Completed job results
  mut results : Array[JobResult]
  /// Number of completed jobs
  mut completed_count : Int
  /// Total number of jobs
  mut total_jobs : Int
  /// Completion callback
  mut on_complete : (() -> Unit)?
  /// Initialization data (JSON string)
  init_data : String
}

// =============================================================================
// Pool Creation
// =============================================================================

///|
/// Create a new worker pool with the given configuration
pub fn WorkerPool::new(config : PoolConfig, init_data : String) -> WorkerPool {
  let workers : Array[WorkerHandle] = []
  let pool = WorkerPool::{
    config,
    workers,
    pending_jobs: [],
    results: [],
    completed_count: 0,
    total_jobs: 0,
    on_complete: None,
    init_data,
  }

  // Spawn workers
  for i = 0; i < config.num_workers; i = i + 1 {
    pool.spawn_worker()
  }
  pool
}

///|
/// Spawn a single worker process
fn WorkerPool::spawn_worker(self : WorkerPool) -> Unit {
  // Fork the worker script
  let child = @child_process.fork(
    self.config.worker_script,
    cwd=self.config.cwd,
    silent=true,
  )

  // Create worker handle (starts as Initializing, becomes Idle when ready)
  let handle = WorkerHandle::{
    process: child,
    state: WorkerState::Initializing,
  }
  let worker_id = self.workers.length()
  self.workers.push(handle)

  // Set up message handler
  setup_worker_message_handler(child, self, worker_id)

  // Set up exit handler
  setup_worker_exit_handler(child, self, worker_id)

  // Send init message
  let init_msg = ParentMessage::Init(self.init_data)
  child.send(init_msg.to_json().raw()) |> ignore
}

///|
/// Set up message handler for a worker
fn setup_worker_message_handler(
  child : @child_process.ChildProcess,
  pool : WorkerPool,
  worker_id : Int,
) -> Unit {
  let emitter = child.to_event_emitter()
  emitter.on("message", fn(msg) { pool.handle_worker_message(worker_id, msg) })
}

///|
/// Set up exit handler for a worker
fn setup_worker_exit_handler(
  child : @child_process.ChildProcess,
  pool : WorkerPool,
  worker_id : Int,
) -> Unit {
  let emitter = child.to_event_emitter()
  emitter.on("exit", fn(_code) { pool.handle_worker_exit(worker_id) })
}

// =============================================================================
// Message Handling
// =============================================================================

///|
/// Handle message from a worker
fn WorkerPool::handle_worker_message(
  self : WorkerPool,
  worker_id : Int,
  msg : @core.Any,
) -> Unit {
  guard WorkerMessage::from_json(IpcMessage::from_raw(msg)) is Some(worker_msg) else {
    println("  Warning: Invalid message from worker \{worker_id}")
    return
  }
  match worker_msg {
    Ready => {
      // Worker is ready - assign pending job if any
      self.workers[worker_id].state = WorkerState::Idle
      self.try_assign_job(worker_id)
    }
    Done(result) => {
      // Job completed
      self.results.push(result)
      self.completed_count = self.completed_count + 1
      self.workers[worker_id].state = WorkerState::Idle

      // Check if all jobs are done
      if self.completed_count >= self.total_jobs {
        // Call completion callback
        match self.on_complete {
          Some(callback) => callback()
          None => ()
        }
      } else {
        // Try to assign next job
        self.try_assign_job(worker_id)
      }
    }
    Error(message) => {
      println("  Worker \{worker_id} error: \{message}")
      // Try to recover by assigning next job
      self.workers[worker_id].state = WorkerState::Idle
      self.try_assign_job(worker_id)
    }
  }
}

///|
/// Handle worker exit
fn WorkerPool::handle_worker_exit(self : WorkerPool, worker_id : Int) -> Unit {
  self.workers[worker_id].state = WorkerState::Terminated
}

// =============================================================================
// Job Management
// =============================================================================

///|
/// Submit jobs to the pool
pub fn WorkerPool::submit_jobs(self : WorkerPool, job_ids : Array[Int]) -> Unit {
  self.pending_jobs = job_ids.copy()
  self.total_jobs = job_ids.length()
  self.completed_count = 0
  self.results = []

  // Try to assign jobs to idle workers
  for i = 0; i < self.workers.length(); i = i + 1 {
    if self.workers[i].state is Idle {
      self.try_assign_job(i)
    }
  }
}

///|
/// Try to assign a pending job to a worker
fn WorkerPool::try_assign_job(self : WorkerPool, worker_id : Int) -> Unit {
  if self.pending_jobs.is_empty() {
    return
  }

  // Get next job
  let job_id = self.pending_jobs.unsafe_pop()

  // Mark worker as busy
  self.workers[worker_id].state = WorkerState::Busy(job_id)

  // Send job message
  let msg = ParentMessage::Job(job_id)
  self.workers[worker_id].process.send(msg.to_json().raw()) |> ignore
}

///|
/// Wait for all submitted jobs to complete
pub async fn WorkerPool::wait_all(self : WorkerPool) -> Array[JobResult] {
  // If already complete, return immediately
  if self.completed_count >= self.total_jobs {
    return self.results
  }

  // Create promise to wait for completion
  let resolvers : @core.PromiseResolvers[Unit] = @core.Promise::withResolvers()
  self.on_complete = Some(fn() { resolvers.resolve(()) })
  resolvers.promise.wait()
  self.results
}

///|
/// Shutdown all workers
pub fn WorkerPool::shutdown(self : WorkerPool) -> Unit {
  for worker in self.workers {
    if !(worker.state is Terminated) {
      let msg = ParentMessage::Shutdown
      worker.process.send(msg.to_json().raw()) |> ignore
    }
  }
}

///|
/// Get number of workers
pub fn WorkerPool::num_workers(self : WorkerPool) -> Int {
  self.workers.length()
}
