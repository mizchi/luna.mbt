// Regression coverage for generated website HTML that references local
// static assets not emitted into the build output. This catches broken
// resource loads before the deployed docs ship them.

import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  existsSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  rmSync,
  statSync,
} from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..", "..");
const ASTRA_SHIM = path.join(ROOT, "js", "astra", "bin", "astra.js");
const WEBSITE_DIR = path.join(ROOT, "website");
const ASSET_EXTENSIONS = new Set([
  ".css",
  ".ico",
  ".js",
  ".json",
  ".map",
  ".png",
  ".svg",
  ".wasm",
  ".webp",
]);

function collectFiles(dir, predicate, results = []) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const filePath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      collectFiles(filePath, predicate, results);
    } else if (predicate(filePath)) {
      results.push(filePath);
    }
  }
  return results;
}

function decodeHtmlAttribute(value) {
  return value
    .replaceAll("&amp;", "&")
    .replaceAll("&quot;", '"')
    .replaceAll("&#39;", "'")
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">");
}

function stripQueryAndHash(value) {
  return value.split(/[?#]/, 1)[0] ?? "";
}

function isExternalReference(value) {
  return /^(?:[a-z][a-z0-9+.-]*:|\/\/)/i.test(value);
}

function resolveAssetPath(outDir, htmlFile, rawValue) {
  const value = stripQueryAndHash(decodeHtmlAttribute(rawValue).trim());
  if (
    value === "" ||
    value.startsWith("#") ||
    isExternalReference(value) ||
    !ASSET_EXTENSIONS.has(path.extname(value))
  ) {
    return null;
  }

  if (value.startsWith("/")) {
    return path.join(outDir, value.slice(1));
  }
  return path.resolve(path.dirname(htmlFile), value);
}

function referencedAssets(outDir) {
  const htmlFiles = collectFiles(outDir, (filePath) => filePath.endsWith(".html"));
  const refs = new Map();
  const attrRe = /\s(?:src|href|luna:wc-url|luna:url)=["']([^"']+)["']/g;

  for (const htmlFile of htmlFiles) {
    const html = readFileSync(htmlFile, "utf8");
    for (const match of html.matchAll(attrRe)) {
      const rawValue = match[1];
      const assetPath = resolveAssetPath(outDir, htmlFile, rawValue);
      if (!assetPath) {
        continue;
      }
      const pages = refs.get(assetPath) ?? [];
      pages.push(path.relative(outDir, htmlFile));
      refs.set(assetPath, pages);
    }
  }

  return refs;
}

test("website build emits every local asset referenced by generated HTML", () => {
  const outDir = mkdtempSync(path.join(tmpdir(), "luna-website-assets-"));
  try {
    const result = spawnSync(
      process.execPath,
      [ASTRA_SHIM, "build", "--out", outDir],
      { cwd: WEBSITE_DIR, encoding: "utf-8" },
    );
    assert.equal(
      result.status,
      0,
      `astra build failed:\nstdout=${result.stdout}\nstderr=${result.stderr}`,
    );

    const pagefind = spawnSync(
      "pnpm",
      ["exec", "pagefind", "--site", outDir],
      { cwd: ROOT, encoding: "utf-8" },
    );
    assert.equal(
      pagefind.status,
      0,
      `pagefind failed:\nstdout=${pagefind.stdout}\nstderr=${pagefind.stderr}`,
    );

    const missing = [...referencedAssets(outDir).entries()]
      .filter(([assetPath]) => !existsSync(assetPath) || !statSync(assetPath).isFile())
      .map(([assetPath, pages]) => ({
        asset: `/${path.relative(outDir, assetPath)}`,
        pages: [...new Set(pages)].slice(0, 5),
      }));

    assert.deepEqual(
      missing,
      [],
      `website build referenced missing local assets:\n${JSON.stringify(
        missing,
        null,
        2,
      )}`,
    );
  } finally {
    rmSync(outDir, { recursive: true, force: true });
  }
});
