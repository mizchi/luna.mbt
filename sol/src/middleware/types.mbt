// Sol Middleware - Simplified middleware system using Mars Handler
//
// Design principles:
// 1. Wraps Mars Handler in a newtype for better API control
// 2. Handler returns Unit; calls ctx.text()/ctx.json() to halt
// 3. Check ctx.is_response_sent() to determine if halted

// ============================================================================
// Type Aliases
// ============================================================================

///|
/// Mars context type alias
pub type Ctx = @mars.Context

///|
/// Middleware type - wraps Mars Handler
/// To halt the pipeline, call ctx.text(), ctx.json(), etc.
/// To continue, simply return without sending response.
pub(all) struct Middleware(@mars.Handler)

// ============================================================================
// Helper Functions
// ============================================================================

///|
/// Check if HTTP method is safe (no side effects)
pub fn is_safe_method(meth : String) -> Bool {
  match meth {
    "GET" | "HEAD" | "OPTIONS" => true
    _ => false
  }
}

///|
/// Get header value from context (case-insensitive)
pub fn get_header(ctx : Ctx, name : String) -> String? {
  ctx.header(name)
}
