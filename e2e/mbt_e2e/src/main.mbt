let base = "http://localhost:3457"

async fn main {
  println("Launching browser via chromium-bidi...")
  let browser = @pw.chromium().launch(headless=true)
  println("Browser: " + browser.version())
  let page = browser.new_page()
  println("Page URL: " + page.url())
  // Use expression (not arrow function) for script.evaluate
  let r = page.evaluate("1 + 1")
  println("1+1 = " + r.stringify())
  // goto
  let resp = page.goto("\{base}/api/health")
  match resp {
    Some(re) => println("goto: status=" + re.status().to_string() + " url=" + re.url())
    None => println("goto: None")
  }
  // content after goto
  let content = page.content()
  println("content length: " + content.length().to_string())
  println("content preview: " + content)
  // title
  let title = page.title()
  println("title: [" + title + "]")
  page.close()
  browser.close()
  println("Done!")
}
