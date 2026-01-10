///|
/// Fine-grained reactive store implementations
/// Comparing different approaches for MoonBit

// =============================================================================
// Approach 1: Split Signals (individual signals per field)
// Most idiomatic for MoonBit, best performance, explicit structure
// =============================================================================

///|
/// A record where each field is an independent Signal
/// This is the most performant approach - updates only affect specific fields
pub struct SplitStore2[A, B] {
  field1 : Signal[A]
  field2 : Signal[B]
}

///|
pub fn[A, B] SplitStore2::new(v1 : A, v2 : B) -> SplitStore2[A, B] {
  { field1: signal(v1), field2: signal(v2) }
}

///|
/// 3-field version
pub struct SplitStore3[A, B, C] {
  field1 : Signal[A]
  field2 : Signal[B]
  field3 : Signal[C]
}

///|
pub fn[A, B, C] SplitStore3::new(
  v1 : A,
  v2 : B,
  v3 : C,
) -> SplitStore3[A, B, C] {
  { field1: signal(v1), field2: signal(v2), field3: signal(v3) }
}

// =============================================================================
// Approach 2: Lens-based Store
// Type-safe field access with getter/setter pairs
// =============================================================================

///|
/// A lens focuses on a specific part of a larger structure
pub struct Lens[S, A] {
  get : (S) -> A
  set : (S, A) -> S
}

///|
pub fn[S, A] Lens::new(get : (S) -> A, set : (S, A) -> S) -> Lens[S, A] {
  { get, set }
}

///|
/// A store with lens-based field access
/// Each focused lens creates a derived signal that only updates when that field changes
pub struct LensStore[T] {
  source : Signal[T]
}

///|
pub fn[T] LensStore::new(initial : T) -> LensStore[T] {
  { source: signal(initial) }
}

///|
/// Focus on a field using a lens, returns getter and setter functions
/// The getter is memoized and only recomputes when the focused value changes
/// Uses render_effect for synchronous updates
pub fn[T, A : Eq] LensStore::focus(
  self : LensStore[T],
  lens : Lens[T, A],
) -> (Signal[A], (A) -> Unit) {
  // Create a derived signal for this field
  let field_signal : Signal[A] = signal((lens.get)(self.source.peek()))

  // Subscribe to source changes and update field signal only if value changed
  let _ = render_effect(fn() {
    let new_value = (lens.get)(self.source.get())
    if new_value != field_signal.peek() {
      field_signal.set(new_value)
    }
  })

  // Setter updates the source through the lens
  let setter = fn(value : A) {
    self.source.update(fn(s) { (lens.set)(s, value) })
  }
  (field_signal, setter)
}

///|
/// Get the current snapshot of the entire store
pub fn[T] LensStore::snapshot(self : LensStore[T]) -> T {
  self.source.peek()
}

///|
/// Update the entire store
pub fn[T] LensStore::update(self : LensStore[T], f : (T) -> T) -> Unit {
  self.source.update(f)
}

// =============================================================================
// Approach 3: Record of Signals with snapshot
// Best of both worlds - fine-grained + easy snapshot for SSR
// =============================================================================

///|
/// Trait for signal records that can produce a snapshot
pub trait Snapshot {
  snapshot(Self) -> Self
}

///|
/// Helper to create a signal record from a plain record
/// Usage pattern:
/// ```
/// struct State { count: Int, name: String }
/// struct ReactiveState { count: Signal[Int], name: Signal[String] }
/// fn ReactiveState::from(s: State) -> ReactiveState {
/// { count: signal(s.count), name: signal(s.name) }
/// fn ReactiveState::snapshot(self) -> State {
/// { count: self.count.peek(), name: self.name.peek() }
/// ```
