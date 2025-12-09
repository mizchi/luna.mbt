///| Props builder helpers - type-safe prop construction

///| Generic over handler type H for multi-backend support

///|

///|
/// Create empty props
pub fn[H] props() -> Props[H] {
  []
}

///| Common HTML attributes

///|
/// className attribute
pub fn[H] class_name(value : String) -> (String, AttrValue[H]) {
  ("className", AttrValue::Str(value))
}

///|
/// id attribute
pub fn[H] id(value : String) -> (String, AttrValue[H]) {
  ("id", AttrValue::Str(value))
}

///|
/// href attribute (for links)
pub fn[H] href(value : String) -> (String, AttrValue[H]) {
  ("href", AttrValue::Str(value))
}

///|
/// src attribute (for images, scripts)
pub fn[H] src(value : String) -> (String, AttrValue[H]) {
  ("src", AttrValue::Str(value))
}

///|
/// alt attribute (for images)
pub fn[H] alt(value : String) -> (String, AttrValue[H]) {
  ("alt", AttrValue::Str(value))
}

///|
/// title attribute
pub fn[H] title(value : String) -> (String, AttrValue[H]) {
  ("title", AttrValue::Str(value))
}

///|
/// placeholder attribute (for inputs)
pub fn[H] placeholder(value : String) -> (String, AttrValue[H]) {
  ("placeholder", AttrValue::Str(value))
}

///|
/// value attribute (for inputs)
pub fn[H] value(value : String) -> (String, AttrValue[H]) {
  ("value", AttrValue::Str(value))
}

///|
/// type attribute (for inputs)
pub fn[H] type_(value : String) -> (String, AttrValue[H]) {
  ("type", AttrValue::Str(value))
}

///|
/// name attribute (for form elements)
pub fn[H] name(value : String) -> (String, AttrValue[H]) {
  ("name", AttrValue::Str(value))
}

///|
/// for attribute (for labels)
pub fn[H] for_(value : String) -> (String, AttrValue[H]) {
  ("for", AttrValue::Str(value))
}

///|
/// Generic data-* attribute
pub fn[H] data_(key : String, value : String) -> (String, AttrValue[H]) {
  (key, AttrValue::Str(value))
}

///| Boolean attributes

///|
/// disabled attribute
pub fn[H] disabled(value : Bool) -> (String, AttrValue[H]) {
  ("disabled", AttrValue::Bool(value))
}

///|
/// checked attribute (for checkboxes)
pub fn[H] checked(value : Bool) -> (String, AttrValue[H]) {
  ("checked", AttrValue::Bool(value))
}

///|
/// readonly attribute
pub fn[H] readonly_(value : Bool) -> (String, AttrValue[H]) {
  ("readonly", AttrValue::Bool(value))
}

///|
/// required attribute (for form inputs)
pub fn[H] required(value : Bool) -> (String, AttrValue[H]) {
  ("required", AttrValue::Bool(value))
}

///| Numeric attributes

///|
/// tabIndex attribute
pub fn[H] tab_index(value : Int) -> (String, AttrValue[H]) {
  ("tabIndex", AttrValue::Num(value))
}

///|
/// maxLength attribute (for inputs)
pub fn[H] max_length(value : Int) -> (String, AttrValue[H]) {
  ("maxLength", AttrValue::Num(value))
}

///| Event handlers

///|
/// onClick event handler
pub fn[H] on_click(handler : H) -> (String, AttrValue[H]) {
  ("onClick", AttrValue::Handler(handler))
}

///|
/// onChange event handler
pub fn[H] on_change(handler : H) -> (String, AttrValue[H]) {
  ("onChange", AttrValue::Handler(handler))
}

///|
/// onInput event handler
pub fn[H] on_input(handler : H) -> (String, AttrValue[H]) {
  ("onInput", AttrValue::Handler(handler))
}

///|
/// onSubmit event handler
pub fn[H] on_submit(handler : H) -> (String, AttrValue[H]) {
  ("onSubmit", AttrValue::Handler(handler))
}

///|
/// onFocus event handler
pub fn[H] on_focus(handler : H) -> (String, AttrValue[H]) {
  ("onFocus", AttrValue::Handler(handler))
}

///|
/// onBlur event handler
pub fn[H] on_blur(handler : H) -> (String, AttrValue[H]) {
  ("onBlur", AttrValue::Handler(handler))
}

///|
/// onKeyDown event handler
pub fn[H] on_key_down(handler : H) -> (String, AttrValue[H]) {
  ("onKeyDown", AttrValue::Handler(handler))
}

///|
/// onKeyUp event handler
pub fn[H] on_key_up(handler : H) -> (String, AttrValue[H]) {
  ("onKeyUp", AttrValue::Handler(handler))
}

///|
/// onMouseEnter event handler
pub fn[H] on_mouse_enter(handler : H) -> (String, AttrValue[H]) {
  ("onMouseEnter", AttrValue::Handler(handler))
}

///|
/// onMouseLeave event handler
pub fn[H] on_mouse_leave(handler : H) -> (String, AttrValue[H]) {
  ("onMouseLeave", AttrValue::Handler(handler))
}

///| Style

///|
/// style attribute - takes array of CSS property-value pairs
pub fn[H] style(styles : Array[(String, String)]) -> (String, AttrValue[H]) {
  ("style", AttrValue::StyleObj(styles))
}

///|
/// Custom attribute (for any attribute not covered above)
pub fn[H] attr(key : String, value : String) -> (String, AttrValue[H]) {
  (key, AttrValue::Str(value))
}

///|
/// Custom numeric attribute
pub fn[H] attr_num(key : String, value : Int) -> (String, AttrValue[H]) {
  (key, AttrValue::Num(value))
}

///|
/// Custom boolean attribute
pub fn[H] attr_bool(key : String, value : Bool) -> (String, AttrValue[H]) {
  (key, AttrValue::Bool(value))
}
