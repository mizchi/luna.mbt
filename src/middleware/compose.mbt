// Middleware composition operators
//
// Simple composition using Mars Handler pattern:
// - Handlers run sequentially
// - If a handler sends a response, subsequent handlers are skipped
// - Use ctx.is_response_sent() to check if halted

// ============================================================================
// Sequential Composition
// ============================================================================

///|
/// Compose array of middlewares into single middleware
/// Runs handlers sequentially, stops if response is sent
pub fn pipeline(middlewares : Array[Middleware]) -> Middleware {
  let handlers : Array[@mars.Handler] = []
  for mw in middlewares {
    let Middleware(handler) = mw
    handlers.push(handler)
  }
  Middleware(@mars.compose(handlers))
}

///|
/// Sequential composition: run m1, then m2 if m1 didn't send response
/// Usage: m1 |> then_(m2)
pub fn then_(m1 : Middleware, m2 : Middleware) -> Middleware {
  pipeline([m1, m2])
}

///|
/// Method-style composition: then(m1, m2)
pub fn then(m1 : Middleware, m2 : Middleware) -> Middleware {
  then_(m1, m2)
}

///|
/// Method-style composition on Middleware type
/// Usage: logger().Middleware::then(cors())
/// Note: Using explicit type to avoid needing mars import in consumer packages
pub fn Middleware::then(self : Middleware, other : Middleware) -> Middleware {
  then_(self, other)
}

// ============================================================================
// Identity Middleware
// ============================================================================

///|
/// Identity middleware - passes through unchanged
pub fn identity() -> Middleware {
  Middleware(@mars.Handler(async fn(_ctx) { () }))
}

// ============================================================================
// Run Middleware
// ============================================================================

///|
/// Execute middleware and check if it halted
/// Returns true if middleware sent a response (halted)
pub async fn run(middleware : Middleware, ctx : Ctx) -> Bool raise Error {
  let Middleware(@mars.Handler(h)) = middleware
  h(ctx)
  ctx.is_response_sent()
}

///|
/// Execute middleware and convert unexpected errors to 500 response.
/// Returns true if middleware halted request handling.
pub async fn run_or_500(
  middleware : Middleware,
  ctx : Ctx,
  message_prefix? : String = "Internal Server Error: ",
) -> Bool {
  run(middleware, ctx) catch {
    e => {
      ctx.text(message_prefix + e.to_string(), status=500)
      true
    }
  }
}
