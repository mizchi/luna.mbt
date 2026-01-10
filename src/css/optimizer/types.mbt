// CSS Optimizer Types
// For analyzing co-occurrence patterns and suggesting CSS compression

///|
/// A single CSS declaration (property: value)
pub struct Declaration {
  property : String
  value : String
} derive(Eq, Compare, Hash, Show)

///|
/// A CSS rule: selector -> declarations
pub struct Rule {
  selector : String
  declarations : Array[Declaration]
} derive(Show)

///|
/// A class usage instance (which classes appear together on an element)
pub struct ClassUsage {
  /// Classes used on this element
  classes : Array[String]
  /// Source location for debugging
  source : String
} derive(Show)

///|
/// Co-occurrence pair with frequency
pub struct CoOccurrence {
  class_a : String
  class_b : String
  frequency : Int
} derive(Show)

///|
/// A frequent pattern: set of classes that often appear together
pub struct FrequentPattern {
  classes : Array[String]
  frequency : Int
  /// Combined CSS size if merged
  potential_savings : Int
} derive(Show)

///|
/// Merge suggestion
pub struct MergeSuggestion {
  /// Original classes to merge
  original_classes : Array[String]
  /// New combined class name
  new_class : String
  /// Combined declarations
  declarations : Array[Declaration]
  /// How many times this pattern is used
  usage_count : Int
  /// Bytes saved by merging
  bytes_saved : Int
} derive(Show)

///|
/// Analysis result
pub struct AnalysisResult {
  /// All class usages found
  usages : Array[ClassUsage]
  /// Co-occurrence matrix (sparse representation)
  cooccurrences : Array[CoOccurrence]
  /// Frequent patterns (sorted by potential savings)
  patterns : Array[FrequentPattern]
  /// Merge suggestions
  suggestions : Array[MergeSuggestion]
} derive(Show)

///|
/// Create a declaration
pub fn Declaration::new(property : String, value : String) -> Declaration {
  { property, value }
}

///|
/// Create declaration key for hashing
pub fn Declaration::key(self : Declaration) -> String {
  self.property + ":" + self.value
}

///|
/// Create a class usage
pub fn ClassUsage::new(classes : Array[String], source : String) -> ClassUsage {
  { classes, source }
}
