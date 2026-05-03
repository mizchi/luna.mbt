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

      // Format log message
      let message = format_log_message(ctx, config.format)

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
fn format_log_message(ctx : Ctx, format : LogFormat) -> String {
  let method = ctx.meth().to_string()
  let path = ctx.path()
  match format {
    Dev => format_dev_pure(method, path)
    Combined => {
      let user_agent = ctx.header("User-Agent").unwrap_or("-")
      let referer = ctx.header("Referer").unwrap_or("-")
      let timestamp = get_timestamp()
      format_combined_pure(method, path, user_agent, referer, timestamp)
    }
    Json => {
      let timestamp = get_timestamp()
      format_json_pure(method, path, timestamp)
    }
  }
}

///|
/// Dev format: GET /path (pure, no IO)
fn format_dev_pure(method : String, path : String) -> String {
  "\{method} \{path}"
}

///|
/// Combined format (pure, no IO)
fn format_combined_pure(
  method : String,
  path : String,
  user_agent : String,
  referer : String,
  timestamp : String,
) -> String {
  "- - - [\{timestamp}] \"\{method} \{path}\" - - \"\{referer}\" \"\{user_agent}\""
}

///|
/// JSON format (pure, no IO)
fn format_json_pure(
  method : String,
  path : String,
  timestamp : String,
) -> String {
  let json : Json = {
    "method": method.to_json(),
    "path": path.to_json(),
    "timestamp": timestamp.to_json(),
  }
  json.stringify()
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
