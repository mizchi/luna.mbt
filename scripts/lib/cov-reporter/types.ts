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
}

export function createDefaultConfig(projectRoot: string): CoverageConfig {
  return {
    projectRoot,
    coverageDir: `${projectRoot}/coverage`,
    sourceMapDir: `${projectRoot}/target/js/debug/build`,
    include: /^src\//,
    exclude: /_test\.mbt$/,
  };
}
