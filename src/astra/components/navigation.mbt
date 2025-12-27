// Astra Components - Navigation (Breadcrumb, Prev/Next)
// In-page navigation components

///|
/// Slice string from start to end
fn bc_slice(s : String, start : Int, end : Int) -> String {
  let arr = s.to_array()
  let chars : Array[Char] = []
  for i = start; i < end && i < arr.length(); i = i + 1 {
    chars.push(arr[i])
  }
  String::from_array(chars)
}

///|
/// Slice string from start to end
fn bc_slice_from(s : String, start : Int) -> String {
  let arr = s.to_array()
  let chars : Array[Char] = []
  for i = start; i < arr.length(); i = i + 1 {
    chars.push(arr[i])
  }
  String::from_array(chars)
}

///|
/// Find page title by URL path
fn find_page_title(
  pages : Array[@astra.PageMeta],
  url_path : String,
  locale : String,
) -> String? {
  for page in pages {
    if page.url_path == url_path && page.locale == locale {
      return page.frontmatter.title
    }
  }
  None
}

///|
/// Capitalize first letter
fn capitalize(s : String) -> String {
  if s.is_empty() {
    return s
  }
  let chars = s.to_array()
  let first = chars[0]
  if first >= 'a' && first <= 'z' {
    chars[0] = Int::unsafe_to_char(first.to_int() - 32)
  }
  String::from_array(chars)
}

///|
/// Capitalize segment for display (remove numbers prefix, replace dashes)
fn capitalize_segment(segment : String) -> String {
  // Remove leading number prefix (e.g., "01_" or "01-")
  let mut s = segment
  let chars = s.to_array()
  let mut skip = 0
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] >= '0' && chars[i] <= '9' {
      skip = i + 1
    } else if (chars[i] == '_' || chars[i] == '-') && skip == i {
      skip = i + 1
      break
    } else {
      break
    }
  }
  if skip > 0 && skip < chars.length() {
    s = bc_slice_from(s, skip)
  }

  // Replace dashes/underscores with spaces and capitalize
  let result = s.replace(old="-", new=" ").replace(old="_", new=" ")
  capitalize(result)
}

///|
/// Build breadcrumb navigation
pub fn build_breadcrumb(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
) -> @luna.Node[Unit] {
  // Parse URL path into segments
  let path = page.url_path.trim_start(chars="/").trim_end(chars="/").to_string()
  if path.is_empty() {
    return empty()
  }

  // Split path into segments
  let segments : Array[String] = []
  let chars = path.to_array()
  let mut start = 0
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '/' {
      if i > start {
        segments.push(bc_slice(path, start, i))
      }
      start = i + 1
    }
  }
  if start < chars.length() {
    segments.push(bc_slice_from(path, start))
  }
  if segments.is_empty() {
    return empty()
  }

  // Build breadcrumb items
  let items : Array[@luna.Node[Unit]] = []
  let mut current_path = ""
  for i = 0; i < segments.length(); i = i + 1 {
    let segment = segments[i]
    current_path = current_path + "/" + segment

    // Find page title for this path
    let title = find_page_title(ctx.pages, current_path + "/", page.locale).unwrap_or(
      capitalize_segment(segment),
    )

    // Add separator (except for first item)
    if i > 0 {
      items.push(
        h("span", [attr("class", "breadcrumb-separator")], [@luna.text("/")]),
      )
    }

    // Last item is current page (no link)
    if i == segments.length() - 1 {
      items.push(
        h("span", [attr("class", "breadcrumb-current")], [@luna.text(title)]),
      )
    } else {
      items.push(
        h(
          "a",
          [attr("href", current_path + "/"), attr("class", "breadcrumb-link")],
          [@luna.text(title)],
        ),
      )
    }
  }
  h("nav", [attr("class", "breadcrumb")], items)
}

///|
/// Build prev/next navigation
pub fn build_prev_next(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
) -> @luna.Node[Unit] {
  let prev = @routes.find_prev_page(ctx.pages, page.url_path)
  let next = @routes.find_next_page(ctx.pages, page.url_path)
  let children : Array[@luna.Node[Unit]] = []
  if prev is Some(link) {
    children.push(
      h("a", [attr("href", link.link), attr("class", "prev-link")], [
        h("span", [attr("class", "label")], [@luna.text("Previous")]),
        h("span", [attr("class", "title")], [@luna.text(link.text)]),
      ]),
    )
  }
  if next is Some(link) {
    children.push(
      h("a", [attr("href", link.link), attr("class", "next-link")], [
        h("span", [attr("class", "label")], [@luna.text("Next")]),
        h("span", [attr("class", "title")], [@luna.text(link.text)]),
      ]),
    )
  }
  h("nav", [attr("class", "prev-next")], children)
}
