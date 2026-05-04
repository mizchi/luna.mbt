// CSS Direct API - Property names exposed, compression automatic
//
// Design philosophy:
// - CSS property names are NOT abstracted
// - User writes real CSS, system handles compression
// - No Tailwind-style vocabulary to learn

// ============================================================================
// Core API
// ============================================================================

/// Style registry: declaration → short class name
struct StyleRegistry {
  // "display:flex" → "_a"
  decl_to_class : @hashmap.HashMap[String, String]
  // All declarations in order (for deterministic output)
  declarations : Array[String]
  // Counter for class name generation
  mut counter : Int
}

let registry : StyleRegistry = {
  decl_to_class: @hashmap.new(),
  declarations: [],
  counter: 0,
}

/// Generate short class name
fn next_class_name() -> String {
  let chars = "abcdefghijklmnopqrstuvwxyz"
  let n = registry.counter
  registry.counter += 1
  let name = if n < 26 {
    chars[n].to_string()
  } else {
    chars[n % 26].to_string() + (n / 26).to_string()
  }
  "_" + name  // Prefix to avoid collision
}

/// Core function: css property-value pair
pub fn css(property : String, value : String) -> @luna.Attr {
  let decl = property + ":" + value

  let class_name = match registry.decl_to_class.get(decl) {
    Some(cls) => cls
    None => {
      let cls = next_class_name()
      registry.decl_to_class.set(decl, cls)
      registry.declarations.push(decl)
      cls
    }
  }

  @luna.attr("class", class_name)
}

/// Multiple CSS properties at once
pub fn styles(props : Array[(String, String)]) -> @luna.Attr {
  let classes : Array[String] = []
  for pair in props {
    let (property, value) = pair
    let decl = property + ":" + value

    let class_name = match registry.decl_to_class.get(decl) {
      Some(cls) => cls
      None => {
        let cls = next_class_name()
        registry.decl_to_class.set(decl, cls)
        registry.declarations.push(decl)
        cls
      }
    }
    classes.push(class_name)
  }

  @luna.attr("class", classes.join(" "))
}

// ============================================================================
// Output Generation
// ============================================================================

/// Generate CSS output (minified)
pub fn generate_css() -> String {
  let buf = StringBuilder::new()
  for decl in registry.declarations {
    match registry.decl_to_class.get(decl) {
      Some(cls) => {
        buf.write_string(".")
        buf.write_string(cls)
        buf.write_string("{")
        buf.write_string(decl)
        buf.write_string("}")
      }
      None => ()
    }
  }
  buf.to_string()
}

/// Generate CSS output (readable)
pub fn generate_css_pretty() -> String {
  let buf = StringBuilder::new()
  for decl in registry.declarations {
    match registry.decl_to_class.get(decl) {
      Some(cls) => {
        buf.write_string(".")
        buf.write_string(cls)
        buf.write_string(" { ")
        buf.write_string(decl)
        buf.write_string(" }\n")
      }
      None => ()
    }
  }
  buf.to_string()
}

// ============================================================================
// Usage Examples
// ============================================================================

// Example 1: Basic card
// fn card() -> @luna.Node {
//   @luna.h("div", [
//     css("display", "flex"),
//     css("align-items", "center"),
//     css("padding", "1rem"),
//     css("border-radius", "0.5rem"),
//     css("box-shadow", "0 1px 3px rgba(0,0,0,0.1)"),
//   ], [
//     @luna.text("Card content")
//   ])
// }
//
// Output: <div class="_a _b _c _d _e">Card content</div>

// Example 2: Using styles() for multiple props
// fn button() -> @luna.Node {
//   @luna.h("button", [
//     styles([
//       ("display", "inline-flex"),
//       ("align-items", "center"),
//       ("padding", "0.5rem 1rem"),
//       ("font-weight", "500"),
//       ("border-radius", "0.375rem"),
//       ("cursor", "pointer"),
//     ]),
//   ], [
//     @luna.text("Click me")
//   ])
// }

// Example 3: Reusing styles (automatic dedup)
// fn flex_center() -> Array[(String, String)] {
//   [("display", "flex"), ("align-items", "center"), ("justify-content", "center")]
// }
//
// fn modal_overlay() -> @luna.Node {
//   @luna.h("div", [styles(flex_center())], [...])
// }
//
// fn dialog() -> @luna.Node {
//   @luna.h("div", [styles(flex_center())], [...])  // Same classes reused!
// }

// ============================================================================
// Generated CSS Example
// ============================================================================

// After rendering card() and button():
//
// ._a{display:flex}
// ._b{align-items:center}
// ._c{padding:1rem}
// ._d{border-radius:0.5rem}
// ._e{box-shadow:0 1px 3px rgba(0,0,0,0.1)}
// ._f{display:inline-flex}
// ._g{padding:0.5rem 1rem}
// ._h{font-weight:500}
// ._i{border-radius:0.375rem}
// ._j{cursor:pointer}
//
// Note: "_b" (align-items:center) is shared between card and button!

// ============================================================================
// Pseudo-classes & Pseudo-elements
// ============================================================================

// Design: Use CSS pseudo-selector names directly
// Format: on(":pseudo", "property", "value")

/// Pseudo-class/element registry
struct PseudoRegistry {
  // ":hover:background:#2563eb" → "_h0"
  pseudo_to_class : @hashmap.HashMap[String, String]
  mut hover_counter : Int
  mut focus_counter : Int
  mut active_counter : Int
  // ... other counters
}

let pseudo_registry : PseudoRegistry = {
  pseudo_to_class: @hashmap.new(),
  hover_counter: 0,
  focus_counter: 0,
  active_counter: 0,
}

/// Generic pseudo-class handler
/// on(":hover", "background", "#2563eb")
/// on(":focus", "outline", "2px solid blue")
/// on("::before", "content", "\"→\"")
pub fn on(pseudo : String, property : String, value : String) -> @luna.Attr {
  let decl = pseudo + ":" + property + ":" + value

  let class_name = match pseudo_registry.pseudo_to_class.get(decl) {
    Some(cls) => cls
    None => {
      // Generate class name based on pseudo type
      let prefix = match pseudo {
        ":hover" => { pseudo_registry.hover_counter += 1; "_h" + pseudo_registry.hover_counter.to_string() }
        ":focus" => { pseudo_registry.focus_counter += 1; "_f" + pseudo_registry.focus_counter.to_string() }
        ":active" => { pseudo_registry.active_counter += 1; "_ac" + pseudo_registry.active_counter.to_string() }
        _ => next_class_name()  // Fallback to generic
      }
      pseudo_registry.pseudo_to_class.set(decl, prefix)
      prefix
    }
  }

  @luna.attr("class", class_name)
}

/// Convenience wrappers (optional, for common pseudo-classes)
pub fn hover(property : String, value : String) -> @luna.Attr {
  on(":hover", property, value)
}

pub fn focus(property : String, value : String) -> @luna.Attr {
  on(":focus", property, value)
}

pub fn active(property : String, value : String) -> @luna.Attr {
  on(":active", property, value)
}

// ============================================================================
// Media Queries
// ============================================================================

// Design: Use CSS media query syntax directly
// Format: media("condition", "property", "value")

struct MediaRegistry {
  // "@media(min-width:768px):padding:2rem" → "_m0"
  media_to_class : @hashmap.HashMap[String, String]
  mut counter : Int
}

let media_registry : MediaRegistry = {
  media_to_class: @hashmap.new(),
  counter: 0,
}

/// Generic media query handler
/// media("min-width: 768px", "padding", "2rem")
/// media("prefers-color-scheme: dark", "background", "#1a1a1a")
pub fn media(condition : String, property : String, value : String) -> @luna.Attr {
  let decl = "@media(" + condition + "):" + property + ":" + value

  let class_name = match media_registry.media_to_class.get(decl) {
    Some(cls) => cls
    None => {
      let cls = "_m" + media_registry.counter.to_string()
      media_registry.counter += 1
      media_registry.media_to_class.set(decl, cls)
      cls
    }
  }

  @luna.attr("class", class_name)
}

/// Breakpoint convenience wrappers
pub fn at_sm(property : String, value : String) -> @luna.Attr {
  media("min-width: 640px", property, value)
}

pub fn at_md(property : String, value : String) -> @luna.Attr {
  media("min-width: 768px", property, value)
}

pub fn at_lg(property : String, value : String) -> @luna.Attr {
  media("min-width: 1024px", property, value)
}

pub fn at_xl(property : String, value : String) -> @luna.Attr {
  media("min-width: 1280px", property, value)
}

/// Dark mode convenience wrapper
pub fn dark(property : String, value : String) -> @luna.Attr {
  media("prefers-color-scheme: dark", property, value)
}

// ============================================================================
// CSS Output with Pseudo & Media
// ============================================================================

/// Generate complete CSS output (including pseudo-classes and media queries)
pub fn generate_full_css() -> String {
  let buf = StringBuilder::new()

  // Base styles
  for decl in registry.declarations {
    match registry.decl_to_class.get(decl) {
      Some(cls) => {
        buf.write_string(".")
        buf.write_string(cls)
        buf.write_string("{")
        buf.write_string(decl)
        buf.write_string("}")
      }
      None => ()
    }
  }

  // Pseudo-class styles
  for entry in pseudo_registry.pseudo_to_class.iter() {
    let (decl, cls) = entry
    // Parse ":hover:background:#2563eb" → ".cls:hover{background:#2563eb}"
    // Implementation would split by first ":" occurrence
    buf.write_string(".")
    buf.write_string(cls)
    // ... parse and output
  }

  // Media query styles (grouped by condition)
  // @media(min-width:768px){._m0{padding:2rem}._m1{font-size:1.25rem}}
  // Implementation would group by condition

  buf.to_string()
}

// ============================================================================
// Usage Examples
// ============================================================================

// Example: Interactive button with responsive sizing
// fn button() -> @luna.Node {
//   @luna.h("button", [
//     // Base styles
//     css("display", "inline-flex"),
//     css("align-items", "center"),
//     css("padding", "0.5rem 1rem"),
//     css("background", "#3b82f6"),
//     css("color", "white"),
//     css("border-radius", "0.375rem"),
//     css("cursor", "pointer"),
//
//     // Pseudo-classes
//     hover("background", "#2563eb"),
//     focus("outline", "2px solid #93c5fd"),
//     focus("outline-offset", "2px"),
//     active("transform", "scale(0.98)"),
//
//     // Responsive
//     at_md("padding", "0.75rem 1.5rem"),
//     at_lg("font-size", "1.125rem"),
//   ], [...])
// }
//
// Generated CSS:
// ._a{display:inline-flex}
// ._b{align-items:center}
// ._c{padding:0.5rem 1rem}
// ._d{background:#3b82f6}
// ._e{color:white}
// ._f{border-radius:0.375rem}
// ._g{cursor:pointer}
// ._h1:hover{background:#2563eb}
// ._f1:focus{outline:2px solid #93c5fd}
// ._f2:focus{outline-offset:2px}
// ._ac1:active{transform:scale(0.98)}
// @media(min-width:768px){._m0{padding:0.75rem 1.5rem}}
// @media(min-width:1024px){._m1{font-size:1.125rem}}

// Example: Dark mode support
// fn card() -> @luna.Node {
//   @luna.h("div", [
//     css("background", "white"),
//     css("color", "#1a1a1a"),
//     dark("background", "#1a1a1a"),
//     dark("color", "white"),
//   ], [...])
// }

// Example: Complex pseudo-elements
// fn list_item() -> @luna.Node {
//   @luna.h("li", [
//     css("position", "relative"),
//     css("padding-left", "1.5rem"),
//     on("::before", "content", "\"•\""),
//     on("::before", "position", "absolute"),
//     on("::before", "left", "0"),
//   ], [...])
// }

// ============================================================================
// Shadow DOM Support - Configurable Style Mode
// ============================================================================

/// Style injection mode for Shadow DOM
pub enum StyleMode {
  /// Keep SSR-injected <style> elements (simple, default)
  Inline
  /// Use Adoptable Stylesheets for sharing (efficient for many components)
  Adoptable
}

/// Style system configuration
pub struct StyleConfig {
  mode : StyleMode
  /// For Adoptable mode: preload global sheet at init
  preload_sheet : Bool
}

/// Default configuration: Inline mode (simplest)
pub let default_style_config : StyleConfig = {
  mode: Inline,
  preload_sheet: false,
}

// FFI for Adoptable Stylesheets
//
// extern "js" fn create_adoptable_sheet(css : String) -> @js.Any =
//   #| (css) => {
//   #|   const sheet = new CSSStyleSheet();
//   #|   sheet.replaceSync(css);
//   #|   window.__LUNA_STYLES__ = sheet;
//   #|   return sheet;
//   #| }
//
// extern "js" fn adopt_styles(shadow_root : @js.Any) -> Unit =
//   #| (root) => {
//   #|   if (window.__LUNA_STYLES__) {
//   #|     root.adoptedStyleSheets = [window.__LUNA_STYLES__];
//   #|   }
//   #| }
//
// extern "js" fn remove_utility_styles(shadow_root : @js.Any) -> Unit =
//   #| (root) => {
//   #|   root.querySelectorAll('style[data-luna-utility]').forEach(s => s.remove());
//   #| }

/// Initialize style system with configuration
// pub fn init_styles(config : StyleConfig) -> Unit {
//   match config.mode {
//     Inline => ()  // No-op: styles already in SSR output
//     Adoptable => {
//       if config.preload_sheet {
//         let css = generate_full_css()
//         let _ = create_adoptable_sheet(css)
//       }
//     }
//   }
// }

/// Hydrate styles for a shadow root based on configuration
// pub fn hydrate_styles(shadow : @js.Any, config : StyleConfig) -> Unit {
//   match config.mode {
//     Inline => ()  // Keep SSR styles as-is
//     Adoptable => {
//       // Remove SSR utility styles, adopt shared sheet
//       remove_utility_styles(shadow)
//       adopt_styles(shadow)
//     }
//   }
// }

// ============================================================================
// SSR Output Helpers
// ============================================================================

/// Generate <style> tag for SSR (mode-aware)
// pub fn render_utility_styles(css : String, config : StyleConfig) -> String {
//   match config.mode {
//     Inline => "<style>" + css + "</style>"
//     Adoptable => "<style data-luna-utility>" + css + "</style>"
//   }
// }
