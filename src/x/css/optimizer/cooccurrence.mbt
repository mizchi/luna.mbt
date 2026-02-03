// Co-occurrence Matrix Builder
// Analyzes which CSS classes frequently appear together

///|
/// Build co-occurrence counts from class usages
pub fn build_cooccurrence_matrix(
  usages : Array[ClassUsage],
) -> Map[String, Map[String, Int]] {
  let matrix : Map[String, Map[String, Int]] = {}
  for usage in usages {
    let classes = usage.classes
    let n = classes.length()

    // Count all pairs (i, j) where i < j
    for i in 0..<n {
      let start = i + 1
      for j in start..<n {
        let a = classes[i]
        let b = classes[j]

        // Ensure consistent ordering (a < b alphabetically)
        let (first, second) = if a < b { (a, b) } else { (b, a) }

        // Increment count
        match matrix.get(first) {
          Some(inner) =>
            match inner.get(second) {
              Some(count) => inner.set(second, count + 1)
              None => inner.set(second, 1)
            }
          None => {
            let inner : Map[String, Int] = {}
            inner.set(second, 1)
            matrix.set(first, inner)
          }
        }
      }
    }
  }
  matrix
}

///|
/// Convert matrix to flat array of CoOccurrence
pub fn matrix_to_cooccurrences(
  matrix : Map[String, Map[String, Int]],
) -> Array[CoOccurrence] {
  let result : Array[CoOccurrence] = []
  matrix.each(fn(class_a, inner) {
    inner.each(fn(class_b, frequency) {
      result.push({ class_a, class_b, frequency })
    })
  })

  // Sort by frequency descending
  result.sort_by(fn(a, b) { b.frequency - a.frequency })
  result
}

///|
/// Get top N co-occurring pairs
pub fn top_cooccurrences(
  cooccurrences : Array[CoOccurrence],
  n : Int,
) -> Array[CoOccurrence] {
  let result : Array[CoOccurrence] = []
  let limit = if n < cooccurrences.length() {
    n
  } else {
    cooccurrences.length()
  }
  for i in 0..<limit {
    result.push(cooccurrences[i])
  }
  result
}

///|
/// Edge in adjacency list
pub struct Edge {
  target : String
  weight : Int
} derive(Show)

///|
/// Build adjacency list from co-occurrences (for graph algorithms)
pub fn build_adjacency_list(
  cooccurrences : Array[CoOccurrence],
  min_frequency : Int,
) -> Map[String, Array[Edge]] {
  let adj : Map[String, Array[Edge]] = {}
  for co in cooccurrences {
    if co.frequency >= min_frequency {
      // Add edge a -> b
      match adj.get(co.class_a) {
        Some(neighbors) =>
          neighbors.push({ target: co.class_b, weight: co.frequency })
        None => {
          let neighbors : Array[Edge] = []
          neighbors.push({ target: co.class_b, weight: co.frequency })
          adj[co.class_a] = neighbors
        }
      }

      // Add edge b -> a (undirected graph)
      match adj.get(co.class_b) {
        Some(neighbors) =>
          neighbors.push({ target: co.class_a, weight: co.frequency })
        None => {
          let neighbors : Array[Edge] = []
          neighbors.push({ target: co.class_a, weight: co.frequency })
          adj[co.class_b] = neighbors
        }
      }
    }
  }
  adj
}
