// Logger Middleware
//
// Logs HTTP requests in various formats.
// Default format: dev (METHOD /path STATUS time)

// ============================================================================
// Logger Configuration
// ============================================================================

///|
/// Log output format
pub enum LogFormat {
  /// Development format: GET /path 200 12ms
  Dev
  /// Combined log format (Apache-style)
  Combined
  /// JSON format for structured logging
  Json
}

///|
/// Logger configuration
pub struct LoggerConfig {
  /// Output format
  format : LogFormat
  /// Skip logging for certain paths
  skip_paths : Array[String]
  /// Log to custom function (default: console.log)
  log_fn : ((String) -> Unit)?
}

///|
/// Default logger configuration
pub fn LoggerConfig::default() -> LoggerConfig {
  { format: LogFormat::Dev, skip_paths: [], log_fn: None }
}

///|
/// Create dev format config
pub fn LoggerConfig::dev() -> LoggerConfig {
  { format: LogFormat::Dev, skip_paths: [], log_fn: None }
}

///|
/// Create combined format config
pub fn LoggerConfig::combined() -> LoggerConfig {
  { format: LogFormat::Combined, skip_paths: [], log_fn: None }
}

///|
/// Create JSON format config
pub fn LoggerConfig::json() -> LoggerConfig {
  { format: LogFormat::Json, skip_paths: [], log_fn: None }
}

///|
/// Set skip paths
pub fn LoggerConfig::with_skip_paths(
  self : LoggerConfig,
  paths : Array[String],
) -> LoggerConfig {
  { ..self, skip_paths: paths }
}

///|
/// Set custom log function
pub fn LoggerConfig::with_log_fn(
  self : LoggerConfig,
  log_fn : (String) -> Unit,
) -> LoggerConfig {
  { ..self, log_fn: Some(log_fn) }
}

// ============================================================================
// Logger Middleware
// ============================================================================

///|
/// Create logger middleware with default config (dev format)
pub fn logger() -> Middleware {
  logger_with_config(LoggerConfig::default())
}

///|
/// Create logger middleware with custom config
pub fn logger_with_config(config : LoggerConfig) -> Middleware {
  match delegate_logger_handler(config) {
    Some(handler) => return Middleware(handler)
    None => ()
  }
  Middleware(
    @mars.Handler(async fn(ctx) {
      let path = ctx.path()

      // Check skip condition
      for skip_path in config.skip_paths {
        if path.has_prefix(skip_path) {
          return // Continue without logging
        }
      }

      // Get current time
      let start_time = now_ms()

      // Format log message
      let message = format_log_message(ctx, start_time, config.format)

      // Output log
      match config.log_fn {
        Some(log_fn) => log_fn(message)
        None => console_log(message)
      }
      // Continue to next handler
    }),
  )
}

///|
fn delegate_logger_handler(config : LoggerConfig) -> @mars.Handler? {
  match config.log_fn {
    Some(_) => None
    None =>
      match config.format {
        LogFormat::Dev => {
          let base_handler = @mars_mw.logger_simple()
          if config.skip_paths.is_empty() {
            Some(base_handler)
          } else {
            Some(
              @mars.Handler(async fn(ctx) {
                let path = ctx.path()
                for skip_path in config.skip_paths {
                  if path.has_prefix(skip_path) {
                    return
                  }
                }
                let @mars.Handler(h) = base_handler
                h(ctx)
              }),
            )
          }
        }
        LogFormat::Combined | LogFormat::Json => None
      }
  }
}

// ============================================================================
// Log Formatting
// ============================================================================

///|
fn format_log_message(
  ctx : Ctx,
  start_time : Float,
  format : LogFormat,
) -> String {
  match format {
    Dev => format_dev(ctx, start_time)
    Combined => format_combined(ctx, start_time)
    Json => format_json(ctx, start_time)
  }
}

///|
/// Dev format: GET /path
fn format_dev(ctx : Ctx, _start_time : Float) -> String {
  let m = ctx.meth().to_string()
  let path = ctx.path()
  "\{m} \{path}"
}

///|
/// Combined format: IP - - [timestamp] "METHOD /path" status size "referer" "user-agent"
fn format_combined(ctx : Ctx, _start_time : Float) -> String {
  let m = ctx.meth().to_string()
  let path = ctx.path()
  let user_agent = ctx.header("User-Agent").unwrap_or("-")
  let referer = ctx.header("Referer").unwrap_or("-")
  let timestamp = get_timestamp()
  "- - - [\{timestamp}] \"\{m} \{path}\" - - \"\{referer}\" \"\{user_agent}\""
}

///|
/// JSON format: {"method": "GET", "path": "/", "timestamp": "..."}
fn format_json(ctx : Ctx, _start_time : Float) -> String {
  let m = ctx.meth().to_string()
  let path = ctx.path()
  let timestamp = get_timestamp()
  "{\"method\":\"\{m}\",\"path\":\"\{path}\",\"timestamp\":\"\{timestamp}\"}"
}

// ============================================================================
// FFI Helpers
// ============================================================================

///|
extern "js" fn now_ms() -> Float =
  #| () => Date.now()

///|
extern "js" fn get_timestamp() -> String =
  #| () => new Date().toISOString()

///|
extern "js" fn console_log(message : String) -> Unit =
  #| (msg) => console.log(msg)
