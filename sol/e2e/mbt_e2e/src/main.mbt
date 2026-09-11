///| Sol E2E Tests — MoonBit Playwright (WebDriver BiDi)

///|

///| Replaces parts of e2e/sol-app-hydration.spec.ts with MoonBit.

///|
/// The Playwright fixture supplies the server and owns the browser process.
let base : String = ffi_env("SOL_E2E_BASE_URL")

///|
extern "js" fn ffi_env(name : String) -> String =
  #| (name) => {
  #|   const value = process.env[name];
  #|   if (!value) throw new Error(`Missing ${name}; run just test-mbt-e2e from sol/`);
  #|   return value;
  #| }

///|
/// Per-test timeout (ms)
let test_timeout = 15000

///|
/// Total suite timeout (ms)
let suite_timeout = 300000

///|
async fn main {
  // The parent fixture also enforces a timeout and closes its owned browser.
  match @async.with_timeout_opt(suite_timeout, run_suite) {
    Some(_) => ()
    None => {
      println("\n✗ SUITE TIMEOUT (\{suite_timeout}ms) — aborting")
      ffi_exit(2)
    }
  }
}

///|
async fn run_suite() -> Unit {
  let browser = @pw.chromium().connect(ffi_env("SOL_E2E_BIDI_URL"))
  println("Browser: \{browser.version()}")
  let passed = Ref(0)
  let failed = Ref(0)
  let errors : Array[String] = []

  // === Core functionality ===
  run(
    "evaluate expression",
    b => test_evaluate(b),
    browser,
    passed,
    failed,
    errors,
  )
  run(
    "evaluate arrow function",
    b => test_arrow_fn(b),
    browser,
    passed,
    failed,
    errors,
  )
  run(
    "evaluate returns object",
    b => test_object_return(b),
    browser,
    passed,
    failed,
    errors,
  )

  // === sol_app hydration tests (replaces sol-app-hydration.spec.ts) ===
  run(
    "home page SSR content",
    b => test_home_ssr(b),
    browser,
    passed,
    failed,
    errors,
  )
  run(
    "counter island visible",
    b => test_counter_island_visible(b),
    browser,
    passed,
    failed,
    errors,
  )
  run(
    "counter island JS loads",
    b => test_island_js_loads(b),
    browser,
    passed,
    failed,
    errors,
  )
  run(
    "API health returns 200 JSON",
    b => test_api_health(b),
    browser,
    passed,
    failed,
    errors,
  )
  run(
    "about page renders",
    b => test_about_page(b),
    browser,
    passed,
    failed,
    errors,
  )
  run(
    "CSR navigation click",
    b => test_csr_navigation(b),
    browser,
    passed,
    failed,
    errors,
  )
  run("404 response", b => test_404(b), browser, passed, failed, errors)
  run(
    "fragment request works",
    b => test_fragment_request(b),
    browser,
    passed,
    failed,
    errors,
  )

  // === Hydration error detection (replaces TS console event tests) ===
  run(
    "no hydration errors on home",
    b => test_no_hydration_errors(b, "/"),
    browser,
    passed,
    failed,
    errors,
  )
  run(
    "no hydration errors on about",
    b => test_no_hydration_errors(b, "/about"),
    browser,
    passed,
    failed,
    errors,
  )
  run(
    "no WC counter errors",
    b => test_no_wc_errors(b),
    browser,
    passed,
    failed,
    errors,
  )

  // === Interaction + fetch helpers ===
  run(
    "counter click increments",
    b => test_counter_click(b),
    browser,
    passed,
    failed,
    errors,
  )
  run(
    "fetch_json API health",
    b => test_fetch_json(b),
    browser,
    passed,
    failed,
    errors,
  )
  run(
    "fetch_json POST action",
    b => test_fetch_post(b),
    browser,
    passed,
    failed,
    errors,
  )

  // === Navigation ===
  run(
    "navigate all pages",
    b => test_navigate_all(b),
    browser,
    passed,
    failed,
    errors,
  )

  // === Admin layout ===
  run(
    "admin nested layout",
    b => test_admin_layout(b),
    browser,
    passed,
    failed,
    errors,
  )
  run(
    "admin CSR navigation",
    b => test_admin_csr_nav(b),
    browser,
    passed,
    failed,
    errors,
  )

  // === WC Counter (shadow DOM) ===
  run(
    "WC counter direct load",
    b => test_wc_counter_direct(b),
    browser,
    passed,
    failed,
    errors,
  )

  // === Form ===
  run(
    "form fill + two-way binding",
    b => test_form_binding(b),
    browser,
    passed,
    failed,
    errors,
  )
  run(
    "form submit via fetch",
    b => test_form_submit(b),
    browser,
    passed,
    failed,
    errors,
  )
  run(
    "form re-hydration",
    b => test_form_rehydration(b),
    browser,
    passed,
    failed,
    errors,
  )

  // === Re-hydration ===
  run(
    "counter A→B→A re-hydration",
    b => test_counter_rehydration(b),
    browser,
    passed,
    failed,
    errors,
  )
  run(
    "multiple round trips",
    b => test_round_trips(b),
    browser,
    passed,
    failed,
    errors,
  )

  // === Parallel safety ===
  run("parallel: home", b => test_home_ssr(b), browser, passed, failed, errors)
  run("parallel: api", b => test_api_health(b), browser, passed, failed, errors)

  println("")
  println("Results: \{passed.val} passed, \{failed.val} failed")
  if !errors.is_empty() {
    println("Failures:")
    for e in errors {
      println("  ✗ \{e}")
    }
  }
  browser.close()
  // Report suite failures through the process status to the parent fixture.
  ffi_exit(if failed.val > 0 { 1 } else { 0 })
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
    match @async.with_timeout_opt(test_timeout, async fn() { f(b) }) {
      Some(_) => {
        println("  ✓ \{name}")
        passed.val += 1
      }
      None => {
        println("  ✗ \{name}: TIMEOUT (\{test_timeout}ms)")
        failed.val += 1
        errors.push("\{name}: TIMEOUT (\{test_timeout}ms)")
      }
    }
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
  assert_eq(page.evaluate("1 + 1"), Json::number(2.0))
  page.close()
}

///|
async fn test_arrow_fn(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  assert_eq(page.evaluate("() => 42"), Json::number(42.0))
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
async fn wait_hydrated(page : @pw.Page) -> Unit {
  let _ = page.wait_for_function(
    "() => Array.from(document.querySelectorAll('*')).filter(el => el.hasAttribute('luna:wc-url')).every(el => el.hasAttribute('data-sol-hydrated'))",
  )
}

///|
async fn navigate(page : @pw.Page, path : String) -> Unit {
  page.locator("nav a[href=\"\{path}\"]").first().click()
  let _ = page.wait_for_function(
    "() => location.pathname === " + Json::string(path).stringify(),
  )
  wait_hydrated(page)
}

///|
async fn increment_counter(
  page : @pw.Page,
  host? : String = "luna-counter",
) -> Unit {
  wait_hydrated(page)
  let root = "document.querySelector(" +
    Json::string(host).stringify() +
    ").shadowRoot"
  let read_count = "Number(" +
    root +
    ".querySelector('.count-display').textContent)"
  let initial = match page.evaluate("() => " + read_count) {
    Number(n, ..) => n.to_int()
    _ => fail("expected a numeric counter value")
  }
  let _ = page.evaluate(
    "() => " + root + ".querySelector('button.inc').click()",
  )
  let _ = page.wait_for_function(
    "() => " + read_count + " === " + (initial + 1).to_string(),
  )
}

///|
async fn fill_form(page : @pw.Page, name : String, email : String) -> Unit {
  wait_hydrated(page)
  let _ = page.evaluate(
    "() => { const root = document.querySelector('contact-form').shadowRoot; " +
    "const values = { name: " +
    Json::string(name).stringify() +
    ", email: " +
    Json::string(email).stringify() +
    " }; " +
    "for (const [key, value] of Object.entries(values)) { const el = root.querySelector('#' + key); el.value = value; el.dispatchEvent(new Event('input', { bubbles: true, composed: true })); } }",
  )
  let _ = page.wait_for_function(
    "() => document.querySelector('contact-form').shadowRoot.querySelector('.preview-name').textContent === " +
    Json::string(name).stringify(),
  )
}

///|
async fn test_counter_island_visible(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/")
  let _ = page.wait_for_function(
    "() => !!document.querySelector('luna-counter')?.shadowRoot?.querySelector('.counter')",
  )
  @pw.expect(page.shadow_text("luna-counter", ".count-display").length() > 0).to_be_truthy()
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
  assert_eq(status, Json::number(200.0))
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
  navigate(page, "/about")
  @pw.expect(page.wait_for_content("About")).to_be_truthy()
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
  assert_eq(status, Json::number(200.0))
  page.close()
}

// =============================================================================
// Hydration error detection
// =============================================================================

///|
async fn test_no_hydration_errors(browser : @pw.Browser, path : String) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}\{path}")
  // Wait for hydration to complete
  wait_hydrated(page)
  // Check console errors for hydration failures
  let errors = page.console_errors()
  let hydration_errors = errors.filter(fn(m) {
    m.text.contains("[sol] Hydration failed")
  })
  @pw.expect(hydration_errors.length()).to_be(0)
  page.close()
}

///|
async fn test_no_wc_errors(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/")
  wait_hydrated(page)
  let errors = page.console_errors()
  let wc_errors = errors.filter(fn(m) {
    m.text.contains("WcCounterProps") || m.text.contains("wc_counter")
  })
  @pw.expect(wc_errors.length()).to_be(0)
  page.close()
}

// =============================================================================
// Interaction + fetch helper tests
// =============================================================================

///|
async fn test_counter_click(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/")
  increment_counter(page)
  page.close()
}

///|
async fn test_fetch_json(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/")
  let (status, json) = page.fetch_json("\{base}/api/health")
  @pw.expect(status).to_be(200)
  match json {
    Object(m) =>
      match m.get("status") {
        Some(String(s)) => @pw.expect(s).to_be("ok")
        _ => fail("expected status field")
      }
    _ => fail("expected JSON object")
  }
  page.close()
}

///|
async fn test_fetch_post(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/")
  let (status, json) = page.fetch_json(
    "\{base}/_action/submit-contact",
    http_method="POST",
    body="{\"name\":\"Test\",\"email\":\"test@example.com\"}",
    headers=[("Content-Type", "application/json"), ("Origin", "\{base}")],
  )
  @pw.expect(status).to_be(200)
  match json {
    Object(m) =>
      match m.get("success") {
        Some(True) => ()
        _ => fail("expected success:true")
      }
    _ => fail("expected JSON object from action")
  }
  page.close()
}

// =============================================================================
// Navigation tests
// =============================================================================

///|
async fn test_navigate_all(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/")
  for path in ["/about", "/form", "/wc-counter", "/"] {
    navigate(page, path)
    assert_eq(page.evaluate("() => location.pathname"), Json::string(path))
  }
  page.close()
}

// =============================================================================
// Admin layout tests
// =============================================================================

///|
async fn test_admin_layout(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/admin")
  let content = page.content()
  @pw.expect(content).to_contain("admin-sidebar")
  @pw.expect(content).to_contain("Admin Dashboard")
  page.close()
}

///|
async fn test_admin_csr_nav(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/admin")
  // Admin → Settings (via evaluate click + wait_for_content)
  let _ = page.evaluate(
    "() => document.querySelector('.admin-sidebar a[href=\"/admin/settings\"]')?.click()",
  )
  @pw.expect(page.wait_for_content("Settings")).to_be_truthy()
  @pw.expect(page.content()).to_contain("admin-sidebar")
  // Settings → Users
  let _ = page.evaluate(
    "() => document.querySelector('.admin-sidebar a[href=\"/admin/users\"]')?.click()",
  )
  @pw.expect(page.wait_for_content("User Management")).to_be_truthy()
  page.close()
}

// =============================================================================
// Form tests
// =============================================================================

///|
async fn test_form_binding(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/form")
  fill_form(page, "Test User", "test@example.com")
  page.close()
}

///|
async fn test_form_submit(browser : @pw.Browser) -> Unit {
  // Submit via fetch_json (bypass hydration requirement for form submit handler)
  let page = browser.new_page()
  let _ = page.goto("\{base}/form")
  let (status, json) = page.fetch_json(
    "\{base}/_action/submit-contact",
    http_method="POST",
    body="{\"name\":\"Submit User\",\"email\":\"submit@example.com\"}",
    headers=[("Content-Type", "application/json"), ("Origin", "\{base}")],
  )
  @pw.expect(status).to_be(200)
  match json {
    Object(m) =>
      match m.get("success") {
        Some(True) => ()
        _ => fail("expected success:true")
      }
    _ => fail("expected JSON")
  }
  page.close()
}

// =============================================================================
// WC Counter tests
// =============================================================================

///|
async fn test_wc_counter_direct(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/wc-counter")
  increment_counter(page, host="wc-counter")
  page.close()
}

// =============================================================================
// Re-hydration tests
// =============================================================================

///|
async fn test_counter_rehydration(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/")
  increment_counter(page)
  navigate(page, "/about")
  navigate(page, "/")
  increment_counter(page)
  page.close()
}

///|
async fn test_form_rehydration(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/form")
  fill_form(page, "Original", "original@example.com")
  navigate(page, "/about")
  navigate(page, "/form")
  fill_form(page, "New Name", "new@example.com")
  page.close()
}

///|
async fn test_round_trips(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/")
  for path in ["/about", "/form"] {
    navigate(page, path)
    navigate(page, "/")
    increment_counter(page)
  }
  page.close()
}

///|
extern "js" fn ffi_exit(code : Int) -> Unit =
  #| (code) => process.exit(code)
