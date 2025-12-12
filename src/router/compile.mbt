///| Route Compilation - Convert Route tree to flat list of CompiledRoutes

///|
/// Route 配列をコンパイルしてフラットなリストに変換
pub fn compile_routes(routes : Array[Route]) -> Array[CompiledRoute] {
  let result : Array[CompiledRoute] = []
  compile_routes_inner(routes, "", [], result)
  result
}

///|
fn compile_routes_inner(
  routes : Array[Route],
  prefix : String,
  inherited_params : Array[String],
  result : Array[CompiledRoute],
) -> Unit {
  // 現在のスコープで定義されたパラメータを収集（パス用）
  let current_params = inherited_params.copy()
  // パラメータセグメントをパスに追加するためのプレフィックス
  let mut current_prefix = prefix
  for route in routes {
    match route {
      Param(_, key~, ..) => {
        current_params.push(key)
        // パターンに :key プレースホルダーを追加
        current_prefix = normalize_path(current_prefix + "/:" + key)
      }
      RegexParam(_, key~, ..) => {
        current_params.push(key)
        current_prefix = normalize_path(current_prefix + "/:" + key)
      }
      Wildcard(key~, ..) => {
        current_params.push(key)
        current_prefix = normalize_path(current_prefix + "/*")
      }
      _ => ()
    }
  }
  for route in routes {
    match route {
      Page(path~, title~, meta~) => {
        let full_path = normalize_path(current_prefix + path)
        result.push({
          pattern: full_path,
          param_names: current_params.copy(),
          kind: Page,
          title,
          meta,
        })
      }
      Get(path~, title~, meta~) => {
        let full_path = normalize_path(current_prefix + path)
        result.push({
          pattern: full_path,
          param_names: current_params.copy(),
          kind: GetApi,
          title,
          meta,
        })
      }
      Post(path~, title~, meta~) => {
        let full_path = normalize_path(current_prefix + path)
        result.push({
          pattern: full_path,
          param_names: current_params.copy(),
          kind: PostApi,
          title,
          meta,
        })
      }
      Path(segment, children, ..) => {
        let new_prefix = normalize_path(current_prefix + segment)
        compile_routes_inner(children, new_prefix, current_params, result)
      }
      // Param, RegexParam, Wildcard はパスセグメントとして上で処理済み
      Param(_, ..) | RegexParam(_, ..) | Wildcard(..) => ()
    }
  }
}

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
/// コンパイル済みルートをURLPatternに変換可能な形式で出力
pub fn to_url_pattern(route : CompiledRoute) -> String {
  route.pattern
}
