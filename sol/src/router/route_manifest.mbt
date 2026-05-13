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
