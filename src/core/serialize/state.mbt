// Resumable State - Qwik-like state serialization and restoration
//
// This module provides functionality to serialize Signal states to JSON
// and restore them on the client side for hydration.
//

///|
/// State container that can be serialized
pub struct ResumableState {
  /// Serialized values as JSON-compatible array
  values : Array[StateValue]
  /// Map from signal ID to index in values array
  mut next_id : Int
}

///|
/// Create a new empty resumable state
pub fn ResumableState::new() -> ResumableState {
  { values: [], next_id: 0 }
}

///|
/// Add a null value to state
pub fn ResumableState::register_null(self : ResumableState) -> Int {
  let id = self.next_id
  self.next_id = id + 1
  self.values.push(sv_null())
  id
}

///|
/// Register a signal value and return its ID
pub fn ResumableState::register_int(self : ResumableState, value : Int) -> Int {
  let id = self.next_id
  self.next_id = id + 1
  self.values.push(sv_int(value))
  id
}

///|
/// Register a string value and return its ID
pub fn ResumableState::register_string(
  self : ResumableState,
  value : String,
) -> Int {
  let id = self.next_id
  self.next_id = id + 1
  self.values.push(sv_str(value))
  id
}

///|
/// Register a bool value and return its ID
pub fn ResumableState::register_bool(
  self : ResumableState,
  value : Bool,
) -> Int {
  let id = self.next_id
  self.next_id = id + 1
  self.values.push(sv_bool(value))
  id
}

///|
/// Register a float value and return its ID
pub fn ResumableState::register_float(
  self : ResumableState,
  value : Double,
) -> Int {
  let id = self.next_id
  self.next_id = id + 1
  self.values.push(sv_number(value))
  id
}

///|
/// Get value at index
pub fn ResumableState::get(self : ResumableState, id : Int) -> StateValue? {
  if id >= 0 && id < self.values.length() {
    Some(self.values[id])
  } else {
    None
  }
}

///|
/// Get int value at index
pub fn ResumableState::get_int(self : ResumableState, id : Int) -> Int? {
  match self.get(id) {
    Some(v) => v.as_int()
    None => None
  }
}

///|
/// Get string value at index
pub fn ResumableState::get_string(self : ResumableState, id : Int) -> String? {
  match self.get(id) {
    Some(v) => v.as_string()
    None => None
  }
}

///|
/// Get bool value at index
pub fn ResumableState::get_bool(self : ResumableState, id : Int) -> Bool? {
  match self.get(id) {
    Some(v) => v.as_bool()
    None => None
  }
}

///|
/// Get float value at index
pub fn ResumableState::get_float(self : ResumableState, id : Int) -> Double? {
  match self.get(id) {
    Some(v) => v.as_number()
    None => None
  }
}

///|
/// Serialize state to JSON string
pub fn ResumableState::to_json(self : ResumableState) -> String {
  state_values_to_json(self.values)
}

///|
/// Parse JSON string to ResumableState
pub fn ResumableState::from_json(json : String) -> ResumableState? {
  match state_values_from_json(json) {
    Some(values) => Some({ values, next_id: values.length() })
    None => None
  }
}
