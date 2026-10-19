// Server Action Client
//
// Client-side utilities for invoking server actions.
// This module provides type-safe action invocation from the browser.

// ============================================================================
// Action Client Types
// ============================================================================

///|
/// Action invocation options
pub struct ActionOptions {
  /// Custom headers to send with the request
  headers : Array[(String, String)]
  /// Request timeout in milliseconds
  timeout : Int32?
  /// Abort signal (for cancellation)
  signal : @js_async.AbortSignal?
}

///|
/// Default action options
pub fn ActionOptions::default() -> ActionOptions {
  { headers: [], timeout: None, signal: None, }
}

///|
/// Action client response
priv enum ActionResponse {
  /// Successful response with data
  Success(@js.Any)
  /// Server requested a redirect
  Redirect(String)
  /// Error response
  Error(Int32, String)
  /// Network error (including cancellation)
  NetworkError(String)
  DecodeError(String)
}

///|
/// Typed action client response.
pub enum TypedActionResponse[Res] {
  /// Successful response decoded into the generated response payload type
  Success(Res)
  /// Server requested a redirect
  Redirect(String)
  /// Error response
  Error(Int32, String)
  /// Network error
  NetworkError(String)
  /// Successful HTTP response whose JSON shape did not match `Res`
  DecodeError(String)
}

///|
/// Decode an untyped action response into a typed action response.
fn[Res : FromJson] TypedActionResponse::from_action_response(
  response : ActionResponse,
) -> TypedActionResponse[Res] {
  match response {
    ActionResponse::Success(data) => {
      guard @js_any.any_to_json(data) is Some(json) else {
        return TypedActionResponse::DecodeError("Action response is not JSON")
      }
      let decoded : Res = @json.from_json(json) catch {
        _ =>
          return TypedActionResponse::DecodeError(
            "Action response does not match expected type",
          )
      }
      TypedActionResponse::Success(decoded)
    }
    ActionResponse::Redirect(url) => TypedActionResponse::Redirect(url)
    ActionResponse::Error(status, message) =>
      TypedActionResponse::Error(status, message)
    ActionResponse::NetworkError(message) =>
      TypedActionResponse::NetworkError(message)
    ActionResponse::DecodeError(message) =>
      TypedActionResponse::DecodeError(message)
  }
}

///|
/// UI-facing action phase for common form/action states
pub enum ActionPhase {
  Idle
  Pending
  Succeeded
  Failed
  Redirecting
} derive(Eq, Debug)

///|
pub extend ActionPhase with @debug.Debug::{to_repr}

///|
pub extend ActionPhase with Eq::{not_equal, equal}

///|
/// UI-facing action state for pending/error/success controls
pub struct ActionState {
  phase : ActionPhase
  status : Int32?
  message : String?
  redirect : String?
}

///|
/// Initial idle action state
pub fn ActionState::idle() -> ActionState {
  { phase: Idle, status: None, message: None, redirect: None, }
}

///|
/// Pending action state
pub fn ActionState::pending(message~ : String = "Pending") -> ActionState {
  { phase: Pending, status: None, message: Some(message), redirect: None, }
}

///|
/// Successful action state
pub fn ActionState::success(message~ : String = "Success") -> ActionState {
  { phase: Succeeded, status: None, message: Some(message), redirect: None, }
}

///|
/// Failed action state
pub fn ActionState::error(status~ : Int32, message~ : String) -> ActionState {
  {
    phase: Failed,
    status: Some(status),
    message: Some(message),
    redirect: None,
  }
}

///|
/// Redirecting action state
pub fn ActionState::redirect(url : String) -> ActionState {
  {
    phase: Redirecting,
    status: None,
    message: Some("Redirecting"),
    redirect: Some(url),
  }
}

// ============================================================================
// Action Invocation
// ============================================================================

///|
/// Invoke a server action with callback
/// - `url`: The action endpoint URL (e.g., "/_action/create-user")
/// - `payload`: The JSON payload to send
/// - `callback`: Function to call with the response
/// - `options`: Optional configuration
fn invoke_action(
  url : String,
  payload : @js.Any,
  callback : (ActionResponse) -> Unit,
  options? : ActionOptions,
  http_method~ : String = "POST",
) -> Unit {
  let opts = options.unwrap_or(ActionOptions::default())
  request_action(url, payload, http_method, callback, opts)
}

///|
/// Invoke a typed server action using its generated request payload type.
pub fn[Req : ToJson, Res : FromJson] invoke_typed_action_key(
  key : TypedActionKey[Req, Res],
  payload : Req,
  callback : (TypedActionResponse[Res]) -> Unit,
  options? : ActionOptions,
) -> Unit {
  invoke_action(
    typed_action_url(key),
    @js_any.json_to_any(payload.to_json()),
    fn(response) {
      callback(TypedActionResponse::from_action_response(response))
    },
    options?,
  )
}

///|
/// Create an action invoker whose payload parameter is tied to a typed key.
pub fn[Req : ToJson, Res : FromJson] create_typed_action_invoker_key(
  key : TypedActionKey[Req, Res],
  options? : ActionOptions,
) -> (Req, (TypedActionResponse[Res]) -> Unit) -> Unit {
  let url = typed_action_url(key)
  let opts = options.unwrap_or(ActionOptions::default())
  fn(payload, callback) {
    request_action(
      url,
      @js_any.json_to_any(payload.to_json()),
      "POST",
      fn(response) {
        callback(TypedActionResponse::from_action_response(response))
      },
      opts,
    )
  }
}

// ============================================================================
// Form Integration
// ============================================================================

///|
/// Action form configuration
pub struct ActionFormConfig[Res] {
  /// Action URL
  priv action : String
  /// Method (default: POST)
  priv form_method : String
  /// On success callback
  priv on_success : ((Res) -> Unit)?
  /// On error callback
  priv on_error : ((Int32, String) -> Unit)?
  /// On redirect callback (return false to prevent redirect)
  priv on_redirect : ((String) -> Bool)?
}

///|
/// Raw JS-facing form configuration.
priv struct RawActionFormConfig {
  action : String
  form_method : String
  on_success : ((@js.Any) -> Unit)?
  on_error : ((Int32, String) -> Unit)?
  on_redirect : ((String) -> Bool)?
}

///|
/// Default form config
fn[Res] ActionFormConfig::new(action : String) -> ActionFormConfig[Res] {
  {
    action,
    form_method: "POST",
    on_success: None,
    on_error: None,
    on_redirect: None,
  }
}

///|
/// Create form config from a generated action key
pub fn[Req, Res] ActionFormConfig::from_key(
  key : TypedActionKey[Req, Res],
) -> ActionFormConfig[Res] {
  ActionFormConfig::new(typed_action_url(key))
}

///|
/// Set form method for action form submission.
pub fn[Res] ActionFormConfig::with_method(
  self : ActionFormConfig[Res],
  form_method : String,
) -> ActionFormConfig[Res] {
  { ..self, form_method, }
}

///|
/// Set success callback for action form submission.
pub fn[Res] ActionFormConfig::with_success(
  self : ActionFormConfig[Res],
  on_success : (Res) -> Unit,
) -> ActionFormConfig[Res] {
  { ..self, on_success: Some(on_success), }
}

///|
/// Set error callback for action form submission.
pub fn[Res] ActionFormConfig::with_error(
  self : ActionFormConfig[Res],
  on_error : (Int32, String) -> Unit,
) -> ActionFormConfig[Res] {
  { ..self, on_error: Some(on_error), }
}

///|
/// Set redirect callback for action form submission.
pub fn[Res] ActionFormConfig::with_redirect(
  self : ActionFormConfig[Res],
  on_redirect : (String) -> Bool,
) -> ActionFormConfig[Res] {
  { ..self, on_redirect: Some(on_redirect), }
}

///|
fn[Res : FromJson] ActionFormConfig::to_raw(
  self : ActionFormConfig[Res],
) -> RawActionFormConfig {
  let on_success : ((@js.Any) -> Unit)? = match self.on_success {
    Some(callback) =>
      Some(fn(data) {
        guard @js_any.any_to_json(data) is Some(json) else {
          match self.on_error {
            Some(on_error) => on_error(0, "Action form response is not JSON")
            None => ()
          }
          return
        }
        let decoded : Res = @json.from_json(json) catch {
          _ => {
            match self.on_error {
              Some(on_error) =>
                on_error(0, "Action form response does not match expected type")
              None => ()
            }
            return
          }
        }
        callback(decoded)
      })
    None => None
  }
  {
    action: self.action,
    form_method: self.form_method,
    on_success,
    on_error: self.on_error,
    on_redirect: self.on_redirect,
  }
}

///|
/// Handle form submission as server action
pub fn[Res : FromJson] submit_form_as_action(
  form : @js_dom.HTMLFormElement,
  config : ActionFormConfig[Res],
) -> Unit {
  let raw = config.to_raw()
  invoke_action(
    raw.action,
    ffi_form_payload(form),
    fn(response) {
      match response {
        Success(data) =>
          match raw.on_success {
            Some(f) => f(data)
            None => ()
          }
        Redirect(url) => {
          let navigate = match raw.on_redirect {
            Some(f) => f(url)
            None => true
          }
          if navigate {
            ffi_navigate_action(url)
          }
        }
        Error(status, message) =>
          match raw.on_error {
            Some(f) => f(status, message)
            None => ()
          }
        NetworkError(message) | DecodeError(message) =>
          match raw.on_error {
            Some(f) => f(0, message)
            None => ()
          }
      }
    },
    http_method=raw.form_method,
  )
}

// ============================================================================
// FFI Implementation
// ============================================================================

// The FFI carries a string discriminator and plain data, never compiler-private enum tags.

///|
fn request_action(
  url : String,
  payload : @js.Any,
  http_method : String,
  callback : (ActionResponse) -> Unit,
  options : ActionOptions,
) -> Unit {
  let signals = match options.signal {
    Some(signal) => FixedArray::from_array([signal][:])
    None => FixedArray::from_array([][:])
  }
  ffi_request_action_cb(
    url,
    payload,
    http_method,
    FixedArray::from_array(options.headers[:]),
    signals,
    options.timeout.unwrap_or(0),
    fn(kind, status, message, data) {
      let response = match kind {
        "success" => ActionResponse::Success(data)
        "redirect" => ActionResponse::Redirect(message)
        "error" => ActionResponse::Error(status, message)
        "validation" => ActionResponse::Error(status, "Validation failed")
        "decode" => ActionResponse::DecodeError(message)
        _ => ActionResponse::NetworkError(message)
      }
      callback(response)
    },
  )
}

///|
extern "js" fn ffi_form_payload(form : @js_dom.HTMLFormElement) -> @js.Any =
  #| form => Object.fromEntries(new FormData(form).entries())

///|
extern "js" fn ffi_navigate_action(url : String) -> Unit =
  #| url => {
  #|   if (globalThis.__LUNA_NAVIGATION__) globalThis.__LUNA_NAVIGATION__.navigate(url);
  #|   else globalThis.location.assign(url);
  #| }

///|
extern "js" fn ffi_request_action_cb(
  url : String,
  payload : @js.Any,
  http_method : String,
  custom_headers : FixedArray[(String, String)],
  signals : FixedArray[@js_async.AbortSignal],
  timeout : Int32,
  callback : (String, Int32, String, @js.Any) -> Unit,
) -> Unit =
  #| async (url, payload, method, customHeaders, signals, timeout, callback) => {
  #|   let result;
  #|   const checkUrl = value => {
  #|     const current = globalThis.location;
  #|     const target = new URL(value, current.href);
  #|     if (!['http:', 'https:'].includes(target.protocol) || target.origin !== current.origin || target.username || target.password) {
  #|       throw new TypeError('Actions and redirects must use the current HTTP(S) origin.');
  #|     }
  #|     return target.href;
  #|   };
  #|   try {
  #|     const target = checkUrl(url);
  #|     const headers = new Headers({ 'Content-Type': 'application/json' });
  #|     for (const h of customHeaders) headers.set(h[0] ?? h._0, h[1] ?? h._1);
  #|     const signal = timeout > 0
  #|       ? AbortSignal.any([...signals, AbortSignal.timeout(timeout)])
  #|       : signals[0];
  #|     const response = await fetch(target, {
  #|       method, headers, body: JSON.stringify(payload), signal,
  #|       mode: 'same-origin', credentials: 'same-origin'
  #|     });
  #|     if (response.redirected) {
  #|       result = ['redirect', response.status, checkUrl(response.url), null];
  #|     } else {
  #|       const text = await response.text();
  #|       let data;
  #|       let decoded = false;
  #|       try { data = JSON.parse(text); decoded = true; } catch {}
  #|       if (!response.ok) {
  #|         const errors = data && data.fieldErrors;
  #|         if (response.status === 422 && errors && typeof errors === 'object' && !Array.isArray(errors) && Object.values(errors).every(value => typeof value === 'string')) {
  #|           result = ['validation', 422, '', errors];
  #|         } else {
  #|           result = ['error', response.status, typeof data?.error === 'string' ? data.error : text || response.statusText, null];
  #|         }
  #|       } else if (!decoded) {
  #|         result = ['decode', response.status, 'Action response is not JSON', null];
  #|       } else if (typeof data?.redirect === 'string') {
  #|         result = ['redirect', response.status, checkUrl(data.redirect), null];
  #|       } else {
  #|         result = ['success', response.status, '', data];
  #|       }
  #|     }
  #|   } catch (error) {
  #|     const aborted = signals.some(signal => signal.aborted) || error?.name === 'AbortError' || error?.name === 'TimeoutError';
  #|     result = [aborted ? 'aborted' : 'network', 0, aborted ? 'Action aborted' : error?.message || 'Network error', null];
  #|   }
  #|   // User callbacks run outside the transport catch and are invoked exactly once.
  #|   callback(...result);
  #| }
