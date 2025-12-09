///| Attribute helpers - HTML attribute factory functions
///|
///| This module provides convenient factory functions for creating HTML attributes.
///| Separated from core vnode for smaller bundle size when not needed.

// Attribute helpers

///|
/// Create a static attribute
pub fn vattr(key : String, value : String) -> (String, @ui.Attr) {
  (key, @ui.attr_static(value))
}

///|
/// Create a dynamic attribute
pub fn vattr_dyn(key : String, getter : () -> String) -> (String, @ui.Attr) {
  (key, @ui.attr_dynamic(getter))
}

///|
/// Create a className attribute
pub fn vclass(value : String) -> (String, @ui.Attr) {
  ("class", @ui.attr_static(value))
}

///|
/// Create a dynamic className attribute
pub fn vclass_dyn(getter : () -> String) -> (String, @ui.Attr) {
  ("class", @ui.attr_dynamic(getter))
}

///|
/// Create an id attribute
pub fn vid(value : String) -> (String, @ui.Attr) {
  ("id", @ui.attr_static(value))
}

///|
/// Create a href attribute
pub fn vhref(value : String) -> (String, @ui.Attr) {
  ("href", @ui.attr_static(value))
}

///|
/// Create a src attribute
pub fn vsrc(value : String) -> (String, @ui.Attr) {
  ("src", @ui.attr_static(value))
}

///|
/// Create an alt attribute
pub fn valt(value : String) -> (String, @ui.Attr) {
  ("alt", @ui.attr_static(value))
}

///|
/// Create a type attribute
pub fn vtype(value : String) -> (String, @ui.Attr) {
  ("type", @ui.attr_static(value))
}

///|
/// Create a value attribute
pub fn vvalue(value : String) -> (String, @ui.Attr) {
  ("value", @ui.attr_static(value))
}

///|
/// Create a dynamic value attribute
pub fn vvalue_dyn(getter : () -> String) -> (String, @ui.Attr) {
  ("value", @ui.attr_dynamic(getter))
}

///|
/// Create a placeholder attribute
pub fn vplaceholder(value : String) -> (String, @ui.Attr) {
  ("placeholder", @ui.attr_static(value))
}

///|
/// Create a disabled attribute
pub fn vdisabled(value : Bool) -> (String, @ui.Attr) {
  if value {
    ("disabled", @ui.attr_static(""))
  } else {
    ("disabled", @ui.attr_static("__remove__"))
  }
}

///|
/// Create an onClick handler (placeholder for SSR, actual handler set in DOM)
pub fn von_click(handler : @ui.EventHandler) -> (String, @ui.Attr) {
  ("onClick", @ui.attr_handler(handler))
}

///|
/// Create an onInput handler
pub fn von_input(handler : @ui.EventHandler) -> (String, @ui.Attr) {
  ("onInput", @ui.attr_handler(handler))
}

///|
/// Create an onChange handler
pub fn von_change(handler : @ui.EventHandler) -> (String, @ui.Attr) {
  ("onChange", @ui.attr_handler(handler))
}

///|
/// Create an onSubmit handler
pub fn von_submit(handler : @ui.EventHandler) -> (String, @ui.Attr) {
  ("onSubmit", @ui.attr_handler(handler))
}

///|
/// Create a style attribute
pub fn vstyle(styles : Array[(String, String)]) -> (String, @ui.Attr) {
  ("style", @ui.attr_style(styles))
}

///|
/// Create a dynamic style attribute
pub fn vstyle_dyn(getter : () -> Array[(String, String)]) -> (String, @ui.Attr) {
  ("style", @ui.attr_dynamic_style(getter))
}
