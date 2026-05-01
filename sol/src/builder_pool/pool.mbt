// Sol Builder Pool - Pool Implementation
//
// Uses sol/builder for generic worker pool infrastructure.
// Provides SSG-specific convenience functions.

// =============================================================================
// Convenience Functions for Sol SSG
// =============================================================================

///|
/// Run parallel build for all pages
pub async fn run_parallel_build(
  config : @ssg.SsgConfig,
  pages : Array[@ssg.PageMeta],
  sidebar : Array[@ssg.SidebarGroup],
  cwd : String,
  worker_script : String,
  num_workers? : Int,
) -> Array[PageJobResult] {
  let num = num_workers.unwrap_or(4)
  println("Starting parallel build with \{num} workers...")

  // Create pool config
  let pool_config = @builder.PoolConfig::{
    num_workers: num,
    worker_script,
    cwd,
    timeout_ms: 60000,
  }

  // Serialize init data to JSON string
  let init_data = WorkerInitData::{
    config_json: ssg_config_to_json(config),
    pages_json: pages_to_json(pages),
    sidebar_json: sidebar_to_json(sidebar),
    cwd,
  }
  let init_data_json = init_data.to_json_string()

  // Create pool using sol/builder
  let pool = @builder.WorkerPool::new(pool_config, init_data_json)

  // Submit all page indices as job IDs
  let job_ids : Array[Int] = []
  for i = 0; i < pages.length(); i = i + 1 {
    job_ids.push(i)
  }
  pool.submit_jobs(job_ids)

  // Wait for completion
  let results = pool.wait_all()

  // Shutdown workers
  pool.shutdown()

  // Convert to SSG-specific results
  let page_results : Array[PageJobResult] = []
  let mut success_count = 0
  for r in results {
    let page_result = PageJobResult::from_builder_result(r)
    page_results.push(page_result)
    if page_result.success {
      success_count = success_count + 1
    }
  }
  let fail_count = page_results.length() - success_count
  println(
    "Parallel build complete: \{success_count} succeeded, \{fail_count} failed",
  )
  page_results
}
