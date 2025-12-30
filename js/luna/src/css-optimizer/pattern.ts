/**
 * Frequent pattern mining for CSS classes
 */

import type { ClassUsage, MergePattern } from "./types.js";

/**
 * Find frequent patterns (sets of classes that often appear together)
 * Uses a greedy enumeration approach for small pattern sizes
 */
export function findFrequentPatterns(
  usages: ClassUsage[],
  minFrequency: number,
  maxSize: number
): MergePattern[] {
  // Count all class set patterns
  const patternCounts = new Map<string, number>();

  for (const usage of usages) {
    const classes = [...usage.classes].sort();
    const n = classes.length;

    // Count pairs (size 2)
    for (let i = 0; i < n; i++) {
      for (let j = i + 1; j < n; j++) {
        const key = `${classes[i]}|${classes[j]}`;
        patternCounts.set(key, (patternCounts.get(key) || 0) + 1);
      }
    }

    // Count triples (size 3)
    if (maxSize >= 3) {
      for (let i = 0; i < n; i++) {
        for (let j = i + 1; j < n; j++) {
          for (let k = j + 1; k < n; k++) {
            const key = `${classes[i]}|${classes[j]}|${classes[k]}`;
            patternCounts.set(key, (patternCounts.get(key) || 0) + 1);
          }
        }
      }
    }

    // Count quadruples (size 4)
    if (maxSize >= 4) {
      for (let i = 0; i < n; i++) {
        for (let j = i + 1; j < n; j++) {
          for (let k = j + 1; k < n; k++) {
            for (let l = k + 1; l < n; l++) {
              const key = `${classes[i]}|${classes[j]}|${classes[k]}|${classes[l]}`;
              patternCounts.set(key, (patternCounts.get(key) || 0) + 1);
            }
          }
        }
      }
    }

    // Count quintuples (size 5)
    if (maxSize >= 5) {
      for (let i = 0; i < n; i++) {
        for (let j = i + 1; j < n; j++) {
          for (let k = j + 1; k < n; k++) {
            for (let l = k + 1; l < n; l++) {
              for (let m = l + 1; m < n; m++) {
                const key = `${classes[i]}|${classes[j]}|${classes[k]}|${classes[l]}|${classes[m]}`;
                patternCounts.set(key, (patternCounts.get(key) || 0) + 1);
              }
            }
          }
        }
      }
    }
  }

  // Filter by min frequency and create patterns
  const patterns: MergePattern[] = [];

  for (const [key, frequency] of patternCounts) {
    if (frequency >= minFrequency) {
      const originalClasses = key.split("|");
      const classCount = originalClasses.length;

      // Estimate savings:
      // HTML: each class is ~6 chars + space, merged saves (n-1) * 7 * frequency
      // CSS: each rule is ~25 bytes, merged saves (n-1) * 25
      const htmlSavings = (classCount - 1) * 7 * frequency;
      const cssSavings = (classCount - 1) * 25;
      const bytesSaved = htmlSavings + cssSavings;

      patterns.push({
        originalClasses,
        mergedClass: "", // Will be set during merge
        declarations: [], // Will be set during merge
        frequency,
        bytesSaved,
      });
    }
  }

  // Sort by bytes saved descending
  patterns.sort((a, b) => b.bytesSaved - a.bytesSaved);

  // Remove subsumed patterns
  return removeSubsumedPatterns(patterns);
}

/**
 * Remove patterns that are subsets of larger patterns with similar frequency
 * This prevents double-counting savings
 */
export function removeSubsumedPatterns(patterns: MergePattern[]): MergePattern[] {
  const result: MergePattern[] = [];

  for (let i = 0; i < patterns.length; i++) {
    const pattern = patterns[i];
    let isDominated = false;

    for (let j = 0; j < patterns.length; j++) {
      if (i === j) continue;

      const other = patterns[j];
      // Check if other is a superset with similar or higher frequency (80% threshold)
      if (
        other.originalClasses.length > pattern.originalClasses.length &&
        other.frequency >= pattern.frequency * 0.8
      ) {
        const patternSet = new Set(pattern.originalClasses);
        const otherSet = new Set(other.originalClasses);

        // Check if pattern is subset of other
        let isSubset = true;
        for (const cls of patternSet) {
          if (!otherSet.has(cls)) {
            isSubset = false;
            break;
          }
        }

        if (isSubset) {
          isDominated = true;
          break;
        }
      }
    }

    if (!isDominated) {
      result.push(pattern);
    }
  }

  return result;
}

/**
 * Group usages by their exact class set
 * Returns a map from sorted class key to array of usages
 */
export function groupByClassSet(
  usages: ClassUsage[]
): Map<string, ClassUsage[]> {
  const groups = new Map<string, ClassUsage[]>();

  for (const usage of usages) {
    const key = [...usage.classes].sort().join("|");
    if (!groups.has(key)) {
      groups.set(key, []);
    }
    groups.get(key)!.push(usage);
  }

  return groups;
}
