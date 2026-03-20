///| Sol E2E Tests using mizchi/playwright (MoonBit + WebDriver BiDi)

let base = "http://localhost:3457"

async fn main {
  let browser = @pw.chromium().launch(headless=true)
  println("Browser: \{browser.version()}")
  let passed = Ref::new(0)
  let failed = Ref::new(0)
  let errors : Array[String] = []
  run_test("evaluate expression", (b) => { test_evaluate(b) }, browser, passed, failed, errors)
  run_test("evaluate arrow function", (b) => { test_arrow_fn(b) }, browser, passed, failed, errors)
  run_test("evaluate returns object", (b) => { test_object_return(b) }, browser, passed, failed, errors)
  run_test("goto loads page content", (b) => { test_goto_content(b) }, browser, passed, failed, errors)
  run_test("goto returns response status", (b) => { test_goto_response(b) }, browser, passed, failed, errors)
  run_test("404 response", (b) => { test_404(b) }, browser, passed, failed, errors)
  run_test("parallel: evaluate", (b) => { test_evaluate(b) }, browser, passed, failed, errors)
  run_test("parallel: goto", (b) => { test_goto_content(b) }, browser, passed, failed, errors)
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

///|
async fn test_evaluate(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let r = page.evaluate("1 + 1")
  @pw.expect(r).to_equal(Json::number(2.0))
  page.close()
}

///|
async fn test_arrow_fn(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let r = page.evaluate("() => 42")
  @pw.expect(r).to_equal(Json::number(42.0))
  page.close()
}

///|
async fn test_object_return(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let r = page.evaluate("() => ({ x: 1, msg: 'hello' })")
  match r {
    Object(_) => () // Object returned successfully
    _ => fail("expected Object, got \{r.stringify()}")
  }
  page.close()
}

///|
async fn test_goto_content(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let _ = page.goto("\{base}/")
  let content = page.content()
  @pw.expect(content.length() > 50).to_be_truthy()
  page.close()
}

///|
async fn test_goto_response(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let resp = page.goto("\{base}/api/health")
  match resp {
    Some(r) => @pw.expect(r.status()).to_be(200)
    None => fail("expected response")
  }
  page.close()
}

///|
async fn test_404(browser : @pw.Browser) -> Unit {
  let page = browser.new_page()
  let resp = page.goto("\{base}/nonexistent-xyz")
  match resp {
    Some(r) => @pw.expect(r.status()).to_be(404)
    None => fail("expected 404 response")
  }
  page.close()
}

///|
extern "js" fn ffi_exit(code : Int) -> Unit =
  #| (code) => process.exit(code)
