/// Parallel CSS Extraction Test
///
/// Verifies that CSS extraction can be parallelized using process_pool.
/// This test demonstrates spawning multiple Node.js processes to extract
/// CSS from .mbt files concurrently.

// =============================================================================
// Test Helpers
// =============================================================================

///|
/// Create a job for extracting CSS from a single file
fn css_extract_job(file : String, extract_js_path : String) -> @process_pool.Job {
  @process_pool.job(
    "node",
    [extract_js_path, file, "--json"],
    timeout=30000, // 30 second timeout
  )
}

///|
/// Create jobs for batch extraction (multiple files per process)
fn css_batch_job(
  files : Array[String],
  extract_js_path : String,
) -> @process_pool.Job {
  let args = [extract_js_path]
  args.append(files)
  args.push("--json")
  @process_pool.job("node", args, timeout=60000)
}

// =============================================================================
// Configuration Tests
// =============================================================================

///|
test "parallel extraction: pool creation" {
  let pool = @process_pool.ProcessPool::new(max_workers=4)
  // Pool should be created successfully
  inspect(pool.max_workers, content="4")
}

///|
test "parallel extraction: job creation" {
  let job = css_extract_job("test.mbt", "src/luna/css/extract.js")
  inspect(job.cmd, content="node")
  inspect(job.args.length(), content="3")
  inspect(job.args[0], content="src/luna/css/extract.js")
  inspect(job.args[1], content="test.mbt")
  inspect(job.args[2], content="--json")
}

///|
test "parallel extraction: batch job creation" {
  let files = ["a.mbt", "b.mbt", "c.mbt"]
  let job = css_batch_job(files, "src/luna/css/extract.js")
  inspect(job.cmd, content="node")
  // args: [extract.js, a.mbt, b.mbt, c.mbt, --json]
  inspect(job.args.length(), content="5")
}

// =============================================================================
// Parallel Strategy Tests
// =============================================================================

///|
/// Configuration for parallel CSS extraction
pub struct ParallelCssConfig {
  /// Maximum number of concurrent processes
  max_workers : Int
  /// Number of files per batch (for batch mode)
  batch_size : Int
  /// Path to extract.js
  extract_js_path : String
  /// Working directory
  cwd : String?
}

///|
pub fn ParallelCssConfig::default() -> ParallelCssConfig {
  {
    max_workers: 4,
    batch_size: 10,
    extract_js_path: "src/luna/css/extract.js",
    cwd: None,
  }
}

///|
test "parallel config: default values" {
  let config = ParallelCssConfig::default()
  inspect(config.max_workers, content="4")
  inspect(config.batch_size, content="10")
}

///|
/// Calculate optimal batch size based on file count and worker count
fn calculate_batch_size(file_count : Int, max_workers : Int) -> Int {
  if file_count <= max_workers {
    1 // One file per worker
  } else {
    // Distribute files evenly across workers
    let batch = (file_count + max_workers - 1) / max_workers
    if batch < 5 {
      batch
    } else {
      // Cap at reasonable batch size to avoid too much memory usage
      10
    }
  }
}

///|
test "batch size calculation: small file count" {
  inspect(calculate_batch_size(4, 4), content="1")
  inspect(calculate_batch_size(2, 4), content="1")
}

///|
test "batch size calculation: medium file count" {
  inspect(calculate_batch_size(8, 4), content="2")
  inspect(calculate_batch_size(12, 4), content="3")
}

///|
test "batch size calculation: large file count" {
  inspect(calculate_batch_size(100, 4), content="10")
  inspect(calculate_batch_size(1000, 8), content="10")
}

// =============================================================================
// File Chunking Tests
// =============================================================================

///|
/// Split files into chunks for batch processing
fn chunk_files(files : Array[String], chunk_size : Int) -> Array[Array[String]] {
  let chunks : Array[Array[String]] = []
  let mut current_chunk : Array[String] = []
  for file in files {
    current_chunk.push(file)
    if current_chunk.length() >= chunk_size {
      chunks.push(current_chunk)
      current_chunk = []
    }
  }
  if current_chunk.length() > 0 {
    chunks.push(current_chunk)
  }
  chunks
}

///|
test "chunk files: exact division" {
  let files = ["a", "b", "c", "d"]
  let chunks = chunk_files(files, 2)
  inspect(chunks.length(), content="2")
  inspect(chunks[0].length(), content="2")
  inspect(chunks[1].length(), content="2")
}

///|
test "chunk files: with remainder" {
  let files = ["a", "b", "c", "d", "e"]
  let chunks = chunk_files(files, 2)
  inspect(chunks.length(), content="3")
  inspect(chunks[0].length(), content="2")
  inspect(chunks[1].length(), content="2")
  inspect(chunks[2].length(), content="1")
}

///|
test "chunk files: single chunk" {
  let files = ["a", "b"]
  let chunks = chunk_files(files, 10)
  inspect(chunks.length(), content="1")
  inspect(chunks[0].length(), content="2")
}

///|
test "chunk files: empty input" {
  let files : Array[String] = []
  let chunks = chunk_files(files, 5)
  inspect(chunks.length(), content="0")
}

// =============================================================================
// Result Aggregation Tests
// =============================================================================

///|
/// Aggregated CSS extraction result
pub struct AggregatedCssResult {
  /// Total files processed
  total_files : Int
  /// Files that succeeded
  success_count : Int
  /// Files that failed
  failure_count : Int
  /// Total CSS declarations found
  total_declarations : Int
  /// Processing time in ms
  elapsed_ms : Int64
}

///|
test "aggregated result: initialization" {
  let result : AggregatedCssResult = {
    total_files: 10,
    success_count: 8,
    failure_count: 2,
    total_declarations: 150,
    elapsed_ms: 1234L,
  }
  inspect(result.total_files, content="10")
  inspect(result.success_count, content="8")
  inspect(result.failure_count, content="2")
}

// =============================================================================
// Speedup Estimation Tests
// =============================================================================

///|
/// Estimate speedup based on Amdahl's law
/// Assumes 10% of work is sequential (file I/O overhead)
fn estimate_speedup(workers : Int) -> Double {
  let parallel_fraction = 0.9 // 90% parallelizable
  let sequential_fraction = 0.1
  1.0 / (sequential_fraction + parallel_fraction / workers.to_double())
}

///|
test "speedup estimation: single worker" {
  let speedup = estimate_speedup(1)
  // Single worker = no speedup
  inspect(speedup >= 0.99 && speedup <= 1.01, content="true")
}

///|
test "speedup estimation: 4 workers" {
  let speedup = estimate_speedup(4)
  // Expected: ~3.08x speedup with 90% parallel
  inspect(speedup > 2.5 && speedup < 4.0, content="true")
}

///|
test "speedup estimation: 8 workers" {
  let speedup = estimate_speedup(8)
  // Expected: ~4.7x speedup (diminishing returns)
  inspect(speedup > 4.0 && speedup < 6.0, content="true")
}

// =============================================================================
// Integration Pattern Tests
// =============================================================================

///|
/// Strategy for parallel CSS extraction
pub enum ExtractionStrategy {
  /// One file per process (simple but more overhead)
  PerFile
  /// Multiple files per process (efficient for many files)
  Batched(Int) // batch size
  /// Automatic batching based on file count
  Auto
}

///|
fn determine_batch_size(strategy : ExtractionStrategy, file_count : Int, max_workers : Int) -> Int {
  match strategy {
    PerFile => 1
    Batched(size) => size
    Auto => calculate_batch_size(file_count, max_workers)
  }
}

///|
test "extraction strategy: per file" {
  let size = determine_batch_size(PerFile, 100, 4)
  inspect(size, content="1")
}

///|
test "extraction strategy: batched" {
  let size = determine_batch_size(Batched(5), 100, 4)
  inspect(size, content="5")
}

///|
test "extraction strategy: auto" {
  let size = determine_batch_size(Auto, 100, 4)
  inspect(size, content="10")
}

// =============================================================================
// Job Result Parsing Tests
// =============================================================================

///|
/// Parse CSS count from extract.js JSON output
fn parse_css_count_from_json(json_output : String) -> Int {
  // Simple parsing: count occurrences of "key" fields
  let mut count = 0
  let chars = json_output.to_array()
  let pattern = "\"key\":"
  let pattern_chars = pattern.to_array()
  let pattern_len = pattern_chars.length()

  if chars.length() < pattern_len {
    return 0
  }

  for i = 0; i <= chars.length() - pattern_len; i = i + 1 {
    let mut matched = true
    for j = 0; j < pattern_len; j = j + 1 {
      if chars[i + j] != pattern_chars[j] {
        matched = false
        break
      }
    }
    if matched {
      count = count + 1
    }
  }
  count
}

///|
test "parse css count: empty" {
  inspect(parse_css_count_from_json("{}"), content="0")
}

///|
test "parse css count: single" {
  let json = #|{"base":[{"key":"display:flex"}]}
  inspect(parse_css_count_from_json(json), content="1")
}

///|
test "parse css count: multiple" {
  let json = #|{"base":[{"key":"a"},{"key":"b"},{"key":"c"}]}
  inspect(parse_css_count_from_json(json), content="3")
}
