// Event Handler Types - Type-safe event handlers for Luna DOM
//
// This module provides typed event handler aliases similar to React's event handler types.
// Each handler type is parameterized by the target element type [T] for type safety.
//
// Usage:
// // Type-safe handler with specific element type
// let handler : MouseEventHandler[@js_dom.HTMLButtonElement] = fn(e) {
// let target = e.target() // Returns HTMLButtonElement
// e.preventDefault()
// }
//
// // Or use with generic Element when element type doesn't matter
// let handler : MouseEventHandler[@js_dom.Element] = fn(e) { ... }

// =============================================================================
// Event Handler Type Aliases (with target element type parameter)
// =============================================================================

///|
/// MouseEventHandler[T] - Handler for mouse events (click, dblclick, mouseenter, etc.)
/// T is the target element type (e.g., HTMLButtonElement, HTMLDivElement)
/// The event provides clientX, clientY, button, ctrlKey, etc.
pub type MouseEventHandler[T] = (@js_dom.MouseEvent) -> Unit

///|
/// KeyboardEventHandler[T] - Handler for keyboard events (keydown, keyup, keypress)
/// T is the target element type (e.g., HTMLInputElement)
/// The event provides key, code, ctrlKey, shiftKey, etc.
pub type KeyboardEventHandler[T] = (@js_dom.KeyboardEvent) -> Unit

///|
/// InputEventHandler[T] - Handler for input events on form elements
/// T is the target element type (e.g., HTMLInputElement, HTMLTextAreaElement)
/// The event provides inputType, data, isComposing, etc.
pub type InputEventHandler[T] = (@js_dom.InputEvent) -> Unit

///|
/// ChangeEventHandler[T] - Handler for change events on form elements
/// T is the target element type (e.g., HTMLInputElement, HTMLSelectElement)
pub type ChangeEventHandler[T] = (@js_dom.ChangeEvent) -> Unit

///|
/// FocusEventHandler[T] - Handler for focus/blur events
/// T is the target element type
/// The event provides relatedTarget for focus transitions
pub type FocusEventHandler[T] = (@js_dom.FocusEvent) -> Unit

///|
/// FormEventHandler[T] - Handler for form submission events
/// T is typically HTMLFormElement
/// Call preventDefault() to prevent default form submission
pub type FormEventHandler[T] = (@js_dom.FormEvent) -> Unit

///|
/// DragEventHandler[T] - Handler for drag and drop events
/// T is the target element type
/// The event provides dataTransfer for drag data
pub type DragEventHandler[T] = (@js_dom.DragEvent) -> Unit

///|
/// WheelEventHandler[T] - Handler for wheel/scroll events
/// T is the target element type
/// The event provides deltaX, deltaY, deltaZ, deltaMode
pub type WheelEventHandler[T] = (@js_dom.WheelEvent) -> Unit

///|
/// TouchEventHandler[T] - Handler for touch events on touch devices
/// T is the target element type
/// The event provides touches, targetTouches, changedTouches arrays
pub type TouchEventHandler[T] = (@js_dom.TouchEvent) -> Unit

///|
/// PointerEventHandler[T] - Handler for pointer events (unified mouse/touch/pen)
/// T is the target element type
/// The event provides pointerId, pointerType, pressure, etc.
pub type PointerEventHandler[T] = (@js_dom.PointerEvent) -> Unit

///|
/// AnimationEventHandler[T] - Handler for CSS animation events
/// T is the target element type
/// The event provides animationName, elapsedTime, pseudoElement
pub type AnimationEventHandler[T] = (@js_dom.AnimationEvent) -> Unit

///|
/// TransitionEventHandler[T] - Handler for CSS transition events
/// T is the target element type
/// The event provides propertyName, elapsedTime, pseudoElement
pub type TransitionEventHandler[T] = (@js_dom.TransitionEvent) -> Unit

///|
/// ClipboardEventHandler[T] - Handler for clipboard events (copy, cut, paste)
/// T is the target element type
/// The event provides clipboardData
pub type ClipboardEventHandler[T] = (@js_dom.ClipboardEvent) -> Unit

///|
/// ScrollEventHandler[T] - Handler for scroll events
/// T is the target element type
pub type ScrollEventHandler[T] = (@js_dom.ScrollEvent) -> Unit

// =============================================================================
// Generic Event Handler
// =============================================================================

///|
/// GenericEventHandler[T] - Handler for any DOM event
/// T is the target element type
/// Use when you need to handle an event type not covered above
pub type GenericEventHandler[T] = (@js_dom.Event) -> Unit

// =============================================================================
// Ref Callback Type - For direct DOM element access (Solid.js style)
// =============================================================================

///|
/// RefCallback[T] - Callback for accessing the DOM element after creation
/// T is the target element type (e.g., HTMLButtonElement, HTMLInputElement)
/// Called when the element is created, before it connects to the DOM
///
/// Usage:
///   button(ref=fn(el) { myButtonRef = el }, children=[text("Click me")])
///
/// Note: The ref callback receives the raw @js_dom element, not DomElement wrapper
pub type RefCallback[T] = (T) -> Unit

// =============================================================================
// Non-generic aliases for convenience (using Element as target)
// =============================================================================

///|
/// Convenience alias: ElementRef - RefCallback for generic Element
/// Use when you don't need specific element type
pub type ElementRef = (@js_dom.Element) -> Unit

///|
/// Convenience alias: MouseHandler = MouseEventHandler[@js_dom.Element]
pub type MouseHandler = (@js_dom.MouseEvent) -> Unit

///|
/// Convenience alias: KeyboardHandler = KeyboardEventHandler[@js_dom.Element]
pub type KeyboardHandler = (@js_dom.KeyboardEvent) -> Unit

///|
/// Convenience alias: InputHandler = InputEventHandler[@js_dom.Element]
pub type InputHandler = (@js_dom.InputEvent) -> Unit

///|
/// Convenience alias: ChangeHandler = ChangeEventHandler[@js_dom.Element]
pub type ChangeHandler = (@js_dom.ChangeEvent) -> Unit

///|
/// Convenience alias: FocusHandler = FocusEventHandler[@js_dom.Element]
pub type FocusHandler = (@js_dom.FocusEvent) -> Unit

///|
/// Convenience alias: FormHandler = FormEventHandler[@js_dom.Element]
pub type FormHandler = (@js_dom.FormEvent) -> Unit
