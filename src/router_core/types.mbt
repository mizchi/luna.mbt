// Portable route parameter and request types.
// These types work on JS, native, and wasm-gc targets.

///|
pub type App = @mars.Server

///|
pub type Ctx = @mars.Context

///|
/// Route parameters extracted from URL
pub struct RouteParams {
  params : Array[(String, String)]
  query : Array[(String, String)]
  path : String
  is_fragment : Bool
}

///|
pub fn RouteParams::empty() -> RouteParams {
  { params: [], query: [], path: "", is_fragment: false }
}

///|
pub fn RouteParams::get_param(self : RouteParams, key : String) -> String? {
  for pair in self.params {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
pub fn RouteParams::get_query(self : RouteParams, key : String) -> String? {
  for pair in self.query {
    if pair.0 == key {
      return Some(pair.1)
    }
  }
  None
}

///|
/// Props passed to page/API handlers
pub struct RequestProps {
  priv ctx : Ctx
  params : RouteParams
  is_fragment : Bool
  is_isr_render : Bool
}

///|
pub fn RequestProps::from_ctx(ctx : Ctx) -> RequestProps {
  { ctx, params: RouteParams::empty(), is_fragment: false, is_isr_render: false }
}

///|
pub fn RequestProps::from_ctx_with_params(
  ctx : Ctx,
  params : RouteParams,
) -> RequestProps {
  { ctx, params, is_fragment: params.is_fragment, is_isr_render: false }
}

///|
pub fn RequestProps::get_param(self : RequestProps, key : String) -> String? {
  self.params.get_param(key)
}

///|
pub fn RequestProps::get_query(self : RequestProps, key : String) -> String? {
  self.params.get_query(key)
}

///|
pub fn RequestProps::path(self : RequestProps) -> String {
  self.params.path
}

///|
pub fn RequestProps::header(self : RequestProps, name : String) -> String? {
  if self.is_isr_render {
    None
  } else {
    self.ctx.header(name)
  }
}

///|
pub fn RequestProps::cookie(self : RequestProps, name : String) -> String? {
  if self.is_isr_render {
    None
  } else {
    self.ctx.cookie(name)
  }
}

///|
pub async fn RequestProps::body_json(self : RequestProps) -> Json? {
  if self.is_isr_render {
    None
  } else {
    self.ctx.body_json()
  }
}

///|
pub fn RequestProps::set_header(
  self : RequestProps,
  name : String,
  value : String,
) -> Unit {
  if not(self.is_isr_render) {
    self.ctx.set_header(name, value)
  }
}

///|
pub fn RequestProps::set_status(self : RequestProps, status : Int) -> Unit {
  if not(self.is_isr_render) {
    self.ctx.set_status(status)
  }
}

///|
pub async fn RequestProps::text(
  self : RequestProps,
  body : String,
  status? : Int,
) -> Unit {
  if not(self.is_isr_render) {
    match status {
      Some(code) => self.ctx.text(body, status=code)
      None => self.ctx.text(body)
    }
  }
}

///|
pub async fn RequestProps::html(
  self : RequestProps,
  body : String,
  status? : Int,
) -> Unit {
  if not(self.is_isr_render) {
    match status {
      Some(code) => self.ctx.html(body, status=code)
      None => self.ctx.html(body)
    }
  }
}
