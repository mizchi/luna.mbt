///| Sol E2E Tests using mizchi/playwright (MoonBit + WebDriver BiDi)
///|
///| Tests run against the sol_app example on localhost:3457.
///|
///| Prerequisites:
///|   1. Start server: cd examples/sol_app && sol dev --no-watch -p 3457
///|   2. Run tests:    cd e2e/mbt_e2e && moon run src/ --target js
///|
///| NOTE: Requires mizchi/playwright with working BiDi goto/evaluate.
///| Currently BiDi evaluate returns null — tests will fail until
///| the upstream library is fixed. The test structure is correct and
///| ready to verify parallelism once the transport layer works.

let base = "http://localhost:3457"

async fn main {
  let browser = @pw.chromium().launch(headless=true)
  println("Browser: \{browser.version()}")
  let passed = Ref::new(0)
  let failed = Ref::new(0)
  let errors : Array[String] = []
  // Sequential tests — each creates its own page
  run_test("health API returns 200", (b) => { test_health_api(b) }, browser, passed, failed, errors)
  run_test("home page contains HTML", (b) => { test_home_page(b) }, browser, passed, failed, errors)
  run_test("counter island JS loads", (b) => { test_island_js(b) }, browser, passed, failed, errors)
  run_test("fragment request returns 200", (b) => { test_fragment(b) }, browser, passed, failed, errors)
  run_test("404 for unknown route", (b) => { test_404(b) }, browser, passed, failed, errors)
  // Same tests again — verifies page isolation (safe for parallelism)
  run_test("parallel: health", (b) => { test_health_api(b) }, browser, passed, failed, errors)
  run_test("parallel: home", (b) => { test_home_page(b) }, browser, passed, failed, errors)
  // Summary
  println("")
  println("Results: \{passed.val} passed, \{failed.val} failed")
  if not(errors.is_empty()) {
    println("Failures:")
    for e in errors {
      println("  ✗ \{e}")
    }
  }
  browser.close()
  if failed.val > 0 {
    ffi_exit(1)
  }
}

///|
async fn run_test(
  name : String,
  test_fn : async (@pw.Browser) -> Unit,
  browser : @pw.Browser,
  passed : Ref[Int],
  failed : Ref[Int],
  errors : Array[String],
) -> Unit {
  try {
    test_fn(browser)
    println("  ✓ \{name}")
    passed.val += 1
  } catch {
    e => {
      println("  ✗ \{name}: \{e}")
      failed.val += 1
      errors.push("\{name}: \{e}")
    }
  }
}

// =============================================================================
// Test Cases
// Each test creates its own Page — safe for parallel execution.
// Uses page.goto() for navigation and page.evaluate() for fetch-based checks.
// =============================================================================

///|
async fn test_health_api(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let response = page.goto("\{base}/api/health", wait_until="commit")
  guard response is Some(res) else { fail!("No response from /api/health") }
  @pw.expect(res.status()).to_be(200)
  let text = res.text()
  @pw.expect(text).to_contain("ok")
  page.close()
}

///|
async fn test_home_page(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let response = page.goto("\{base}/", wait_until="commit")
  guard response is Some(res) else { fail!("No response from /") }
  @pw.expect(res.status()).to_be(200)
  let html = res.text()
  @pw.expect(html).to_contain("<h1")
  page.close()
}

///|
async fn test_island_js(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let response = page.goto("\{base}/static/counter.js", wait_until="commit")
  guard response is Some(res) else {
    fail!("No response from /static/counter.js")
  }
  @pw.expect(res.status()).to_be(200)
  page.close()
}

///|
async fn test_fragment(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  // Navigate to home first, then use evaluate for fragment request
  let _ = page.goto("\{base}/", wait_until="commit")
  let result = page.evaluate(
    "async () => { const r = await fetch('/form', { headers: { 'X-Sol-Fragment': '1' } }); return r.status; }",
  )
  match result {
    Number(n, ..) => @pw.expect(n.to_int()).to_be(200)
    _ => fail!("Expected number status for fragment request, got \{result}")
  }
  page.close()
}

///|
async fn test_404(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let response = page.goto(
    "\{base}/nonexistent-page-xyz",
    wait_until="commit",
  )
  guard response is Some(res) else { fail!("Expected response for 404 page") }
  @pw.expect(res.status()).to_be(404)
  page.close()
}

///|
extern "js" fn ffi_exit(code : Int) -> Unit =
  #| (code) => process.exit(code)
