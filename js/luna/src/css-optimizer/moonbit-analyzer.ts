/**
 * MoonBit Static Analyzer Integration
 *
 * Calls the MoonBit-based CSS static analyzer to extract class co-occurrences
 * from MoonBit source files.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
import type { ClassCooccurrence, AnalyzerWarning, ClassUsage } from "./types.js";

// Lazy-loaded MoonBit analyzer module
let analyzerModule: { analyze_file_json: (source: string, file: string) => string } | null = null;

/**
 * Get the path to the MoonBit analyzer JS module
 */
function getAnalyzerPath(): string {
  // When running from dist, the analyzer is relative to the package
  const __dirname = path.dirname(fileURLToPath(import.meta.url));

  // Try multiple possible locations
  const candidates = [
    // Development: from dist/ to _build/ (bundled cli.mjs)
    path.resolve(__dirname, "../../../_build/js/release/build/luna/css/analyzer/analyzer.js"),
    // Development: from src/css-optimizer/ to _build/
    path.resolve(__dirname, "../../../../_build/js/release/build/luna/css/analyzer/analyzer.js"),
    // Installed package
    path.resolve(__dirname, "../moonbit/analyzer.js"),
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  throw new Error(
    `MoonBit analyzer not found. Tried:\n${candidates.join("\n")}\nRun 'moon build --target js src/luna/css/analyzer' first.`
  );
}

/**
 * Load the MoonBit analyzer module
 */
async function loadAnalyzer(): Promise<typeof analyzerModule> {
  if (analyzerModule) {
    return analyzerModule;
  }

  const analyzerPath = getAnalyzerPath();
  analyzerModule = await import(analyzerPath);
  return analyzerModule;
}

/**
 * Result from analyzing a single file
 */
export interface MoonBitAnalysisResult {
  cooccurrences: ClassCooccurrence[];
  warnings: AnalyzerWarning[];
}

/**
 * Analyze a single MoonBit source file
 */
export async function analyzeFile(
  source: string,
  filePath: string
): Promise<MoonBitAnalysisResult> {
  const analyzer = await loadAnalyzer();
  if (!analyzer) {
    throw new Error("Failed to load MoonBit analyzer");
  }

  const jsonResult = analyzer.analyze_file_json(source, filePath);
  return JSON.parse(jsonResult);
}

/**
 * Analyze all .mbt files in a directory
 */
export async function analyzeDirectory(
  dir: string,
  options: { recursive?: boolean } = {}
): Promise<MoonBitAnalysisResult> {
  const { recursive = true } = options;
  const allCooccurrences: ClassCooccurrence[] = [];
  const allWarnings: AnalyzerWarning[] = [];

  const files = findMbtFiles(dir, recursive);

  for (const file of files) {
    const source = fs.readFileSync(file, "utf-8");
    const result = await analyzeFile(source, file);
    allCooccurrences.push(...result.cooccurrences);
    allWarnings.push(...result.warnings);
  }

  return {
    cooccurrences: allCooccurrences,
    warnings: allWarnings,
  };
}

/**
 * Find all .mbt files in a directory
 */
function findMbtFiles(dir: string, recursive: boolean): string[] {
  const files: string[] = [];

  function walk(currentDir: string) {
    const entries = fs.readdirSync(currentDir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(currentDir, entry.name);

      if (entry.isDirectory()) {
        // Skip common non-source directories
        if (
          entry.name === "node_modules" ||
          entry.name === "_build" ||
          entry.name === "target" ||
          entry.name === ".git" ||
          entry.name === ".mooncakes"
        ) {
          continue;
        }

        if (recursive) {
          walk(fullPath);
        }
      } else if (entry.isFile() && entry.name.endsWith(".mbt")) {
        // Skip test files
        if (!entry.name.endsWith("_test.mbt")) {
          files.push(fullPath);
        }
      }
    }
  }

  walk(dir);
  return files;
}

/**
 * Convert MoonBit analysis result to css-optimizer input format
 */
export interface ConvertedResult {
  /** Class usages in css-optimizer format */
  usages: ClassUsage[];
  /** Map from class name to CSS declaration */
  classToDeclaration: Map<string, string>;
}

/**
 * Convert MoonBit analyzer output to css-optimizer format
 *
 * @param result - MoonBit analysis result
 * @param hashFn - Function to generate class name from declaration
 */
export function convertToOptimizerInput(
  result: MoonBitAnalysisResult,
  hashFn: (decl: string) => string
): ConvertedResult {
  const classToDeclaration = new Map<string, string>();
  const usages: ClassUsage[] = [];

  for (const co of result.cooccurrences) {
    // Only process static patterns (can be safely optimized)
    if (!co.isStatic) continue;

    const classes: string[] = [];

    for (const decl of co.classes) {
      const className = hashFn(decl);
      classToDeclaration.set(className, decl);
      classes.push(className);
    }

    usages.push({
      classes,
      source: `${co.file}:${co.line}`,
    });
  }

  return { usages, classToDeclaration };
}

/**
 * CLI entry point for testing
 */
export async function main(args: string[]): Promise<void> {
  const dir = args[0] || ".";

  console.error(`Analyzing MoonBit files in: ${dir}`);

  const result = await analyzeDirectory(dir);

  console.log(JSON.stringify(result, null, 2));

  if (result.warnings.length > 0) {
    console.error(`\nWarnings: ${result.warnings.length}`);
    for (const w of result.warnings) {
      console.error(`  ${w.file}:${w.line} - ${w.kind}: ${w.message}`);
    }
  }

  console.error(`\nFound ${result.cooccurrences.length} class co-occurrences`);
}
