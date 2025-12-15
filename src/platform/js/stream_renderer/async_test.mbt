// Async Exception Handling Tests
// Exploring MoonBit's try-catch expression for error handling patterns.
// MoonBit's try-catch is an expression that returns a value,
// making synchronous error handling natural and composable.
//
// For async rendering, use @luna.vasync() with on_error handler.
// =============================================================================
// Error Types for Async Rendering
// =============================================================================

///|
/// Error type for async data fetching
suberror FetchError {
  NetworkError(String)
  NotFound(String)
  Timeout
}

///|
/// Result type for async operations
pub enum AsyncResult[T] {
  Ok(T)
  Err(FetchError)
  Loading
}

// =============================================================================
// Basic try-catch Expression Tests
// =============================================================================

///|
test "try-catch returns value on success" {
  fn may_fail(succeed : Bool) -> Int raise FetchError {
    if succeed {
      42
    } else {
      raise NetworkError("connection failed")
    }
  }

  let result = may_fail(true) catch { _ => -1 }
  assert_eq(result, 42)
}

///|
test "try-catch returns fallback on error" {
  fn may_fail(succeed : Bool) -> Int raise FetchError {
    if succeed {
      42
    } else {
      raise NetworkError("connection failed")
    }
  }

  let result = may_fail(false) catch {
    NetworkError(_) => -1
    _ => -2
  }
  assert_eq(result, -1)
}

///|
test "try-catch with pattern matching on error type" {
  fn fetch_data(code : Int) -> String raise FetchError {
    match code {
      200 => "success"
      404 => raise NotFound("resource not found")
      500 => raise NetworkError("server error")
      _ => raise Timeout
    }
  }

  let result = fetch_data(404) catch {
    NotFound(msg) => "Not Found: " + msg
    NetworkError(msg) => "Network Error: " + msg
    Timeout => "Request timed out"
  }
  assert_eq(result, "Not Found: resource not found")
}

// =============================================================================
// Async Rendering with try-catch Pattern
// =============================================================================

///|
/// Render a node with error handling - returns error UI on failure
fn render_with_error_boundary(
  fetch : () -> @luna.Node[Unit] raise FetchError,
) -> @luna.Node[Unit] {
  fetch() catch {
    NetworkError(msg) =>
      @luna.h("div", [("class", @luna.attr_static("error network-error"))], [
        @luna.vtext("Network Error: " + msg),
      ])
    NotFound(msg) =>
      @luna.h("div", [("class", @luna.attr_static("error not-found"))], [
        @luna.vtext("Not Found: " + msg),
      ])
    Timeout =>
      @luna.h("div", [("class", @luna.attr_static("error timeout"))], [
        @luna.vtext("Request timed out"),
      ])
  }
}

///|
test "render_with_error_boundary success" {
  let node = render_with_error_boundary(fn() {
    @luna.h("div", [], [@luna.vtext("Success!")])
  })
  let html = @render.render_to_string(node).html
  assert_eq(html, "<div>Success!</div>")
}

///|
test "render_with_error_boundary network error" {
  let node = render_with_error_boundary(fn() {
    raise NetworkError("connection refused")
  })
  let html = @render.render_to_string(node).html
  assert_true(html.contains("Network Error: connection refused"))
  assert_true(html.contains("network-error"))
}

///|
test "render_with_error_boundary not found" {
  let node = render_with_error_boundary(fn() { raise NotFound("/api/user/123") })
  let html = @render.render_to_string(node).html
  assert_true(html.contains("Not Found: /api/user/123"))
  assert_true(html.contains("not-found"))
}

///|
test "render_with_error_boundary timeout" {
  let node = render_with_error_boundary(fn() { raise Timeout })
  let html = @render.render_to_string(node).html
  assert_true(html.contains("Request timed out"))
  assert_true(html.contains("timeout"))
}

// =============================================================================
// Composable Error Boundaries
// =============================================================================

///|
/// Error boundary configuration
pub struct ErrorBoundaryConfig {
  on_network_error : (String) -> @luna.Node[Unit]
  on_not_found : (String) -> @luna.Node[Unit]
  on_timeout : () -> @luna.Node[Unit]
  on_unknown : () -> @luna.Node[Unit]
}

///|
/// Default error boundary configuration
pub fn ErrorBoundaryConfig::default() -> ErrorBoundaryConfig {
  {
    on_network_error: fn(msg) {
      @luna.h("div", [("class", @luna.attr_static("error"))], [
        @luna.vtext("Network Error: " + msg),
      ])
    },
    on_not_found: fn(msg) {
      @luna.h("div", [("class", @luna.attr_static("error"))], [
        @luna.vtext("Not Found: " + msg),
      ])
    },
    on_timeout: fn() {
      @luna.h("div", [("class", @luna.attr_static("error"))], [
        @luna.vtext("Request timed out"),
      ])
    },
    on_unknown: fn() {
      @luna.h("div", [("class", @luna.attr_static("error"))], [
        @luna.vtext("An error occurred"),
      ])
    },
  }
}

///|
/// Render with configurable error boundary
fn render_with_config(
  config : ErrorBoundaryConfig,
  fetch : () -> @luna.Node[Unit] raise FetchError,
) -> @luna.Node[Unit] {
  fetch() catch {
    NetworkError(msg) => (config.on_network_error)(msg)
    NotFound(msg) => (config.on_not_found)(msg)
    Timeout => (config.on_timeout)()
  }
}

///|
test "configurable error boundary" {
  let config : ErrorBoundaryConfig = {
    on_network_error: fn(msg) {
      @luna.h("div", [("class", @luna.attr_static("custom-error"))], [
        @luna.h("h2", [], [@luna.vtext("Oops!")]),
        @luna.h("p", [], [@luna.vtext(msg)]),
      ])
    },
    on_not_found: ErrorBoundaryConfig::default().on_not_found,
    on_timeout: ErrorBoundaryConfig::default().on_timeout,
    on_unknown: ErrorBoundaryConfig::default().on_unknown,
  }
  let node = render_with_config(config, fn() {
    raise NetworkError("server unavailable")
  })
  let html = @render.render_to_string(node).html
  assert_true(html.contains("custom-error"))
  assert_true(html.contains("<h2>Oops!</h2>"))
  assert_true(html.contains("server unavailable"))
}

// =============================================================================
// Result-based Rendering (Alternative to try-catch)
// =============================================================================

///|
/// Render based on AsyncResult state
fn[T] render_async_result(
  result : AsyncResult[T],
  render_ok : (T) -> @luna.Node[Unit],
  render_loading : () -> @luna.Node[Unit],
  render_error : (FetchError) -> @luna.Node[Unit],
) -> @luna.Node[Unit] {
  match result {
    Ok(value) => render_ok(value)
    Loading => render_loading()
    Err(error) => render_error(error)
  }
}

///|
test "render_async_result ok" {
  let result : AsyncResult[String] = Ok("Hello World")
  let node = render_async_result(
    result,
    fn(s) { @luna.h("div", [], [@luna.vtext(s)]) },
    fn() { @luna.h("div", [], [@luna.vtext("Loading...")]) },
    fn(_e) { @luna.h("div", [], [@luna.vtext("Error")]) },
  )
  let html = @render.render_to_string(node).html
  assert_eq(html, "<div>Hello World</div>")
}

///|
test "render_async_result loading" {
  let result : AsyncResult[String] = Loading
  let node = render_async_result(
    result,
    fn(s) { @luna.h("div", [], [@luna.vtext(s)]) },
    fn() {
      @luna.h("div", [("class", @luna.attr_static("spinner"))], [
        @luna.vtext("Loading..."),
      ])
    },
    fn(_e) { @luna.h("div", [], [@luna.vtext("Error")]) },
  )
  let html = @render.render_to_string(node).html
  assert_true(html.contains("spinner"))
  assert_true(html.contains("Loading..."))
}

///|
test "render_async_result error" {
  let result : AsyncResult[String] = Err(Timeout)
  let node = render_async_result(
    result,
    fn(s) { @luna.h("div", [], [@luna.vtext(s)]) },
    fn() { @luna.h("div", [], [@luna.vtext("Loading...")]) },
    fn(e) {
      let msg = match e {
        Timeout => "Timed out"
        _ => "Error"
      }
      @luna.h("div", [("class", @luna.attr_static("error"))], [@luna.vtext(msg)])
    },
  )
  let html = @render.render_to_string(node).html
  assert_true(html.contains("error"))
  assert_true(html.contains("Timed out"))
}

// =============================================================================
// Chained Error Handling
// =============================================================================

///|
/// Chain multiple fallible operations
fn fetch_and_transform(id : Int) -> @luna.Node[Unit] raise FetchError {
  // Simulate fetching
  if id < 0 {
    raise NotFound("Invalid ID: " + id.to_string())
  }
  if id > 100 {
    raise Timeout
  }

  // Simulate transformation
  let data = "User " + id.to_string()

  // Return rendered node
  @luna.h("div", [("class", @luna.attr_static("user-card"))], [
    @luna.h("h2", [], [@luna.vtext(data)]),
    @luna.h("p", [], [@luna.vtext("ID: " + id.to_string())]),
  ])
}

///|
test "chained operations success" {
  let node = fetch_and_transform(42) catch {
    _ => @luna.h("div", [], [@luna.vtext("Error")])
  }
  let html = @render.render_to_string(node).html
  assert_true(html.contains("User 42"))
  assert_true(html.contains("ID: 42"))
}

///|
test "chained operations not found" {
  let node = fetch_and_transform(-1) catch {
    NotFound(msg) =>
      @luna.h("div", [("class", @luna.attr_static("error"))], [
        @luna.vtext("Resource not found: " + msg),
      ])
    _ => @luna.h("div", [], [@luna.vtext("Error")])
  }
  let html = @render.render_to_string(node).html
  assert_true(html.contains("Resource not found"))
  assert_true(html.contains("Invalid ID: -1"))
}

///|
test "chained operations timeout" {
  let node = fetch_and_transform(999) catch {
    Timeout =>
      @luna.h("div", [("class", @luna.attr_static("retry"))], [
        @luna.vtext("Request timed out. "),
        @luna.h("button", [], [@luna.vtext("Retry")]),
      ])
    _ => @luna.h("div", [], [@luna.vtext("Error")])
  }
  let html = @render.render_to_string(node).html
  assert_true(html.contains("retry"))
  assert_true(html.contains("Request timed out"))
  assert_true(html.contains("<button>Retry</button>"))
}

// =============================================================================
// Comparison: try-catch vs VAsync
// =============================================================================

///|
/// Discussion:
///
/// MoonBit's try-catch is an expression, making it natural for synchronous
/// error handling during rendering.
///
/// **try-catch (sync):**
/// - Expression-based: returns a value directly
/// - Pattern matching on error types
/// - No additional runtime overhead
/// - Works with synchronous code naturally
/// - More explicit error handling
///
/// **VAsync (async):**
/// - Streaming HTML output (faster TTFB)
/// - Progressive enhancement with fallback
/// - Parallel async resolution
/// - Better for slow network conditions
/// - Built-in on_error handler
///
/// **Recommendation:**
/// - Use try-catch for: synchronous errors, validation, parsing
/// - Use VAsync for: network requests with loading states, streaming SSR
/// - Combine both: try-catch inside VAsync.render for error handling

///|
test "combined pattern: try-catch for sync error handling" {
  fn create_content_with_fallback(
    fetch : () -> @luna.Node[Unit] raise FetchError,
    fallback : @luna.Node[Unit],
  ) -> @luna.Node[Unit] {
    fetch() catch {
      _ => fallback
    }
  }

  let fallback = @luna.h("div", [("class", @luna.attr_static("skeleton"))], [
    @luna.vtext("Loading..."),
  ])

  // Success case
  let success_node = create_content_with_fallback(
    fn() { @luna.h("div", [], [@luna.vtext("Content loaded!")]) },
    fallback,
  )
  assert_eq(
    @render.render_to_string(success_node).html,
    "<div>Content loaded!</div>",
  )

  // Error case - shows fallback
  let error_node = create_content_with_fallback(
    fn() { raise NetworkError("failed") },
    fallback,
  )
  let html = @render.render_to_string(error_node).html
  assert_true(html.contains("skeleton"))
  assert_true(html.contains("Loading..."))
}
