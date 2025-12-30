// Merge Suggestion Generator
// Generates suggestions for merging CSS classes based on patterns

/// Generate merge suggestions from frequent patterns
pub fn generate_suggestions(
  patterns : Array[FrequentPattern],
  class_declarations : Map[String, Declaration]
) -> Array[MergeSuggestion] {
  let suggestions : Array[MergeSuggestion] = []

  for pattern in patterns {
    // Collect declarations for all classes in pattern
    let declarations : Array[Declaration] = []

    for class_name in pattern.classes {
      match class_declarations.get(class_name) {
        Some(decl) => declarations.push(decl)
        None => () // Skip if declaration not found
      }
    }

    if declarations.length() > 0 {
      // Generate new class name from combined hash
      let new_class = generate_merged_class_name(declarations)

      // Calculate bytes saved
      // Before: n classes * ~8 bytes each in HTML, n rules in CSS
      // After: 1 class * ~8 bytes in HTML, 1 rule in CSS
      let class_count = pattern.classes.length()
      let html_savings = (class_count - 1) * 8 * pattern.frequency
      let css_savings = (class_count - 1) * 25 // ~25 bytes per rule
      let bytes_saved = html_savings + css_savings

      suggestions.push({
        original_classes: pattern.classes,
        new_class,
        declarations,
        usage_count: pattern.frequency,
        bytes_saved,
      })
    }
  }

  // Sort by bytes saved descending
  suggestions.sort_by(fn(a, b) { b.bytes_saved - a.bytes_saved })

  suggestions
}

/// Generate a class name for merged declarations
fn generate_merged_class_name(declarations : Array[Declaration]) -> String {
  // Combine all declarations into one string and hash
  let combined = declarations.iter().fold(
    init="",
    fn(acc, d) {
      if acc == "" {
        d.key()
      } else {
        acc + ";" + d.key()
      }
    },
  )

  // Use DJB2 hash
  let hash = djb2_hash(combined)
  "_m" + to_base36(hash) // prefix with 'm' for merged
}

/// DJB2 hash function
fn djb2_hash(s : String) -> Int {
  let mut hash = 5381
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].to_int()
    hash = ((hash << 5) + hash + c).land(0x7FFFFFFF)
  }
  hash.land(0xFFFFFF) // 24-bit
}

/// Convert to base36
fn to_base36(n : Int) -> String {
  let chars = "0123456789abcdefghijklmnopqrstuvwxyz"
  if n == 0 {
    return "0"
  }

  let mut result = ""
  let mut num = n.land(0xFFFFFF)

  while num > 0 {
    let idx = num % 36
    result = chars[idx].to_string() + result
    num = num / 36
  }

  result
}

/// Generate CSS output for a merge suggestion
pub fn suggestion_to_css(suggestion : MergeSuggestion) -> String {
  let declarations_str = suggestion.declarations.iter().fold(
    init="",
    fn(acc, d) {
      if acc == "" {
        d.property + ":" + d.value
      } else {
        acc + ";" + d.property + ":" + d.value
      }
    },
  )

  "." + suggestion.new_class + "{" + declarations_str + "}"
}

/// Generate readable report for a suggestion
pub fn suggestion_to_report(suggestion : MergeSuggestion) -> String {
  let original = suggestion.original_classes.iter().fold(
    init="",
    fn(acc, c) {
      if acc == "" {
        c
      } else {
        acc + " " + c
      }
    },
  )

  let decls = suggestion.declarations.iter().fold(
    init="",
    fn(acc, d) {
      if acc == "" {
        d.property + ": " + d.value
      } else {
        acc + ", " + d.property + ": " + d.value
      }
    },
  )

  "Merge: [" +
  original +
  "] -> " +
  suggestion.new_class +
  "\n" +
  "  Declarations: " +
  decls +
  "\n" +
  "  Usage: " +
  suggestion.usage_count.to_string() +
  " times\n" +
  "  Savings: ~" +
  suggestion.bytes_saved.to_string() +
  " bytes"
}
