// Middleware composition operators
//
// Railway Oriented Programming style composition:
// - `then_`: Sequential composition (m1 |> then_(m2))
// - `pipeline`: Compose array of middlewares
// - `or_`: Alternative composition (try m1, if halts try m2)

// ============================================================================
// Middleware Type
// ============================================================================

///|
/// Middleware function type
/// Takes MwContext and returns Flow[MwContext] asynchronously
pub(all) struct Middleware(async (MwContext) -> Flow[MwContext] raise Error)

// ============================================================================
// Sequential Composition
// ============================================================================

///|
/// Sequential composition: run m1, then m2 if m1 continues
/// Usage: m1 |> then_(m2)
pub fn then_(m1 : Middleware, m2 : Middleware) -> Middleware {
  Middleware(async fn(ctx) {
    match (m1.0)(ctx) {
      Continue(ctx2) => (m2.0)(ctx2)
      halt => halt
    }
  })
}

///|
/// Method-style composition: m1.then(m2)
/// Composes two middlewares sequentially (like fish operator >=> in Haskell)
/// Usage: logger().then(cors()).then(auth())
pub fn Middleware::then(self : Middleware, other : Middleware) -> Middleware {
  then_(self, other)
}

///|
/// Compose array of middlewares into single middleware
pub fn pipeline(middlewares : Array[Middleware]) -> Middleware {
  Middleware(async fn(ctx) {
    let mut current = ctx
    for mw in middlewares {
      match (mw.0)(current) {
        Continue(next) => current = next
        halt => return halt
      }
    }
    Continue(current)
  })
}

// ============================================================================
// Alternative Composition
// ============================================================================

///|
/// Alternative composition: if m1 halts, try m2
/// Useful for fallback handlers
pub fn or_(m1 : Middleware, m2 : Middleware) -> Middleware {
  Middleware(async fn(ctx) {
    match (m1.0)(ctx) {
      Halt(_) => (m2.0)(ctx)
      cont => cont
    }
  })
}

// ============================================================================
// Identity and Constant Middlewares
// ============================================================================

///|
/// Identity middleware - passes through unchanged
pub fn identity() -> Middleware {
  Middleware(async fn(ctx) { Continue(ctx) })
}

///|
/// Always halt with given response
pub fn halt(response : MwResponse) -> Middleware {
  Middleware(async fn(_ctx) { Halt(response) })
}

// ============================================================================
// Conditional Composition
// ============================================================================

///|
/// Run middleware only if condition is true
pub fn when(
  condition : (MwContext) -> Bool,
  middleware : Middleware,
) -> Middleware {
  Middleware(async fn(ctx) {
    if condition(ctx) {
      (middleware.0)(ctx)
    } else {
      Continue(ctx)
    }
  })
}

///|
/// Run middleware only if condition is false
pub fn unless(
  condition : (MwContext) -> Bool,
  middleware : Middleware,
) -> Middleware {
  Middleware(async fn(ctx) {
    if not(condition(ctx)) {
      (middleware.0)(ctx)
    } else {
      Continue(ctx)
    }
  })
}

// ============================================================================
// Map and Tap
// ============================================================================

///|
/// Transform context without affecting flow
pub fn map_(f : (MwContext) -> MwContext) -> Middleware {
  Middleware(async fn(ctx) { Continue(f(ctx)) })
}

///|
/// Side effect without affecting context or flow
pub fn tap(f : (MwContext) -> Unit) -> Middleware {
  Middleware(async fn(ctx) {
    f(ctx)
    Continue(ctx)
  })
}

// ============================================================================
// Error Handling
// ============================================================================

///|
/// Catch errors and convert to response
pub fn catch_error(
  middleware : Middleware,
  handler : (Error) -> MwResponse,
) -> Middleware {
  Middleware(async fn(ctx) {
    (middleware.0)(ctx) catch {
      e => Halt(handler(e))
    }
  })
}

///|
/// Catch errors and convert to default error response
pub fn catch_error_default(middleware : Middleware) -> Middleware {
  catch_error(middleware, fn(e) { MwResponse::text(e.to_string(), status=500) })
}

// ============================================================================
// Run Middleware
// ============================================================================

///|
/// Execute middleware and return result
pub async fn run(
  middleware : Middleware,
  ctx : MwContext,
) -> Flow[MwContext] raise Error {
  (middleware.0)(ctx)
}
