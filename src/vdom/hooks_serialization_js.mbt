///| JavaScript Backend: Hooks State Serialization

///|

///| Provides JSON-based serialization for HooksState in JavaScript backend

///|

///|
/// Serialize hooks state to JSON string (JavaScript backend)
/// Note: Only serializes data values, not functions
pub fn HooksState::serialize_js(self : HooksState) -> String {
  // Convert Array[@core.Any] to @core.Any array for JSON.stringify
  let arr : @core.Any = self.hooks |> @core.identity
  @json.JSON::stringify(arr)
}

///|

///|
/// Deserialize hooks state from JSON string (JavaScript backend)
/// Creates a new HooksState with restored values
pub fn HooksState::from_json(json : String) -> HooksState {
  let arr : Array[@core.Any] = @json.JSON::parse(json)
  { hooks: arr, current_index: 0, effects: [] }
}

///|

///|
/// Restore hooks state from JSON string (JavaScript backend)
/// Updates the current state in-place
pub fn HooksState::restore_from_json(self : HooksState, json : String) -> Unit {
  let arr : Array[@core.Any] = @json.JSON::parse(json)
  for i = 0; i < arr.length(); i = i + 1 {
    if i < self.hooks.length() {
      self.hooks[i] = arr[i]
    } else {
      self.hooks.push(arr[i])
    }
  }
}
