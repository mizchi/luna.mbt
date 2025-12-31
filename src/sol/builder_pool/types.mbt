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
  // Manual JSON construction for efficiency
  let q = "\""
  "{" +
  q +
  "configJson" +
  q +
  ":" +
  escape_json(self.config_json) +
  "," +
  q +
  "pagesJson" +
  q +
  ":" +
  escape_json(self.pages_json) +
  "," +
  q +
  "sidebarJson" +
  q +
  ":" +
  escape_json(self.sidebar_json) +
  "," +
  q +
  "cwd" +
  q +
  ":" +
  q +
  self.cwd +
  q +
  "}"
}

///|
/// Parse WorkerInitData from JSON object
pub fn WorkerInitData::from_json(obj : @core.Any) -> WorkerInitData? {
  let config_json : String = obj["configJson"].cast()
  let pages_json : String = obj["pagesJson"].cast()
  let sidebar_json : String = obj["sidebarJson"].cast()
  let cwd : String = obj["cwd"].cast()
  Some(WorkerInitData::{ config_json, pages_json, sidebar_json, cwd })
}

///|
fn escape_json(s : String) -> String {
  // Simple JSON string escape - the string itself is JSON so just wrap in quotes
  // For complex strings, proper escaping would be needed
  "\"" +
  s
  .replace(old="\\", new="\\\\")
  .replace(old="\"", new="\\\"")
  .replace(old="\n", new="\\n")
  .replace(old="\r", new="\\r")
  .replace(old="\t", new="\\t") +
  "\""
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
pub fn PageJobResult::to_json(self : PageJobResult) -> @core.Any {
  self.to_builder_result().to_json()
}
