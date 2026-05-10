#!/usr/bin/env node
// Cloudflare Workers disallow asynchronous I/O / random / timers in module
// global scope. MoonBit core eagerly seeds the hash randomization state at
// module init via `globalThis.crypto.getRandomValues`, which trips the
// 10021 validation error and rejects the deploy.
//
// Patch the built server.js so the eager seed call becomes a deterministic
// fallback (0). The seed is only used to randomize hash-table iteration
// order at startup — a deterministic value preserves correctness, only
// removes the DoS-resistance benefit of random hashing (acceptable for an
// example deploy).
//
// Upstream fix would live in moonbitlang/core or sol's cloudflare adapter
// (lazy-init the seed inside the first handler call). Until then this
// post-build patch keeps sol_app deployable to Workers.
import { readFileSync, writeFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const serverJsPath = resolve(
  __dirname,
  "..",
  "_build",
  "js",
  "release",
  "build",
  "__gen__",
  "server",
  "server.js",
);

const original = readFileSync(serverJsPath, "utf8");

const SEED_PATTERN = /const _M0FPB4seed = _M0FPB12random__seed\(\);/;

if (!SEED_PATTERN.test(original)) {
  throw new Error(
    `patch-cloudflare-globals: \`const _M0FPB4seed = _M0FPB12random__seed();\` not found in ${serverJsPath}.\n` +
      "MoonBit core may have changed the mangled symbol — update this script.",
  );
}

const patched = original.replace(
  SEED_PATTERN,
  "const _M0FPB4seed = 0; /* patched by patch-cloudflare-globals.mjs: Workers disallow crypto in global scope */",
);

writeFileSync(serverJsPath, patched);
console.log("patched _M0FPB4seed eager init -> 0 (Cloudflare Workers safe)");
