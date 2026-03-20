async fn main {
  println("Launching browser via playwright-core...")
  let browser = @pw.chromium().launch(headless=true)
  println("Browser: " + browser.version())
  let page = browser.new_page()
  println("Page created")
  let resp = page.goto("https://example.com")
  match resp {
    Some(r) => println("goto: status=" + r.status().to_string() + " url=" + r.url())
    None => println("goto: None")
  }
  let title = page.title()
  println("title: " + title)
  let result = page.evaluate("() => ({ x: 1, msg: 'hello' })")
  println("evaluate: " + result.stringify())
  page.close()
  browser.close()
  println("Done!")
}
