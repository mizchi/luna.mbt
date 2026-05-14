///| Route ownership manifest for Sol/host Worker composition.

///|
pub(all) enum RouteManifestMethod {
  Any
  Get
  Post
  Put
  Delete
  Patch
} derive(Eq, Debug)

///|
pub(all) enum RouteManifestOwner {
  SolPage
  SolApi
  Raw
  StaticAsset
  Reserved
} derive(Eq, Debug)

///|
pub(all) enum RouteManifestMatchKind {
  Exact
  Pattern
  Prefix
} derive(Eq, Debug)

///|
pub struct RouteManifestEntry {
  pattern : String
  http_method : RouteManifestMethod
  owner : RouteManifestOwner
  match_kind : RouteManifestMatchKind
  param_names : Array[String]
}

///|
pub struct RouteOwnershipManifest {
  entries : Array[RouteManifestEntry]
}

///|
fn route_manifest_method_to_string(http_method : RouteManifestMethod) -> String {
  match http_method {
    Any => "ANY"
    Get => "GET"
    Post => "POST"
    Put => "PUT"
    Delete => "DELETE"
    Patch => "PATCH"
  }
}

///|
fn route_manifest_owner_to_string(owner : RouteManifestOwner) -> String {
  match owner {
    SolPage => "sol-page"
    SolApi => "sol-api"
    Raw => "raw"
    StaticAsset => "static-asset"
    Reserved => "reserved"
  }
}

///|
fn route_manifest_match_kind_to_string(
  match_kind : RouteManifestMatchKind,
) -> String {
  match match_kind {
    Exact => "exact"
    Pattern => "pattern"
    Prefix => "prefix"
  }
}

///|
pub fn RouteManifestEntry::to_json(self : RouteManifestEntry) -> Json {
  {
    "pattern": self.pattern.to_json(),
    "method": route_manifest_method_to_string(self.http_method).to_json(),
    "owner": route_manifest_owner_to_string(self.owner).to_json(),
    "match": route_manifest_match_kind_to_string(self.match_kind).to_json(),
    "params": self.param_names.to_json(),
  }
}

///|
pub fn RouteOwnershipManifest::to_json(self : RouteOwnershipManifest) -> Json {
  let entries : Array[Json] = []
  for entry in self.entries {
    entries.push(entry.to_json())
  }
  { "routes": entries.to_json() }
}

///|
fn route_manifest_method_to_js_prefix(
  http_method : RouteManifestMethod,
) -> String {
  match http_method {
    Any => "request"
    Get => "get"
    Post => "post"
    Put => "put"
    Delete => "delete"
    Patch => "patch"
  }
}

///|
fn route_manifest_is_separator(c : Char) -> Bool {
  c == '-' || c == '_' || c == '.' || c == ' '
}

///|
fn route_manifest_upper_ascii(c : Char) -> Char {
  if c >= 'a' && c <= 'z' {
    Char::from_int(c.to_int() - 32)
  } else {
    c
  }
}

///|
fn route_manifest_segment_token(segment : String) -> String {
  let raw = if segment.has_prefix("@") {
    segment[1:].to_owned()
  } else {
    segment
  }
  if raw.has_prefix(":") && raw.length() > 1 {
    raw[1:].to_owned()
  } else if raw.has_prefix("[[...") && raw.has_suffix("]]") {
    raw[5:raw.length() - 2].to_owned()
  } else if raw.has_prefix("[...") && raw.has_suffix("]") {
    raw[4:raw.length() - 1].to_owned()
  } else if raw.has_prefix("[") && raw.has_suffix("]") {
    raw[1:raw.length() - 1].to_owned()
  } else {
    raw
  }
}

///|
fn route_manifest_path_to_pascal(path : String) -> String {
  if path == "/" {
    return "Root"
  }
  let buf = StringBuilder::new()
  let mut capitalize_next = true
  let mut wrote = false
  for segment_view in path.split("/") {
    let segment = route_manifest_segment_token(segment_view.to_owned())
    if segment.is_empty() {
      continue
    }
    capitalize_next = true
    for c in segment {
      let is_alpha = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
      let is_digit = c >= '0' && c <= '9'
      if is_alpha || is_digit {
        if capitalize_next {
          buf.write_char(route_manifest_upper_ascii(c))
        } else {
          buf.write_char(c)
        }
        capitalize_next = false
        wrote = true
      } else if route_manifest_is_separator(c) {
        capitalize_next = true
      }
    }
  }
  if wrote { buf.to_string() } else { "Root" }
}

///|
fn route_manifest_api_helper_name(entry : RouteManifestEntry) -> String {
  route_manifest_method_to_js_prefix(entry.http_method) +
  route_manifest_path_to_pascal(entry.pattern)
}

///|
fn route_manifest_param_type(params : Array[String]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{ ")
  for i, param in params {
    if i > 0 {
      buf.write_string("; ")
    }
    buf.write_string(route_manifest_ts_string_literal(param))
    buf.write_string(": string")
  }
  buf.write_string(" }")
  buf.to_string()
}

///|
fn route_manifest_ts_string_literal(value : String) -> String {
  "\"" +
  value
  .replace(old="\\", new="\\\\")
  .replace(old="\"", new="\\\"")
  .replace(old="\n", new="\\n")
  .replace(old="\r", new="\\r")
  .replace(old="\t", new="\\t") +
  "\""
}

///|
fn route_manifest_write_api_helper(
  buf : StringBuilder,
  entry : RouteManifestEntry,
) -> Unit {
  let name = route_manifest_api_helper_name(entry)
  let http_method_string = route_manifest_method_to_string(entry.http_method)
  let path = entry.pattern
  let has_params = !entry.param_names.is_empty()
  let path_expr = if has_params {
    "fillSolApiPath(\{route_manifest_ts_string_literal(path)}, params)"
  } else {
    route_manifest_ts_string_literal(path)
  }
  buf.write_string("  \{name}: ")
  if entry.http_method is Get {
    if has_params {
      buf.write_string(
        "<TResponse = unknown>(params: \{route_manifest_param_type(entry.param_names)}, init?: RequestInit) =>\n",
      )
    } else {
      buf.write_string("<TResponse = unknown>(init?: RequestInit) =>\n")
    }
    buf.write_string(
      "    solApiRequest<TResponse>(\{path_expr}, { ...init, method: \"\{http_method_string}\" }),\n",
    )
  } else {
    if has_params {
      buf.write_string(
        "<TBody = unknown, TResponse = unknown>(params: \{route_manifest_param_type(entry.param_names)}, body: TBody, init?: RequestInit) =>\n",
      )
    } else {
      buf.write_string(
        "<TBody = unknown, TResponse = unknown>(body: TBody, init?: RequestInit) =>\n",
      )
    }
    buf.write_string("    solApiRequest<TResponse>(\{path_expr}, {\n")
    buf.write_string("      ...init,\n")
    buf.write_string("      method: \"\{http_method_string}\",\n")
    buf.write_string("      headers: jsonHeaders(init),\n")
    buf.write_string("      body: JSON.stringify(body),\n")
    buf.write_string("    }),\n")
  }
}

///|
pub fn RouteOwnershipManifest::api_client_manifest_json(
  self : RouteOwnershipManifest,
) -> Json {
  let routes : Array[Json] = []
  for entry in self.entries {
    if entry.owner is SolApi {
      routes.push({
        "name": route_manifest_api_helper_name(entry).to_json(),
        "method": route_manifest_method_to_string(entry.http_method).to_json(),
        "path": entry.pattern.to_json(),
        "params": entry.param_names.to_json(),
      })
    }
  }
  { "apis": routes.to_json() }
}

///|
/// Generate optional TypeScript helpers for Sol JSON API routes.
///
/// The generated helpers carry the stable route path and HTTP method, expose
/// path params where present, and return a typed success/error result shape.
pub fn RouteOwnershipManifest::api_client_typescript(
  self : RouteOwnershipManifest,
) -> String {
  let buf = StringBuilder::new()
  buf.write_string(
    "export type SolApiError = { ok: false; status: number; message: string; response: Response };\n",
  )
  buf.write_string(
    "export type SolApiSuccess<T> = { ok: true; data: T; response: Response };\n",
  )
  buf.write_string(
    "export type SolApiResult<T> = SolApiSuccess<T> | SolApiError;\n\n",
  )
  buf.write_string(
    "function jsonHeaders(init?: RequestInit): Headers {\n  const headers = new Headers(init?.headers);\n  if (!headers.has(\"content-type\")) headers.set(\"content-type\", \"application/json\");\n  return headers;\n}\n\n",
  )
  buf.write_string(
    "function fillSolApiPath(path: string, params: Record<string, string>): string {\n  return path\n    .replace(/:([A-Za-z0-9_]+)/g, (_, key) => encodeURIComponent(params[key] ?? \"\"))\n    .replace(/\\[\\[?\\.\\.\\.([^\\]]+)\\]?\\]/g, (_, key) => encodeURIComponent(params[key] ?? \"\"))\n    .replace(/\\[([^\\]]+)\\]/g, (_, key) => encodeURIComponent(params[key] ?? \"\"));\n}\n\n",
  )
  buf.write_string(
    "async function solApiRequest<T>(path: string, init: RequestInit): Promise<SolApiResult<T>> {\n  const response = await fetch(path, init);\n  const text = await response.text();\n  let data: unknown = null;\n  if (text.length > 0) {\n    try { data = JSON.parse(text); } catch { data = text; }\n  }\n  if (!response.ok) {\n    const message = typeof data === \"object\" && data !== null && \"error\" in data\n      ? String((data as { error?: unknown }).error)\n      : response.statusText;\n    return { ok: false, status: response.status, message, response };\n  }\n  return { ok: true, data: data as T, response };\n}\n\n",
  )
  buf.write_string("export const api = {\n")
  for entry in self.entries {
    if entry.owner is SolApi {
      route_manifest_write_api_helper(buf, entry)
    }
  }
  buf.write_string("} as const;\n")
  buf.to_string()
}

///|
fn push_manifest_entry(
  entries : Array[RouteManifestEntry],
  pattern : String,
  http_method : RouteManifestMethod,
  owner : RouteManifestOwner,
  match_kind : RouteManifestMatchKind,
  param_names : Array[String],
) -> Unit {
  entries.push({ pattern, http_method, owner, match_kind, param_names })
}

///|
fn route_manifest_method_matches(
  entry_method : RouteManifestMethod,
  request_method : RouteManifestMethod,
) -> Bool {
  match entry_method {
    Any => true
    Get => request_method is Get
    Post => request_method is Post
    Put => request_method is Put
    Delete => request_method is Delete
    Patch => request_method is Patch
  }
}

///|
fn route_manifest_method_for_kind(kind : SolRouteKind) -> RouteManifestMethod {
  match kind {
    Page => Get
    GetApi => Get
    PostApi => Post
    PutApi => Put
    DeleteApi => Delete
    PatchApi => Patch
    RawGet => Get
    RawPost => Post
    RawPut => Put
    RawDelete => Delete
    RawPatch => Patch
  }
}

///|
fn route_manifest_owner_for_kind(kind : SolRouteKind) -> RouteManifestOwner {
  match kind {
    Page => SolPage
    GetApi | PostApi | PutApi | DeleteApi | PatchApi => SolApi
    RawGet | RawPost | RawPut | RawDelete | RawPatch => Raw
  }
}

///|
fn route_manifest_match_kind_for_route(
  route : CompiledSolRoute,
) -> RouteManifestMatchKind {
  if !route.param_names.is_empty() || route.catch_all is Some(_) {
    Pattern
  } else {
    Exact
  }
}

///|
fn route_manifest_param_names(route : CompiledSolRoute) -> Array[String] {
  let names = route.param_names.copy()
  match route.catch_all {
    Some(info) => if !names.contains(info.name) { names.push(info.name) }
    None => ()
  }
  names
}

///|
fn is_remote_asset_url(path : String) -> Bool {
  path.has_prefix("http://") ||
  path.has_prefix("https://") ||
  path.has_prefix("//")
}

///|
fn push_asset_manifest_entry(
  entries : Array[RouteManifestEntry],
  path : String,
) -> Unit {
  let url = normalize_asset_url(path)
  if url.is_empty() || is_remote_asset_url(url) {
    return
  }
  for entry in entries {
    if entry.pattern == url &&
      entry.owner is StaticAsset &&
      entry.match_kind is Exact {
      return
    }
  }
  push_manifest_entry(entries, url, Any, StaticAsset, Exact, [])
}

///|
fn add_route_asset_entries(
  entries : Array[RouteManifestEntry],
  route : CompiledSolRoute,
) -> Unit {
  for path in route.styles {
    push_asset_manifest_entry(entries, path)
  }
  for path in route.scripts {
    push_asset_manifest_entry(entries, path)
  }
}

///|
fn add_config_asset_entries(
  entries : Array[RouteManifestEntry],
  config : RouterConfig,
) -> Unit {
  for path in config.styles {
    push_asset_manifest_entry(entries, path)
  }
  for path in config.client_scripts {
    push_asset_manifest_entry(entries, path)
  }
}

///|
fn add_reserved_manifest_entries(entries : Array[RouteManifestEntry]) -> Unit {
  push_manifest_entry(entries, "/_sol/*", Any, Reserved, Prefix, [])
  push_manifest_entry(entries, "/__sol__/*", Any, Reserved, Prefix, [])
  push_manifest_entry(entries, "/_luna/*", Any, Reserved, Prefix, [])
  push_manifest_entry(entries, "/static/*", Any, StaticAsset, Prefix, [])
}

///|
pub fn route_ownership_manifest(
  routes : Array[SolRoutes],
  config? : RouterConfig = RouterConfig::default(),
) -> RouteOwnershipManifest {
  let entries : Array[RouteManifestEntry] = []
  add_reserved_manifest_entries(entries)
  let compiled = compile_sol_routes(routes)
  for route in compiled {
    push_manifest_entry(
      entries,
      route.pattern,
      route_manifest_method_for_kind(route.kind),
      route_manifest_owner_for_kind(route.kind),
      route_manifest_match_kind_for_route(route),
      route_manifest_param_names(route),
    )
    add_route_asset_entries(entries, route)
  }
  add_config_asset_entries(entries, config)
  { entries, }
}

///|
fn route_manifest_path_for_match(path : String) -> String {
  normalize_path(strip_query_string(path))
}

///|
fn route_manifest_prefix_matches(pattern : String, path : String) -> Bool {
  let prefix = if pattern.has_suffix("/*") {
    pattern[:pattern.length() - 2].to_owned()
  } else {
    pattern
  }
  path == prefix || path.has_prefix(prefix + "/")
}

///|
fn is_pattern_param_segment(segment : String) -> Bool {
  if segment.has_prefix(":") && segment.length() > 1 {
    return true
  }
  segment.has_prefix("[") &&
  !segment.has_prefix("[...") &&
  !segment.has_prefix("[[...") &&
  segment.has_suffix("]") &&
  segment.length() > 2
}

///|
fn is_required_catch_all_segment(segment : String) -> Bool {
  segment.has_prefix("[...") && segment.has_suffix("]") && segment.length() > 5
}

///|
fn is_optional_catch_all_segment(segment : String) -> Bool {
  segment.has_prefix("[[...") &&
  segment.has_suffix("]]") &&
  segment.length() > 7
}

///|
fn route_manifest_pattern_matches(pattern : String, path : String) -> Bool {
  let pattern_segments = split_by_char(normalize_path(pattern), '/')
  let path_segments = split_by_char(path, '/')
  let mut pattern_index = 0
  let mut path_index = 0
  while pattern_index < pattern_segments.length() {
    let segment = pattern_segments[pattern_index]
    if is_optional_catch_all_segment(segment) {
      return true
    }
    if is_required_catch_all_segment(segment) {
      return path_index < path_segments.length()
    }
    if path_index >= path_segments.length() {
      return false
    }
    if is_pattern_param_segment(segment) {
      pattern_index += 1
      path_index += 1
      continue
    }
    if segment != path_segments[path_index] {
      return false
    }
    pattern_index += 1
    path_index += 1
  }
  path_index == path_segments.length()
}

///|
fn route_manifest_entry_matches(
  entry : RouteManifestEntry,
  path : String,
  http_method : RouteManifestMethod,
) -> Bool {
  if !route_manifest_method_matches(entry.http_method, http_method) {
    return false
  }
  match entry.match_kind {
    Exact => path == entry.pattern
    Prefix => route_manifest_prefix_matches(entry.pattern, path)
    Pattern => route_manifest_pattern_matches(entry.pattern, path)
  }
}

///|
pub fn RouteOwnershipManifest::match_path(
  self : RouteOwnershipManifest,
  path : String,
  http_method? : RouteManifestMethod = RouteManifestMethod::Get,
) -> RouteManifestEntry? {
  let normalized = route_manifest_path_for_match(path)
  for entry in self.entries {
    if route_manifest_entry_matches(entry, normalized, http_method) {
      return Some(entry)
    }
  }
  None
}
