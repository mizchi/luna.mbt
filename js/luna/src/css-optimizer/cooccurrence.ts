/**
 * Co-occurrence analysis for CSS classes
 */

import type { ClassUsage, CoOccurrence } from "./types.js";

/**
 * Build a co-occurrence matrix from class usages
 * Returns a nested map: classA -> classB -> count
 * Classes are stored in alphabetical order (A < B)
 */
export function buildCooccurrenceMatrix(
  usages: ClassUsage[]
): Map<string, Map<string, number>> {
  const matrix = new Map<string, Map<string, number>>();

  for (const usage of usages) {
    const classes = usage.classes;
    const n = classes.length;

    // Count all pairs (i, j) where i < j
    for (let i = 0; i < n; i++) {
      for (let j = i + 1; j < n; j++) {
        const a = classes[i];
        const b = classes[j];

        // Ensure consistent ordering (a < b alphabetically)
        const [first, second] = a < b ? [a, b] : [b, a];

        if (!matrix.has(first)) {
          matrix.set(first, new Map());
        }
        const inner = matrix.get(first)!;
        inner.set(second, (inner.get(second) || 0) + 1);
      }
    }
  }

  return matrix;
}

/**
 * Convert matrix to a flat array of co-occurrences
 * Sorted by frequency descending
 */
export function matrixToCooccurrences(
  matrix: Map<string, Map<string, number>>
): CoOccurrence[] {
  const result: CoOccurrence[] = [];

  for (const [classA, inner] of matrix) {
    for (const [classB, frequency] of inner) {
      result.push({ classA, classB, frequency });
    }
  }

  // Sort by frequency descending
  result.sort((a, b) => b.frequency - a.frequency);

  return result;
}

/**
 * Get the top N co-occurring pairs
 */
export function getTopCooccurrences(
  cooccurrences: CoOccurrence[],
  n: number
): CoOccurrence[] {
  return cooccurrences.slice(0, n);
}

/**
 * Build an adjacency list for graph algorithms
 * Only includes pairs with frequency >= minFrequency
 */
export function buildAdjacencyList(
  cooccurrences: CoOccurrence[],
  minFrequency: number
): Map<string, Array<{ target: string; weight: number }>> {
  const adj = new Map<string, Array<{ target: string; weight: number }>>();

  for (const co of cooccurrences) {
    if (co.frequency >= minFrequency) {
      // Add edge a -> b
      if (!adj.has(co.classA)) {
        adj.set(co.classA, []);
      }
      adj.get(co.classA)!.push({ target: co.classB, weight: co.frequency });

      // Add edge b -> a (undirected graph)
      if (!adj.has(co.classB)) {
        adj.set(co.classB, []);
      }
      adj.get(co.classB)!.push({ target: co.classA, weight: co.frequency });
    }
  }

  return adj;
}
