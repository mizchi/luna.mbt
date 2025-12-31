// Sol SSG ISR Types
//
// Types are now defined in sol/isr for sharing between Sol SSG and Sol.
// This file is kept for backwards compatibility but delegates to sol types.

// Re-export sol manifest with additional builder function

///|
pub fn new_manifest() -> @sol_isr.ISRManifest {
  @sol_isr.ISRManifest::new()
}

///|
pub fn new_entry(
  revalidate : Int,
  renderer : String,
  source : String,
) -> @sol_isr.ISRPageMeta {
  { revalidate, renderer, source }
}
