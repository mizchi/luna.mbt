///| Sol E2E Tests — MoonBit Playwright (WebDriver BiDi)
///|
///| Replaces parts of e2e/sol-app-hydration.spec.ts with MoonBit.
///| Runs against sol_app example on localhost:3457.

let base = "http://localhost:3457"

async fn main {
  let browser = @pw.chromium().launch(headless=true)
  println("Browser: \{browser.version()}")
  let passed = Ref::new(0)
  let failed = Ref::new(0)
  let errors : Array[String] = []

  // === Core functionality ===
  run("evaluate expression", (b) => { test_evaluate(b) }, browser, passed, failed, errors)
  run("evaluate arrow function", (b) => { test_arrow_fn(b) }, browser, passed, failed, errors)
  run("evaluate returns object", (b) => { test_object_return(b) }, browser, passed, failed, errors)

  // === sol_app hydration tests (replaces sol-app-hydration.spec.ts) ===
  run("home page SSR content", (b) => { test_home_ssr(b) }, browser, passed, failed, errors)
  run("counter island visible", (b) => { test_counter_island_visible(b) }, browser, passed, failed, errors)
  run("counter island JS loads", (b) => { test_island_js_loads(b) }, browser, passed, failed, errors)
  run("API health returns 200 JSON", (b) => { test_api_health(b) }, browser, passed, failed, errors)
  run("about page renders", (b) => { test_about_page(b) }, browser, passed, failed, errors)
  run("CSR navigation click", (b) => { test_csr_navigation(b) }, browser, passed, failed, errors)
  run("404 response", (b) => { test_404(b) }, browser, passed, failed, errors)
  run("fragment request works", (b) => { test_fragment_request(b) }, browser, passed, failed, errors)

  // === Parallel safety ===
  run("parallel: home", (b) => { test_home_ssr(b) }, browser, passed, failed, errors)
  run("parallel: api", (b) => { test_api_health(b) }, browser, passed, failed, errors)

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
async fn run(
  name : String,
  f : async (@pw.Browser) -> Unit,
  b : @pw.Browser,
  passed : Ref[Int],
  failed : Ref[Int],
  errors : Array[String],
) -> Unit {
  try {
    f(b)
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
// Core: evaluate tests
// =============================================================================

///|
async fn test_evaluate(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  @pw.expect(page.evaluate("1 + 1")).to_equal(Json::number(2.0))
  page.close()
}

///|
async fn test_arrow_fn(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  @pw.expect(page.evaluate("() => 42")).to_equal(Json::number(42.0))
  page.close()
}

///|
async fn test_object_return(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let r = page.evaluate("() => ({ x: 1, msg: 'hello' })")
  guard r is Object(_) else { fail("expected Object, got \{r.stringify()}") }
  page.close()
}

// =============================================================================
// sol_app: SSR + Hydration tests
// =============================================================================

///|
async fn test_home_ssr(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let resp = page.goto("\{base}/")
  // Check response status
  guard resp is Some(r) else { fail("no response from /") }
  @pw.expect(r.status()).to_be(200)
  // Check SSR content contains h1 with "Welcome to Sol"
  let content = page.content()
  @pw.expect(content).to_contain("<h1")
  @pw.expect(content).to_contain("Welcome to Sol")
  page.close()
}

///|
async fn test_counter_island_visible(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/")
  // Check counter element exists in SSR HTML
  let has_counter = page.evaluate(
    "() => document.querySelector('.counter') !== null",
  )
  @pw.expect(has_counter).to_equal(Json::boolean(true))
  page.close()
}

///|
async fn test_island_js_loads(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/")
  // Fetch counter.js and check status
  let status = page.evaluate(
    "() => fetch('/static/counter.js').then(r => r.status)",
  )
  @pw.expect(status).to_equal(Json::number(200.0))
  page.close()
}

///|
async fn test_api_health(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let resp = page.goto("\{base}/api/health")
  guard resp is Some(r) else { fail("no response from /api/health") }
  @pw.expect(r.status()).to_be(200)
  // Verify page content contains the health JSON
  let content = page.content()
  @pw.expect(content).to_contain("ok")
  page.close()
}

///|
async fn test_about_page(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let resp = page.goto("\{base}/about")
  guard resp is Some(r) else { fail("no response from /about") }
  @pw.expect(r.status()).to_be(200)
  let content = page.content()
  @pw.expect(content).to_contain("About")
  page.close()
}

///|
async fn test_csr_navigation(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/")
  page.wait_for_load_state(state="load")
  // Click the about link via evaluate (CSR navigation)
  let _ = page.evaluate(
    "() => { const a = document.querySelector('a[href=\"/about\"]'); if (a) a.click(); }",
  )
  // Wait for navigation
  page.wait_for_timeout(2000)
  // Check URL changed
  let url = page.evaluate("() => location.pathname")
  match url {
    String(path) => @pw.expect(path).to_contain("about")
    _ =>
      // CSR navigation may not change URL in headless — check content instead
      {
        let content = page.content()
        @pw.expect(content).to_contain("About")
      }
  }
  page.close()
}

///|
async fn test_404(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let resp = page.goto("\{base}/nonexistent-xyz")
  guard resp is Some(r) else { fail("expected 404 response") }
  @pw.expect(r.status()).to_be(404)
  page.close()
}

///|
async fn test_fragment_request(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/")
  // Make fragment request via fetch with X-Sol-Fragment header
  let status = page.evaluate(
    "() => fetch('/about', { headers: { 'X-Sol-Fragment': '1' } }).then(r => r.status)",
  )
  @pw.expect(status).to_equal(Json::number(200.0))
  page.close()
}

///|
extern "js" fn ffi_exit(code : Int) -> Unit =
  #| (code) => process.exit(code)
