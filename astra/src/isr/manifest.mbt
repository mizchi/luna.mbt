// ISR (Incremental Static Regeneration) manifest types.
// Shared between astra (build-side: emits the manifest) and
// sol/isr (runtime-side: reads the manifest and dispatches to cache).

///|
/// ISR page entry from manifest
pub(all) struct ISRPageMeta {
  revalidate : Int
  renderer : String
  source : String
}

///|
/// ISR manifest loaded from _luna/isr.json
pub(all) struct ISRManifest {
  version : Int
  pages : Map[String, ISRPageMeta]
}

///|
/// Create empty manifest
pub fn ISRManifest::empty() -> ISRManifest {
  { version: 1, pages: {} }
}

///|
/// Create a new empty ISR manifest (alias for empty)
pub fn ISRManifest::new() -> ISRManifest {
  ISRManifest::empty()
}

///|
/// Add a page to the manifest
pub fn ISRManifest::add(
  self : ISRManifest,
  url_path : String,
  entry : ISRPageMeta,
) -> Unit {
  self.pages[url_path] = entry
}

///|
/// Check if manifest has any ISR pages
pub fn ISRManifest::is_empty(self : ISRManifest) -> Bool {
  self.pages.is_empty()
}

///|
/// Get number of ISR pages
pub fn ISRManifest::len(self : ISRManifest) -> Int {
  self.pages.length()
}

///|
/// Check if a path is an ISR page
pub fn ISRManifest::is_isr_page(self : ISRManifest, path : String) -> Bool {
  self.pages.contains(path)
}

///|
/// Get ISR config for a path
pub fn ISRManifest::get_page(self : ISRManifest, path : String) -> ISRPageMeta? {
  self.pages.get(path)
}
