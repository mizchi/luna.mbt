// Routes Compiler - Compile route definitions to optimized format
//

///|
/// パスを正規化（重複スラッシュ除去、末尾スラッシュ除去）
fn normalize_path(path : String) -> String {
  if path == "" || path == "/" {
    return "/"
  }
  let chars = path.to_array()
  let result : Array[Char] = []
  let mut prev_slash = false
  for c in chars {
    if c == '/' {
      if not(prev_slash) {
        result.push(c)
      }
      prev_slash = true
    } else {
      result.push(c)
      prev_slash = false
    }
  }
  // 末尾スラッシュを除去（ルート以外）
  let len = result.length()
  if len > 1 && result[len - 1] == '/' {
    let _ = result.pop()

  }
  String::from_array(result)
}

///|
/// パスパターンからパラメータ名を抽出
/// 例: "/user/:id/posts/:postId" -> ["id", "postId"]
/// キャッチオールパラメータ ([...slug], [[...slug]]) は含まない
fn extract_param_names(path : String) -> Array[String] {
  let result : Array[String] = []
  let segments = @utils.split_by(path, '/')
  for segment in segments {
    if segment.has_prefix(":") && segment.length() > 1 {
      // ":id" -> "id"
      let name = segment[1:].to_string() catch { _ => continue }
      result.push(name)
    } else if segment.has_prefix("[") &&
      not(segment.has_prefix("[...")) &&
      not(segment.has_prefix("[[...")) {
      // "[id]" -> "id" (Next.js style single param)
      if segment.has_suffix("]") && segment.length() > 2 {
        let name = segment[1:segment.length() - 1].to_string() catch {
          _ => continue
        }
        result.push(name)
      }
    }
    // [...slug] and [[...slug]] are handled separately as catch-all
  }
  result
}

///|
/// パスパターンからキャッチオール情報を抽出
/// 例: "/docs/[...slug]" -> Some({ name: "slug", optional: false })
///     "/docs/[[...slug]]" -> Some({ name: "slug", optional: true })
fn extract_catch_all(path : String) -> CatchAllInfo? {
  let segments = @utils.split_by(path, '/')
  if segments.is_empty() {
    return None
  }
  let last = segments[segments.length() - 1]
  // Optional catch-all: [[...name]]
  if last.has_prefix("[[...") && last.has_suffix("]]") && last.length() > 7 {
    let name = last[5:last.length() - 2].to_string() catch { _ => return None }
    return Some({ name, optional: true })
  }
  // Required catch-all: [...name]
  if last.has_prefix("[...") && last.has_suffix("]") && last.length() > 5 {
    let name = last[4:last.length() - 1].to_string() catch { _ => return None }
    return Some({ name, optional: false })
  }
  None
}

///|
/// Routes を CompiledRoutes にコンパイル
pub fn compile(
  routes : Array[Routes],
  base? : String = "",
) -> Array[CompiledRoutes] {
  let result : Array[CompiledRoutes] = []
  compile_inner(routes, base, [], result)
  result
}

///|
fn compile_inner(
  routes : Array[Routes],
  prefix : String,
  inherited_layouts : Array[String],
  result : Array[CompiledRoutes],
) -> Unit {
  for route in routes {
    match route {
      Page(path~, component~, title~, meta~) => {
        let full_path = normalize_path(prefix + path)
        let param_names = extract_param_names(full_path)
        let catch_all = extract_catch_all(full_path)
        result.push({
          pattern: full_path,
          param_names,
          component,
          layouts: inherited_layouts.copy(),
          kind: Page,
          title,
          meta,
          catch_all,
        })
      }
      Get(path~, handler~) => {
        let full_path = normalize_path(prefix + path)
        let param_names = extract_param_names(full_path)
        let catch_all = extract_catch_all(full_path)
        result.push({
          pattern: full_path,
          param_names,
          component: handler,
          layouts: [],
          kind: GetApi,
          title: "",
          meta: [],
          catch_all,
        })
      }
      Post(path~, handler~) => {
        let full_path = normalize_path(prefix + path)
        let param_names = extract_param_names(full_path)
        let catch_all = extract_catch_all(full_path)
        result.push({
          pattern: full_path,
          param_names,
          component: handler,
          layouts: [],
          kind: PostApi,
          title: "",
          meta: [],
          catch_all,
        })
      }
      Layout(segment~, children~, layout~) => {
        let new_prefix = normalize_path(prefix + segment)
        let new_layouts = inherited_layouts.copy()
        new_layouts.push(layout)
        compile_inner(children, new_prefix, new_layouts, result)
      }
    }
  }
}
