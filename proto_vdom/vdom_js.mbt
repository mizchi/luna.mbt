///| JS Backend Type Aliases

///|

///| This module provides JS-specific type aliases for the generic VNode types.

///| These aliases are used throughout the JS backend (DOM renderer, SSR, etc.)

///|

///|
/// JS event handler type - receives DOM events as @core.Any
pub type JSHandler = (@core.Any) -> Unit

///|

///|
/// JS-specific VNode type
pub type JSVNode = VNode[JSHandler]

///|

///|
/// JS-specific ElementNode type
pub type JSElementNode = ElementNode[JSHandler]

///|

///|
/// JS-specific Props type
pub type JSProps = Props[JSHandler]

///|

///|
/// JS-specific AttrValue type
pub type JSAttrValue = AttrValue[JSHandler]

///|

///|
/// Backwards compatibility: EventHandler is JS-specific
pub type EventHandler = JSHandler
