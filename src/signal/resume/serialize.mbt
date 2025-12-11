///| Signal Serialization - Serialize Signal values to ResumableState

///|
/// Trait for types that can be serialized to StateValue
pub(open) trait Serializable {
  to_state_value(Self) -> StateValue
  from_state_value(StateValue) -> Self?
}

///|
impl Serializable for Int with to_state_value(self) { Int(self) }

///|
impl Serializable for Int with from_state_value(value) {
  match value {
    Int(n) => Some(n)
    _ => None
  }
}

///|
impl Serializable for String with to_state_value(self) { Str(self) }

///|
impl Serializable for String with from_state_value(value) {
  match value {
    Str(s) => Some(s)
    _ => None
  }
}

///|
impl Serializable for Bool with to_state_value(self) { Bool(self) }

///|
impl Serializable for Bool with from_state_value(value) {
  match value {
    Bool(b) => Some(b)
    _ => None
  }
}

///|
impl Serializable for Double with to_state_value(self) { Float(self) }

///|
impl Serializable for Double with from_state_value(value) {
  match value {
    Float(f) => Some(f)
    _ => None
  }
}

///|
/// Register a signal's current value to state and return its ID
pub fn[T : Serializable] register_signal(
  state : ResumableState,
  signal : @signal.Signal[T],
) -> Int {
  let value = signal.peek()
  let state_value = Serializable::to_state_value(value)
  let id = state.next_id
  state.next_id = id + 1
  state.values.push(state_value)
  id
}

///|
/// Restore a signal's value from state
pub fn[T : Serializable] restore_signal(
  state : ResumableState,
  signal : @signal.Signal[T],
  id : Int,
) -> Bool {
  match state.get(id) {
    Some(value) =>
      match Serializable::from_state_value(value) {
        Some(v) => {
          signal.set(v)
          true
        }
        None => false
      }
    None => false
  }
}

///|
/// Create a signal and register it to state, returning (signal, id)
pub fn[T : Serializable] create_resumable_signal(
  state : ResumableState,
  initial : T,
) -> (@signal.Signal[T], Int) {
  let signal = @signal.signal(initial)
  let id = register_signal(state, signal)
  (signal, id)
}

///|
/// Restore or create a signal from state
/// If state has a value at the given ID, use it; otherwise use initial
pub fn[T : Serializable] resume_signal(
  state : ResumableState,
  id : Int,
  initial : T,
) -> @signal.Signal[T] {
  match state.get(id) {
    Some(value) =>
      match Serializable::from_state_value(value) {
        Some(v) => @signal.signal(v)
        None => @signal.signal(initial)
      }
    None => @signal.signal(initial)
  }
}

// =============================================================================
// Serializable utilities - ensure trait implementations are used
// =============================================================================

///|
/// Convert an Int to StateValue
pub fn int_to_state_value(value : Int) -> StateValue {
  Serializable::to_state_value(value)
}

///|
/// Convert a String to StateValue
pub fn string_to_state_value(value : String) -> StateValue {
  Serializable::to_state_value(value)
}

///|
/// Convert a Bool to StateValue
pub fn bool_to_state_value(value : Bool) -> StateValue {
  Serializable::to_state_value(value)
}

///|
/// Convert a Double to StateValue
pub fn double_to_state_value(value : Double) -> StateValue {
  Serializable::to_state_value(value)
}
