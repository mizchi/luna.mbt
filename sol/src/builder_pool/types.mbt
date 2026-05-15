// Sol Builder Pool - SSG-specific Types
//
// Extends sol/builder with SSG-specific data structures.
// Generic pool infrastructure is provided by sol/builder.

// =============================================================================
// Re-export generic types from sol/builder
// =============================================================================

// Note: Use @builder.PoolConfig, @builder.WorkerPool, @builder.JobResult directly

// =============================================================================
// SSG-specific Init Data
// =============================================================================

///|
/// Data sent to worker during initialization (SSG-specific)
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

///|
/// Serialize WorkerInitData to JSON string for IPC
pub fn WorkerInitData::to_json_string(self : WorkerInitData) -> String {
  let obj : Map[String, Json] = {
    "configJson": self.config_json.to_json(),
    "pagesJson": self.pages_json.to_json(),
    "sidebarJson": self.sidebar_json.to_json(),
    "cwd": self.cwd.to_json(),
  }
  obj.to_json().stringify()
}

///|
/// Parse WorkerInitData from JSON.
pub fn WorkerInitData::from_json(json : Json) -> WorkerInitData? {
  guard json is Object(obj) else { return None }
  guard obj.get("configJson") is Some(String(config_json)) else { return None }
  guard obj.get("pagesJson") is Some(String(pages_json)) else { return None }
  guard obj.get("sidebarJson") is Some(String(sidebar_json)) else {
    return None
  }
  guard obj.get("cwd") is Some(String(cwd)) else { return None }
  Some(WorkerInitData::{ config_json, pages_json, sidebar_json, cwd })
}

// =============================================================================
// SSG Job Result (wrapper around generic JobResult)
// =============================================================================

///|
/// SSG-specific job result with page metadata
pub(all) struct PageJobResult {
  /// Index of the page in the pages array
  page_index : Int
  /// URL path of the generated page
  url_path : String
  /// Whether the job succeeded
  success : Bool
  /// Error message if failed
  error : String?
}

///|
/// Convert generic JobResult to PageJobResult
pub fn PageJobResult::from_builder_result(
  result : @builder.JobResult,
) -> PageJobResult {
  PageJobResult::{
    page_index: result.job_id,
    url_path: result.output_path,
    success: result.success,
    error: result.error,
  }
}

///|
/// Convert PageJobResult to generic JobResult
pub fn PageJobResult::to_builder_result(
  self : PageJobResult,
) -> @builder.JobResult {
  @builder.JobResult::{
    job_id: self.page_index,
    output_path: self.url_path,
    success: self.success,
    error: self.error,
  }
}

///|
/// Serialize PageJobResult to JSON object (for worker to send)
pub fn PageJobResult::to_json(self : PageJobResult) -> @builder.IpcMessage {
  self.to_builder_result().to_json()
}
