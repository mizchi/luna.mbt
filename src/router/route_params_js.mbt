// JS-specific URLPattern group extraction (requires @url and @js)

///|
/// Get pathname group from URLPatternResult (JS-only)
/// Returns None — URLPatternResult was removed from RouteParams for native compat.
/// Use RouteParams::get_param() instead for portable code.
pub fn RouteParams::get_pathname_group(
  self : RouteParams,
  _name : String,
) -> String? {
  let _ = self
  None
}

///|
/// Get search group from URLPatternResult (JS-only)
/// Returns None — URLPatternResult was removed from RouteParams for native compat.
/// Use RouteParams::get_query() instead for portable code.
pub fn RouteParams::get_search_group(
  self : RouteParams,
  _name : String,
) -> String? {
  let _ = self
  None
}
