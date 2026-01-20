///| Auto-generated types for island props
///| Re-exports Props structs from client packages

///| Props type from @client
pub(all) struct CounterProps {
  initial_count : Int
} derive(ToJson, FromJson)

///| Props type from @client
pub(all) struct ContactFormProps {
  action : String
  initial_name : String
  initial_email : String
} derive(ToJson, FromJson)

///| Props type from @client
pub(all) struct WcCounterProps {
  initial_count : Int
} derive(ToJson, FromJson)

// =============================================================================
// ComponentRef Factory Functions
// =============================================================================

///|
///| Create ComponentRef for counter component
pub fn counter(
  props : CounterProps,
  trigger~ : @luna.Trigger = @luna.TriggerType::Load,
) -> @luna.ComponentRef[CounterProps] {
  { url: "/static/counter.js", props, wc: false, trigger }
}

///|
///| Create ComponentRef for contact_form component
pub fn contact_form(
  props : ContactFormProps,
  trigger~ : @luna.Trigger = @luna.TriggerType::Load,
) -> @luna.ComponentRef[ContactFormProps] {
  { url: "/static/contact_form.js", props, wc: false, trigger }
}

///|
///| Create ComponentRef for wc_counter component
pub fn wc_counter(
  props : WcCounterProps,
  trigger~ : @luna.Trigger = @luna.TriggerType::Load,
) -> @luna.ComponentRef[WcCounterProps] {
  { url: "/static/wc_counter.js", props, wc: true, trigger }
}

