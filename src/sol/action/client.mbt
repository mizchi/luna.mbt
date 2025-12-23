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
  timeout : Int?
  /// Abort signal (for cancellation)
  signal : @js.Any?
}

///|
/// Default action options
pub fn ActionOptions::default() -> ActionOptions {
  { headers: [], timeout: None, signal: None }
}

///|
/// Action client response
pub enum ActionResponse {
  /// Successful response with data
  Success(@js.Any)
  /// Server requested a redirect
  Redirect(String)
  /// Error response
  Error(Int, String)
  /// Network error
  NetworkError(String)
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
pub fn invoke_action(
  url : String,
  payload : @js.Any,
  callback : (ActionResponse) -> Unit,
  options? : ActionOptions,
) -> Unit {
  let opts = options.unwrap_or(ActionOptions::default())
  ffi_invoke_action_cb(url, payload, callback, opts)
}

///|
/// Create an action invoker for a specific endpoint
/// Returns a function that takes payload and callback
pub fn create_action_invoker(
  url : String,
  options? : ActionOptions,
) -> (@js.Any, (ActionResponse) -> Unit) -> Unit {
  let opts = options.unwrap_or(ActionOptions::default())
  fn(payload, callback) { ffi_invoke_action_cb(url, payload, callback, opts) }
}

// ============================================================================
// Form Integration
// ============================================================================

///|
/// Action form configuration
pub struct ActionFormConfig {
  /// Action URL
  action : String
  /// Method (default: POST)
  form_method : String
  /// On success callback
  on_success : ((@js.Any) -> Unit)?
  /// On error callback
  on_error : ((Int, String) -> Unit)?
  /// On redirect callback (return false to prevent redirect)
  on_redirect : ((String) -> Bool)?
}

///|
/// Default form config
pub fn ActionFormConfig::new(action : String) -> ActionFormConfig {
  {
    action,
    form_method: "POST",
    on_success: None,
    on_error: None,
    on_redirect: None,
  }
}

///|
/// Handle form submission as server action
pub fn submit_form_as_action(form : @js.Any, config : ActionFormConfig) -> Unit {
  ffi_submit_form_action(form, config)
}

// ============================================================================
// FFI Implementation
// ============================================================================

///|
extern "js" fn ffi_invoke_action_cb(
  url : String,
  payload : @js.Any,
  callback : (ActionResponse) -> Unit,
  options : ActionOptions,
) -> Unit =
  #| (url, payload, callback, options) => {
  #|   (async () => {
  #|     try {
  #|       // Build headers - options.headers is MoonBit Array of tuples
  #|       const headers = { 'Content-Type': 'application/json' };
  #|       if (options.headers && options.headers.length > 0) {
  #|         for (const h of options.headers) {
  #|           // MoonBit tuple: h[0] or h._0 for first, h[1] or h._1 for second
  #|           const key = h[0] ?? h._0;
  #|           const val = h[1] ?? h._1;
  #|           if (key && val) headers[key] = val;
  #|         }
  #|       }
  #|
  #|       const fetchOptions = {
  #|         method: 'POST',
  #|         headers,
  #|         body: JSON.stringify(payload),
  #|         credentials: 'same-origin'
  #|       };
  #|
  #|       // Handle MoonBit Option type: { $: "Some", _0: value } or { $: "None" }
  #|       const signal = options.signal;
  #|       if (signal && signal.$ === 'Some' && signal._0 instanceof AbortSignal) {
  #|         fetchOptions.signal = signal._0;
  #|       }
  #|
  #|       const response = await fetch(url, fetchOptions);
  #|
  #|       if (!response.ok) {
  #|         const text = await response.text();
  #|         try {
  #|           const json = JSON.parse(text);
  #|           // Error = variant index 2
  #|           callback({ $tag: 2, _0: response.status, _1: json.error || text });
  #|         } catch {
  #|           callback({ $tag: 2, _0: response.status, _1: text });
  #|         }
  #|         return;
  #|       }
  #|
  #|       const data = await response.json();
  #|
  #|       // Check for redirect instruction
  #|       if (data.redirect) {
  #|         // Redirect = variant index 1
  #|         callback({ $tag: 1, _0: data.redirect });
  #|         return;
  #|       }
  #|
  #|       // Success = variant index 0
  #|       callback({ $tag: 0, _0: data });
  #|     } catch (error) {
  #|       // NetworkError = variant index 3
  #|       callback({ $tag: 3, _0: error.message || 'Network error' });
  #|     }
  #|   })();
  #| }

///|
extern "js" fn ffi_submit_form_action(
  form : @js.Any,
  config : ActionFormConfig,
) -> Unit =
  #| async (form, config) => {
  #|   try {
  #|     const formData = new FormData(form);
  #|     const payload = Object.fromEntries(formData.entries());
  #|
  #|     const response = await fetch(config.action, {
  #|       method: config.form_method || 'POST',
  #|       headers: { 'Content-Type': 'application/json' },
  #|       body: JSON.stringify(payload),
  #|       credentials: 'same-origin'
  #|     });
  #|
  #|     const data = await response.json();
  #|
  #|     if (!response.ok) {
  #|       if (config.on_error) {
  #|         config.on_error(response.status, data.error || 'Unknown error');
  #|       }
  #|       return;
  #|     }
  #|
  #|     if (data.redirect) {
  #|       const shouldRedirect = config.on_redirect ? config.on_redirect(data.redirect) : true;
  #|       if (shouldRedirect) {
  #|         window.location.href = data.redirect;
  #|       }
  #|       return;
  #|     }
  #|
  #|     if (config.on_success) {
  #|       config.on_success(data);
  #|     }
  #|   } catch (error) {
  #|     if (config.on_error) {
  #|       config.on_error(0, error.message || 'Network error');
  #|     }
  #|   }
  #| }

// ============================================================================
// Utility Functions
// ============================================================================

///|
/// Check if response is successful
pub fn ActionResponse::is_success(self : ActionResponse) -> Bool {
  match self {
    Success(_) => true
    _ => false
  }
}

///|
/// Check if response is a redirect
pub fn ActionResponse::is_redirect(self : ActionResponse) -> Bool {
  match self {
    Redirect(_) => true
    _ => false
  }
}

///|
/// Check if response is an error
pub fn ActionResponse::is_error(self : ActionResponse) -> Bool {
  match self {
    Error(_, _) | NetworkError(_) => true
    _ => false
  }
}

///|
/// Get data from successful response
pub fn ActionResponse::data(self : ActionResponse) -> @js.Any? {
  match self {
    Success(data) => Some(data)
    _ => None
  }
}

///|
/// Get redirect URL
pub fn ActionResponse::redirect_url(self : ActionResponse) -> String? {
  match self {
    Redirect(url) => Some(url)
    _ => None
  }
}

///|
/// Get error message
pub fn ActionResponse::error_message(self : ActionResponse) -> String? {
  match self {
    Error(_, msg) => Some(msg)
    NetworkError(msg) => Some(msg)
    _ => None
  }
}
