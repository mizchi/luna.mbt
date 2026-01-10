// Context Provider - Component-level value sharing (Solid.js style)
//
// Context values are associated with Owners (component tree nodes).
// When useContext is called, it walks up the Owner chain to find the value.
//

///|
/// Context type with typed getter
/// The current_getter is managed per-context and tracks the current value chain
pub struct Context[T] {
  id : Int
  default_value : () -> T
  /// Stack of (owner_id, getter) pairs for this context
  /// Most recent provider is at the end
  providers : Array[(Int, () -> T)]
}

///|
/// Global context ID counter
let context_id_counter : Ref[Int] = Ref::new(0)

///|
/// Create a new context with a default value
/// Similar to Solid.js createContext
pub fn[T] create_context(default_value : T) -> Context[T] {
  let id = context_id_counter.val
  context_id_counter.val = id + 1
  let default_fn = fn() { default_value }
  { id, default_value: default_fn, providers: [] }
}

///|
/// Check if an owner is still valid (in the owner chain from current)
fn is_owner_valid(owner_id : Int, current : Owner?) -> Bool {
  match current {
    None => false
    Some(o) =>
      if o.id == owner_id {
        not(o.disposed)
      } else {
        is_owner_valid(owner_id, o.parent)
      }
  }
}

///|
/// Find the most recent valid provider for this context
fn[T] find_valid_provider(
  ctx : Context[T],
  current_owner : Owner?,
) -> (() -> T)? {
  // Walk through providers from most recent to oldest
  for i = ctx.providers.length() - 1; i >= 0; i = i - 1 {
    let (owner_id, getter) = ctx.providers[i]
    if is_owner_valid(owner_id, current_owner) {
      return Some(getter)
    }
  }
  None
}

///|
/// Provide a context value for the current Owner and its descendants
/// The value is associated with the current Owner and will be available
/// to all effects and components created within this scope.
/// Example:
/// ```
/// let theme_ctx = create_context("light")
/// provide(theme_ctx, "dark", fn() {
/// // All components here will see "dark"
/// my_component()
/// })
/// ```
pub fn[T, R] provide(ctx : Context[T], value : T, f : () -> R) -> R {
  match get_owner() {
    None =>
      // No owner, create a temporary root
      create_root(fn(_dispose) { provide_inner(ctx, value, f) })
    Some(_) => provide_inner(ctx, value, f)
  }
}

///|
/// Internal: provide implementation when we have an owner
fn[T, R] provide_inner(ctx : Context[T], value : T, f : () -> R) -> R {
  // Create a child owner for this provide scope
  let parent = get_owner()
  let owner = Owner::new(parent)
  let owner_id = owner.id

  // Add provider to the context's provider list
  let getter : () -> T = fn() { value }
  ctx.providers.push((owner_id, getter))

  // Register cleanup to remove provider when owner is disposed
  owner.cleanups.push(fn() {
    ctx.providers.retain(fn(entry) {
      let (oid, _) = entry
      oid != owner_id
    })
  })

  // Run the function with this owner
  run_with_owner(owner, f)
}

///|
/// Use a context value - returns the current provided value or default
/// Walks up the Owner chain to find the nearest provided value.
/// Similar to Solid.js useContext
/// Example:
/// ```
/// let theme = use_context(theme_ctx) // Returns "dark" or default
/// ```
pub fn[T] use_context(ctx : Context[T]) -> T {
  let current_owner = get_owner()
  match find_valid_provider(ctx, current_owner) {
    Some(getter) => getter()
    None => (ctx.default_value)()
  }
}
