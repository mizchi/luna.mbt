// CSS Optimizer Analyzer
// Main entry point for CSS co-occurrence analysis

///|
/// Analyze class usages and generate optimization suggestions
pub fn analyze(
  usages : Array[ClassUsage],
  class_declarations : Map[String, Declaration],
  min_support : Int,
) -> AnalysisResult {
  // Step 1: Build co-occurrence matrix
  let matrix = build_cooccurrence_matrix(usages)
  let cooccurrences = matrix_to_cooccurrences(matrix)

  // Step 2: Find frequent patterns
  let patterns = find_frequent_patterns(usages, min_support)

  // Step 3: Generate merge suggestions
  let suggestions = generate_suggestions(patterns, class_declarations)
  { usages, cooccurrences, patterns, suggestions }
}

///|
/// Generate a full report from analysis result
pub fn generate_report(result : AnalysisResult) -> String {
  let mut report = "# CSS Optimization Report\n\n"

  // Summary
  report = report + "## Summary\n"
  report = report +
    "- Total class usages: " +
    result.usages.length().to_string() +
    "\n"
  report = report +
    "- Co-occurrence pairs: " +
    result.cooccurrences.length().to_string() +
    "\n"
  report = report +
    "- Frequent patterns: " +
    result.patterns.length().to_string() +
    "\n"
  report = report +
    "- Merge suggestions: " +
    result.suggestions.length().to_string() +
    "\n\n"

  // Top co-occurrences
  report = report + "## Top Co-occurring Pairs\n\n"
  let top_co = top_cooccurrences(result.cooccurrences, 10)
  for co in top_co {
    report = report +
      "- " +
      co.class_a +
      " + " +
      co.class_b +
      " (" +
      co.frequency.to_string() +
      " times)\n"
  }
  report = report + "\n"

  // Frequent patterns
  report = report + "## Frequent Patterns\n\n"
  let limit = if result.patterns.length() < 10 {
    result.patterns.length()
  } else {
    10
  }
  for i in 0..<limit {
    let pattern = result.patterns[i]
    let classes_str = pattern.classes
      .iter()
      .fold(init="", fn(acc, c) { if acc == "" { c } else { acc + ", " + c } })
    report = report +
      "- [" +
      classes_str +
      "] (" +
      pattern.frequency.to_string() +
      " times, ~" +
      pattern.potential_savings.to_string() +
      " bytes)\n"
  }
  report = report + "\n"

  // Merge suggestions
  report = report + "## Merge Suggestions\n\n"
  let suggestion_limit = if result.suggestions.length() < 5 {
    result.suggestions.length()
  } else {
    5
  }
  for i in 0..<suggestion_limit {
    report = report + suggestion_to_report(result.suggestions[i]) + "\n\n"
  }

  // Total potential savings
  let mut total_savings = 0
  for s in result.suggestions {
    total_savings = total_savings + s.bytes_saved
  }
  report = report + "## Total Potential Savings\n\n"
  report = report + "~" + total_savings.to_string() + " bytes\n"
  report
}

///|
/// Generate optimized CSS from suggestions
pub fn generate_optimized_css(
  suggestions : Array[MergeSuggestion],
  original_css : Map[String, String],
) -> String {
  let mut css = ""

  // Add merged rules
  for s in suggestions {
    css = css + suggestion_to_css(s) + "\n"
  }

  // Add remaining original rules (not merged)
  let merged_classes : Map[String, Bool] = {}
  for s in suggestions {
    for c in s.original_classes {
      merged_classes[c] = true
    }
  }
  original_css.each(fn(class_name, rule) {
    if not(merged_classes.contains(class_name)) {
      css = css + rule + "\n"
    }
  })
  css
}
