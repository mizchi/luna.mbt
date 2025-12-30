// Frequent Pattern Mining for CSS Classes
// Finds sets of classes that frequently appear together

///|
/// Find frequent patterns using a greedy approach
/// 1. Start with most frequent pairs
/// 2. Try to extend patterns by adding more classes
/// 3. Keep patterns that appear >= min_support times
pub fn find_frequent_patterns(
  usages : Array[ClassUsage],
  min_support : Int,
) -> Array[FrequentPattern] {
  // Build frequency map for each class set
  let pattern_counts : Map[String, Int] = {}

  // Count all 2-class patterns
  for usage in usages {
    let classes = usage.classes.copy()
    classes.sort_by(fn(a, b) { a.compare(b) })
    let n = classes.length()

    // Count pairs
    for i = 0; i < n; i = i + 1 {
      for j = i + 1; j < n; j = j + 1 {
        let key = classes[i] + "|" + classes[j]
        match pattern_counts.get(key) {
          Some(count) => pattern_counts.set(key, count + 1)
          None => pattern_counts.set(key, 1)
        }
      }
    }

    // Count triples (for larger patterns)
    for i = 0; i < n; i = i + 1 {
      for j = i + 1; j < n; j = j + 1 {
        for k = j + 1; k < n; k = k + 1 {
          let key = classes[i] + "|" + classes[j] + "|" + classes[k]
          match pattern_counts.get(key) {
            Some(count) => pattern_counts.set(key, count + 1)
            None => pattern_counts.set(key, 1)
          }
        }
      }
    }
  }

  // Filter by min_support and convert to patterns
  let patterns : Array[FrequentPattern] = []
  pattern_counts.each(fn(key, frequency) {
    if frequency >= min_support {
      let views = key.split("|").collect()
      let classes : Array[String] = []
      for v in views {
        classes.push(v.to_string())
      }
      // Estimate savings: each class is ~20 bytes, merged saves (n-1)*usage bytes
      let class_count = classes.length()
      let potential_savings = (class_count - 1) * frequency * 8 // rough estimate
      patterns.push({ classes, frequency, potential_savings })
    }
  })

  // Sort by potential savings descending
  patterns.sort_by(fn(a, b) { b.potential_savings - a.potential_savings })

  // Remove subsumed patterns (if A⊂B and freq(A)≈freq(B), keep only B)
  remove_subsumed_patterns(patterns)
}

///|
/// Remove patterns that are subsets of larger patterns with similar frequency
fn remove_subsumed_patterns(
  patterns : Array[FrequentPattern],
) -> Array[FrequentPattern] {
  let result : Array[FrequentPattern] = []
  for i = 0, len = patterns.length(); i < len; i = i + 1 {
    let pattern = patterns[i]
    let dominated = is_dominated(pattern, patterns, i)
    if not(dominated) {
      result.push(pattern)
    }
  }
  result
}

///|
/// Check if pattern is dominated by a larger pattern
fn is_dominated(
  pattern : FrequentPattern,
  all_patterns : Array[FrequentPattern],
  self_index : Int,
) -> Bool {
  let pattern_set = set_from_array(pattern.classes)
  for i = 0, len = all_patterns.length(); i < len; i = i + 1 {
    if i != self_index {
      let other = all_patterns[i]
      // Check if other is a superset with similar or higher frequency
      if other.classes.length() > pattern.classes.length() &&
        other.frequency >= pattern.frequency * 8 / 10 {
        // 80% threshold
        let other_set = set_from_array(other.classes)
        if is_subset(pattern_set, other_set) {
          return true
        }
      }
    }
  }
  false
}

///|
/// Convert array to set (using Map as set)
fn set_from_array(arr : Array[String]) -> Map[String, Bool] {
  let set : Map[String, Bool] = {}
  for item in arr {
    set[item] = true
  }
  set
}

///|
/// Check if a is subset of b
fn is_subset(a : Map[String, Bool], b : Map[String, Bool]) -> Bool {
  let mut all_in = true
  a.each(fn(item, _) { if not(b.contains(item)) { all_in = false } })
  all_in
}

///|
/// Group usages by exact class set
pub fn group_by_class_set(
  usages : Array[ClassUsage],
) -> Map[String, Array[ClassUsage]] {
  let groups : Map[String, Array[ClassUsage]] = {}
  for usage in usages {
    let classes = usage.classes.copy()
    classes.sort_by(fn(a, b) { a.compare(b) })
    let key = classes
      .iter()
      .fold(init="", fn(acc, c) { if acc == "" { c } else { acc + "|" + c } })
    match groups.get(key) {
      Some(arr) => arr.push(usage)
      None => {
        let arr : Array[ClassUsage] = []
        arr.push(usage)
        groups.set(key, arr)
      }
    }
  }
  groups
}
