///| Context API for global state management

///|

///| This provides a simple Context API similar to React's Context API,

///| allowing components to share values without passing props through every level.

///|

///| The storage backend is abstracted and can be switched between:

///| - JavaScript Map (default, for browser/Node.js)

///| - In-memory Map (for testing/non-JS environments, future implementation)

///| Global context storage instance

///|
/// By default, uses JavaScript-based storage
let default_storage : ContextStorage = create_js_storage()

///|
/// Context type - holds a unique ID and default value
pub struct Context[T] {
  id : Int
  default_value : T
}

///| Create a new context with a default value

///|

///| Example:

///| ```

///| let ThemeContext = create_context("light")

///|
/// ```
pub fn[T] create_context(default_value : T) -> Context[T] {
  let id = (default_storage.get_next_id)()
  { id, default_value }
}

///| Set the current value for a context

///|

///| This is similar to using a Provider in React.

///| The value will be available to all subsequent get_context() calls

///| until it is changed or cleared.

///|

///| Example:

///| ```

///| set_context(ThemeContext, "dark")

///|
/// ```
pub fn[T] set_context(context : Context[T], value : T) -> Unit {
  (default_storage.set_value)(context.id, @core.any(value))
}

///| Get the current value for a context

///|

///| Returns the value set by set_context(), or the default value

///| if no value has been set.

///|

///| Example:

///| ```

///| let theme = get_context(ThemeContext)

///|
/// ```
pub fn[T] get_context(context : Context[T]) -> T {
  match (default_storage.get_value)(context.id) {
    Some(value) => value.cast()
    None => context.default_value
  }
}

///| Clear the value for a context, reverting to default

///|

///| Example:

///| ```

///| clear_context(ThemeContext)

///|
/// ```
pub fn[T] clear_context(context : Context[T]) -> Unit {
  (default_storage.delete_value)(context.id)
}
