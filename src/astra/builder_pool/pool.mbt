// Astra Builder Pool - Pool Implementation
//
// Manages worker processes for parallel page generation

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
/// The builder pool manages multiple worker processes
pub struct BuilderPool {
  /// Pool configuration
  config : PoolConfig
  /// Worker handles
  workers : Array[WorkerHandle]
  /// Pending job indices
  mut pending_jobs : Array[Int]
  /// Completed job results
  mut results : Array[JobResult]
  /// Number of completed jobs
  mut completed_count : Int
  /// Total number of jobs
  mut total_jobs : Int
  /// Completion callback
  mut on_complete : (() -> Unit)?
  /// Initialization data
  init_data : WorkerInitData
}

// =============================================================================
// Pool Creation
// =============================================================================

///|
/// Create a new builder pool with the given configuration
pub fn BuilderPool::new(
  config : PoolConfig,
  init_data : WorkerInitData,
) -> BuilderPool {
  let workers : Array[WorkerHandle] = []
  let pool = BuilderPool::{
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
fn BuilderPool::spawn_worker(self : BuilderPool) -> Unit {
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
  child.send(init_msg.to_json()) |> ignore
}

///|
/// Set up message handler for a worker (external function to avoid closure issues)
fn setup_worker_message_handler(
  child : @child_process.ChildProcess,
  pool : BuilderPool,
  worker_id : Int,
) -> Unit {
  let emitter = child.to_event_emitter()
  emitter.on("message", fn(msg) { pool.handle_worker_message(worker_id, msg) })
}

///|
/// Set up exit handler for a worker
fn setup_worker_exit_handler(
  child : @child_process.ChildProcess,
  pool : BuilderPool,
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
fn BuilderPool::handle_worker_message(
  self : BuilderPool,
  worker_id : Int,
  msg : @core.Any,
) -> Unit {
  guard WorkerMessage::from_json(msg) is Some(worker_msg) else {
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
fn BuilderPool::handle_worker_exit(self : BuilderPool, worker_id : Int) -> Unit {
  self.workers[worker_id].state = WorkerState::Terminated
}

// =============================================================================
// Job Management
// =============================================================================

///|
/// Submit jobs to the pool
pub fn BuilderPool::submit_jobs(
  self : BuilderPool,
  page_indices : Array[Int],
) -> Unit {
  self.pending_jobs = page_indices.copy()
  self.total_jobs = page_indices.length()
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
fn BuilderPool::try_assign_job(self : BuilderPool, worker_id : Int) -> Unit {
  if self.pending_jobs.is_empty() {
    return
  }

  // Get next job
  let page_index = self.pending_jobs.unsafe_pop()

  // Mark worker as busy
  self.workers[worker_id].state = WorkerState::Busy(page_index)

  // Send job message
  let msg = ParentMessage::Job(page_index)
  self.workers[worker_id].process.send(msg.to_json()) |> ignore
}

///|
/// Wait for all submitted jobs to complete
pub async fn BuilderPool::wait_all(self : BuilderPool) -> Array[JobResult] {
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
pub fn BuilderPool::shutdown(self : BuilderPool) -> Unit {
  for worker in self.workers {
    if not(worker.state is Terminated) {
      let msg = ParentMessage::Shutdown
      worker.process.send(msg.to_json()) |> ignore
    }
  }
}

// =============================================================================
// Convenience Functions
// =============================================================================

///|
/// Run parallel build for all pages
pub async fn run_parallel_build(
  config : @astra.SsgConfig,
  pages : Array[@astra.PageMeta],
  sidebar : Array[@astra.SidebarGroup],
  cwd : String,
  worker_script : String,
  num_workers? : Int,
) -> Array[JobResult] {
  let num = num_workers.unwrap_or(4)
  println("Starting parallel build with \{num} workers...")

  // Create pool config
  let pool_config = PoolConfig::{
    num_workers: num,
    worker_script,
    cwd,
    timeout_ms: 60000,
  }

  // Serialize init data
  let init_data = WorkerInitData::{
    config_json: ssg_config_to_json(config),
    pages_json: pages_to_json(pages),
    sidebar_json: sidebar_to_json(sidebar),
    cwd,
  }

  // Create pool
  let pool = BuilderPool::new(pool_config, init_data)

  // Submit all page indices
  let page_indices : Array[Int] = []
  for i = 0; i < pages.length(); i = i + 1 {
    page_indices.push(i)
  }
  pool.submit_jobs(page_indices)

  // Wait for completion
  let results = pool.wait_all()

  // Shutdown workers
  pool.shutdown()

  // Report results
  let mut success_count = 0
  for r in results {
    if r.success {
      success_count = success_count + 1
    }
  }
  let fail_count = results.length() - success_count
  println(
    "Parallel build complete: \{success_count} succeeded, \{fail_count} failed",
  )
  results
}
