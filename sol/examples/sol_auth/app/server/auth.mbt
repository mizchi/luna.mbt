///| Authentication utilities for sol
///|
///| This module provides FFI bindings to access session data
///| set by the TypeScript auth middleware (dev-auth.ts).
///|
///| Usage:
///|   let session = get_session()
///|   match session {
///|     Some(s) => ... // authenticated
///|     None => ... // not authenticated
///|   }

///|
/// Session data structure
pub struct Session {
  user_id : String
  user_name : String
  user_email : String
}

///|
/// Get current session from globalThis.__sol_session
/// Returns None if not authenticated
pub fn get_session() -> Session? {
  let raw = get_session_raw()
  if is_null(raw) {
    None
  } else {
    Some(
      Session::{
        user_id: get_user_field(raw, "id"),
        user_name: get_user_field(raw, "name"),
        user_email: get_user_field(raw, "email"),
      },
    )
  }
}

///|
/// Check if user is authenticated
pub fn is_authenticated() -> Bool {
  match get_session() {
    Some(_) => true
    None => false
  }
}

///|
extern "js" fn get_session_raw() -> @core.Any =
  #| () => globalThis.__sol_session || null

///|
extern "js" fn is_null(obj : @core.Any) -> Bool =
  #| (obj) => obj === null || obj === undefined

///|
extern "js" fn get_user_field(session : @core.Any, field : String) -> String =
  #| (session, field) => session?.user?.[field] || ""
