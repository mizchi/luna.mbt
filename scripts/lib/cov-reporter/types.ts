/**
 * Coverage data types
 */

export interface LineCoverage {
  line: number;
  count: number;
}

export interface FileCoverage {
  path: string;
  lines: LineCoverage[];
  source?: string;
}

export interface CoverageStats {
  files: number;
  totalLines: number;
  coveredLines: number;
  rate: number;
}

export interface DirectoryStats {
  covered: number;
  total: number;
}

export interface CoverageConfig {
  projectRoot: string;
  coverageDir: string;
  sourceMapDir: string;
  include?: RegExp;
  exclude?: RegExp;
  /** Additional directories to exclude from coverage reporting */
  excludeDirs?: string[];
}

/**
 * Check if a file path should be excluded based on config
 */
export function shouldExcludeFile(
  filepath: string,
  config: CoverageConfig
): boolean {
  // Check regex exclude pattern
  if (config.exclude && config.exclude.test(filepath)) {
    return true;
  }
  // Check directory exclusions
  if (config.excludeDirs) {
    for (const dir of config.excludeDirs) {
      if (filepath.startsWith(dir + "/") || filepath === dir) {
        return true;
      }
    }
  }
  return false;
}

export function createDefaultConfig(projectRoot: string): CoverageConfig {
  return {
    projectRoot,
    coverageDir: `${projectRoot}/coverage`,
    sourceMapDir: `${projectRoot}/_build/js/debug/build`,
    include: /^src\//,
    exclude: /_test\.mbt$/,
    // Exclude benchmarks, examples, and test infrastructure
    excludeDirs: ["src/_bench", "src/examples", "src/tests"],
  };
}
