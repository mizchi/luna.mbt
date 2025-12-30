/// CSS Static Analyzer Types
///
/// Types for static analysis of MoonBit source code to detect
/// CSS class co-occurrences.

/// A CSS class usage detected in source code
pub(all) struct ClassCooccurrence {
  /// Class names that appear together on the same element
  classes : Array[String]
  /// Source file path
  file : String
  /// Line number in source
  line : Int
  /// Whether this is statically analyzable
  is_static : Bool
}

/// A warning about non-analyzable patterns
pub(all) struct AnalyzerWarning {
  /// Warning type
  kind : WarningKind
  /// Source file path
  file : String
  /// Line number
  line : Int
  /// Description
  message : String
}

/// Types of analyzer warnings
pub(all) enum WarningKind {
  /// Conditional class assignment
  DynamicConditional
  /// Function call result used as class
  DynamicFunctionCall
  /// Variable with unknown origin
  UntraceableVariable
  /// Spread or dynamic array construction
  DynamicArrayConstruction
}

/// Result of analyzing a source file
pub(all) struct FileAnalysisResult {
  /// Detected class co-occurrences
  cooccurrences : Array[ClassCooccurrence]
  /// Warnings about non-analyzable patterns
  warnings : Array[AnalyzerWarning]
}

/// Result of analyzing a project
pub(all) struct ProjectAnalysisResult {
  /// All co-occurrences from all files
  cooccurrences : Array[ClassCooccurrence]
  /// All warnings
  warnings : Array[AnalyzerWarning]
  /// Files analyzed
  files_analyzed : Int
}

/// Known CSS function patterns
pub(all) enum CssFunctionPattern {
  /// css(prop, value) -> single class
  CssSingle
  /// styles([(prop, value), ...]) -> multiple classes
  StylesArray
  /// hover(prop, value), focus(...), etc.
  PseudoClass(String)
}
