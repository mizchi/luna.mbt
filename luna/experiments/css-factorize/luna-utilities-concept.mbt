// Luna Utilities - Compression-first CSS utility system
//
// Design goals:
// 1. Type-safe utility API
// 2. Minimal output (single-char class names)
// 3. No collision with external CSS (prefixed)
// 4. Tree-shakeable (only used utilities emitted)

// ============================================================================
// Core Types
// ============================================================================

/// Spacing scale (matches Tailwind's default)
pub enum Spacing {
  S0      // 0
  S1      // 0.25rem
  S2      // 0.5rem
  S3      // 0.75rem
  S4      // 1rem
  S5      // 1.25rem
  S6      // 1.5rem
  S8      // 2rem
  S10     // 2.5rem
  S12     // 3rem
  S16     // 4rem
  Spx(Int) // arbitrary: px value
}

/// Display types
pub enum Display {
  Flex
  InlineFlex
  Block
  InlineBlock
  Grid
  Hidden
}

/// Flex alignment
pub enum Align {
  Start
  Center
  End
  Stretch
  Baseline
}

/// Flex justify
pub enum Justify {
  Start
  Center
  End
  Between
  Around
  Evenly
}

/// Border radius
pub enum Radius {
  None
  Sm
  Md
  Lg
  Xl
  Full
}

// ============================================================================
// Utility Registry (tracks used utilities for output)
// ============================================================================

/// Global registry of used utilities
struct UtilityRegistry {
  used: @hashset.HashSet[String]
  definitions: @hashmap.HashMap[String, String]
}

let registry: UtilityRegistry = {
  used: @hashset.new(),
  definitions: @hashmap.new()
}

/// Register a utility and return its class name
fn register(id: String, css: String) -> String {
  registry.definitions.set(id, css)
  registry.used.insert(id)
  "_" + id  // Prefixed class name
}

// ============================================================================
// Utility Functions
// ============================================================================

/// Display utilities
pub fn flex() -> @luna.Attr {
  let cls = register("f", "display:flex")
  @luna.attr("class", cls)
}

pub fn inline_flex() -> @luna.Attr {
  let cls = register("if", "display:inline-flex")
  @luna.attr("class", cls)
}

pub fn grid() -> @luna.Attr {
  let cls = register("g", "display:grid")
  @luna.attr("class", cls)
}

pub fn block() -> @luna.Attr {
  let cls = register("b", "display:block")
  @luna.attr("class", cls)
}

pub fn hidden() -> @luna.Attr {
  let cls = register("h", "display:none")
  @luna.attr("class", cls)
}

/// Flex alignment
pub fn items(align: Align) -> @luna.Attr {
  let (id, value) = match align {
    Start => ("is", "flex-start")
    Center => ("ic", "center")
    End => ("ie", "flex-end")
    Stretch => ("ist", "stretch")
    Baseline => ("ib", "baseline")
  }
  let cls = register(id, "align-items:" + value)
  @luna.attr("class", cls)
}

pub fn justify(j: Justify) -> @luna.Attr {
  let (id, value) = match j {
    Start => ("js", "flex-start")
    Center => ("jc", "center")
    End => ("je", "flex-end")
    Between => ("jb", "space-between")
    Around => ("ja", "space-around")
    Evenly => ("jev", "space-evenly")
  }
  let cls = register(id, "justify-content:" + value)
  @luna.attr("class", cls)
}

/// Spacing utilities
fn spacing_value(s: Spacing) -> String {
  match s {
    S0 => "0"
    S1 => "0.25rem"
    S2 => "0.5rem"
    S3 => "0.75rem"
    S4 => "1rem"
    S5 => "1.25rem"
    S6 => "1.5rem"
    S8 => "2rem"
    S10 => "2.5rem"
    S12 => "3rem"
    S16 => "4rem"
    Spx(n) => n.to_string() + "px"
  }
}

fn spacing_id(prefix: String, s: Spacing) -> String {
  prefix + match s {
    S0 => "0"
    S1 => "1"
    S2 => "2"
    S3 => "3"
    S4 => "4"
    S5 => "5"
    S6 => "6"
    S8 => "8"
    S10 => "10"
    S12 => "12"
    S16 => "16"
    Spx(n) => "px" + n.to_string()
  }
}

pub fn p(s: Spacing) -> @luna.Attr {
  let id = spacing_id("p", s)
  let cls = register(id, "padding:" + spacing_value(s))
  @luna.attr("class", cls)
}

pub fn px(s: Spacing) -> @luna.Attr {
  let id = spacing_id("px", s)
  let v = spacing_value(s)
  let cls = register(id, "padding-left:" + v + ";padding-right:" + v)
  @luna.attr("class", cls)
}

pub fn py(s: Spacing) -> @luna.Attr {
  let id = spacing_id("py", s)
  let v = spacing_value(s)
  let cls = register(id, "padding-top:" + v + ";padding-bottom:" + v)
  @luna.attr("class", cls)
}

pub fn m(s: Spacing) -> @luna.Attr {
  let id = spacing_id("m", s)
  let cls = register(id, "margin:" + spacing_value(s))
  @luna.attr("class", cls)
}

pub fn gap(s: Spacing) -> @luna.Attr {
  let id = spacing_id("gap", s)
  let cls = register(id, "gap:" + spacing_value(s))
  @luna.attr("class", cls)
}

/// Border radius
pub fn rounded(r: Radius) -> @luna.Attr {
  let (id, value) = match r {
    None => ("r0", "0")
    Sm => ("rs", "0.125rem")
    Md => ("rm", "0.375rem")
    Lg => ("rl", "0.5rem")
    Xl => ("rx", "0.75rem")
    Full => ("rf", "9999px")
  }
  let cls = register(id, "border-radius:" + value)
  @luna.attr("class", cls)
}

// ============================================================================
// CSS Output
// ============================================================================

/// Generate CSS for all used utilities
pub fn generate_css() -> String {
  let buf = StringBuilder::new()
  for id in registry.used.iter() {
    match registry.definitions.get(id) {
      Some(css) => {
        buf.write_string("._")
        buf.write_string(id)
        buf.write_string("{")
        buf.write_string(css)
        buf.write_string("}")
      }
      None => ()
    }
  }
  buf.to_string()
}

// ============================================================================
// Usage Example
// ============================================================================

// fn card_component() -> @luna.Node {
//   @luna.h("div", [
//     flex(),
//     items(Center),
//     justify(Between),
//     p(S4),
//     gap(S2),
//     rounded(Lg),
//   ], [
//     @luna.text("Card content")
//   ])
// }
//
// Output HTML: <div class="_f _ic _jb _p4 _gap2 _rl">Card content</div>
//
// Generated CSS (only used utilities):
// ._f{display:flex}
// ._ic{align-items:center}
// ._jb{justify-content:space-between}
// ._p4{padding:1rem}
// ._gap2{gap:0.5rem}
// ._rl{border-radius:0.5rem}
