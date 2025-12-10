///| Attribute helpers - HTML attribute factory functions

///|

///| This module provides convenient factory functions for creating HTML attributes.

///| Separated from core vnode for smaller bundle size when not needed.

// Attribute helpers

///|
/// Create a static attribute
pub fn attr(key : String, value : String) -> (String, @kaguya.Attr) {
  (key, @kaguya.attr_static(value))
}

///|
/// Create a dynamic attribute
pub fn attr_dyn(key : String, getter : () -> String) -> (String, @kaguya.Attr) {
  (key, @kaguya.attr_dynamic(getter))
}

///|
/// Create a className attribute
pub fn class(value : String) -> (String, @kaguya.Attr) {
  ("class", @kaguya.attr_static(value))
}

///|
/// Create a dynamic className attribute
pub fn class_dyn(getter : () -> String) -> (String, @kaguya.Attr) {
  ("class", @kaguya.attr_dynamic(getter))
}

///|
/// Create an id attribute
pub fn id(value : String) -> (String, @kaguya.Attr) {
  ("id", @kaguya.attr_static(value))
}

///|
/// Create a href attribute
pub fn href(value : String) -> (String, @kaguya.Attr) {
  ("href", @kaguya.attr_static(value))
}

///|
/// Create a src attribute
pub fn src(value : String) -> (String, @kaguya.Attr) {
  ("src", @kaguya.attr_static(value))
}

///|
/// Create an alt attribute
pub fn alt(value : String) -> (String, @kaguya.Attr) {
  ("alt", @kaguya.attr_static(value))
}

///|
/// Create a type attribute
pub fn type_(value : String) -> (String, @kaguya.Attr) {
  ("type", @kaguya.attr_static(value))
}

///|
/// Create a value attribute
pub fn value(value : String) -> (String, @kaguya.Attr) {
  ("value", @kaguya.attr_static(value))
}

///|
/// Create a dynamic value attribute
pub fn value_dyn(getter : () -> String) -> (String, @kaguya.Attr) {
  ("value", @kaguya.attr_dynamic(getter))
}

///|
/// Create a placeholder attribute
pub fn placeholder(value : String) -> (String, @kaguya.Attr) {
  ("placeholder", @kaguya.attr_static(value))
}

///|
/// Create a disabled attribute
pub fn disabled(value : Bool) -> (String, @kaguya.Attr) {
  if value {
    ("disabled", @kaguya.attr_static(""))
  } else {
    ("disabled", @kaguya.attr_static("__remove__"))
  }
}

///|
/// Create an onClick handler (placeholder for SSR, actual handler set in DOM)
pub fn on_click(handler : @kaguya.EventHandler) -> (String, @kaguya.Attr) {
  ("onClick", @kaguya.attr_handler(handler))
}

///|
/// Create an onInput handler
pub fn on_input(handler : @kaguya.EventHandler) -> (String, @kaguya.Attr) {
  ("onInput", @kaguya.attr_handler(handler))
}

///|
/// Create an onChange handler
pub fn on_change(handler : @kaguya.EventHandler) -> (String, @kaguya.Attr) {
  ("onChange", @kaguya.attr_handler(handler))
}

///|
/// Create an onSubmit handler
pub fn on_submit(handler : @kaguya.EventHandler) -> (String, @kaguya.Attr) {
  ("onSubmit", @kaguya.attr_handler(handler))
}

///|
/// Create a style attribute
pub fn style(styles : Array[(String, String)]) -> (String, @kaguya.Attr) {
  ("style", @kaguya.attr_style(styles))
}

///|
/// Create a dynamic style attribute
pub fn style_dyn(getter : () -> Array[(String, String)]) -> (String, @kaguya.Attr) {
  ("style", @kaguya.attr_dynamic_style(getter))
}
