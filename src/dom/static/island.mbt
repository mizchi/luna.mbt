// Island helpers for server_dom
//
// Provides integration with client-side components through islands.

// =============================================================================
// Type-safe client component API (Recommended)
// =============================================================================

///|
/// Embed a client component with type-safe props
///
/// This is the recommended way to create interactive components in server-rendered HTML.
/// The ComponentRef contains all necessary information (url, props, trigger, wc flag).
///
/// Example:
/// ```moonbit
/// // In app/__gen__/types/types.mbt (generated)
/// pub fn counter(props: CounterProps) -> @core.ComponentRef[CounterProps] {
///   @luna.component_ref("/static/counter.js", props)
/// }
///
/// // In server component
/// client(
///   @types.counter({ initial_count: 42 }),
///   [text("Loading...")],
/// )
/// ```
pub fn[T : ToJson] client(
  cref : @core.ComponentRef[T],
  children : Array[@luna.Node[Unit]],
  styles? : String = "",
) -> @luna.Node[Unit] {
  @luna.internal_ref(
    cref.url,
    cref.props.to_json().stringify(),
    trigger=cref.trigger,
    wc=cref.wc,
    styles~,
    children~,
  )
}
