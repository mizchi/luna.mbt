///| AsyncRouter - Server-side async router with component resolution
///|
///| ServerComponent: サーバーでのみ実行、非同期データ取得可能
///| ClientComponent: Island として埋め込み、クライアントでHydration

///|
/// コンポーネントの種類
pub enum ComponentKind {
  /// サーバーコンポーネント - サーバーでのみ実行
  Server
  /// クライアントコンポーネント - Hydration可能
  Client(url~ : String, trigger~ : @luna.IslandTrigger)
}

///|
/// サーバーサイド非同期ルーター
pub struct AsyncRouter {
  routes : Array[CompiledRoutes]
}

///|
/// AsyncRouter を作成
pub fn AsyncRouter::new(routes : Array[Routes]) -> AsyncRouter {
  { routes: compile(routes) }
}

///|
/// コンパイル済みルートから AsyncRouter を作成
pub fn AsyncRouter::from_compiled(routes : Array[CompiledRoutes]) -> AsyncRouter {
  { routes, }
}

///|
/// URLに対してルートをマッチング
pub fn AsyncRouter::match_url(self : AsyncRouter, url : String) -> RoutesMatch? {
  match_url(url, self.routes)
}

///|
/// コンパイル済みルートを取得
pub fn AsyncRouter::get_routes(self : AsyncRouter) -> Array[CompiledRoutes] {
  self.routes
}

///|
/// ルートをJSON形式でシリアライズ（クライアントに送信用）
pub fn AsyncRouter::to_json(self : AsyncRouter) -> String {
  let sb = StringBuilder::new()
  sb.write_string("[")
  for i, route in self.routes {
    if i > 0 {
      sb.write_string(",")
    }
    sb.write_string("{")
    sb.write_string("\"pattern\":\"")
    sb.write_string(escape_json_string(route.pattern))
    sb.write_string("\",\"component\":\"")
    sb.write_string(escape_json_string(route.component))
    sb.write_string("\",\"params\":[")
    for j, param in route.param_names {
      if j > 0 {
        sb.write_string(",")
      }
      sb.write_string("\"")
      sb.write_string(escape_json_string(param))
      sb.write_string("\"")
    }
    sb.write_string("],\"layouts\":[")
    for j, layout in route.layouts {
      if j > 0 {
        sb.write_string(",")
      }
      sb.write_string("\"")
      sb.write_string(escape_json_string(layout))
      sb.write_string("\"")
    }
    sb.write_string("],\"title\":\"")
    sb.write_string(escape_json_string(route.title))
    sb.write_string("\"}")
  }
  sb.write_string("]")
  sb.to_string()
}

///|
fn escape_json_string(s : String) -> String {
  let chars = s.to_array()
  let result : Array[Char] = []
  for c in chars {
    match c {
      '"' => {
        result.push('\\')
        result.push('"')
      }
      '\\' => {
        result.push('\\')
        result.push('\\')
      }
      '\n' => {
        result.push('\\')
        result.push('n')
      }
      '\r' => {
        result.push('\\')
        result.push('r')
      }
      '\t' => {
        result.push('\\')
        result.push('t')
      }
      _ => result.push(c)
    }
  }
  String::from_array(result)
}
