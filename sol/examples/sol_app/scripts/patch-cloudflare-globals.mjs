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
const sol_app = resolve(__dirname, "..");

// 1) MoonBit core eagerly seeds hash randomization at module init via
//    crypto.getRandomValues. Replace the call site with a deterministic 0.
const serverJsPath = resolve(
  sol_app,
  "_build",
  "js",
  "release",
  "build",
  "__gen__",
  "server",
  "server.js",
);
{
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
  console.log("patched _M0FPB4seed eager init -> 0");
}

// 2) Sol's generated `.sol/prod/server/main.js` polls `globalThis.__SOL_APP__`
//    via `setInterval(..., 1)` in module top-level. The poll exists for the
//    Node adapter's async fs init; on edge runtimes (Cloudflare/Deno) the
//    value is set synchronously when server.js is imported, so the poll is
//    dead code and Workers reject the timer in global scope. Replace the
//    whole top-level block with the synchronous form.
const mainJsPath = resolve(sol_app, ".sol", "prod", "server", "main.js");
{
  const original = readFileSync(mainJsPath, "utf8");
  const POLL_PATTERN =
    /const app = await new Promise\(resolve => \{[\s\S]*?\}\);/;
  if (!POLL_PATTERN.test(original)) {
    throw new Error(
      `patch-cloudflare-globals: setInterval poll block not found in ${mainJsPath}.\n` +
        "Sol's main.js template may have changed — update this script.",
    );
  }
  const patched = original.replace(
    POLL_PATTERN,
    [
      "const app = globalThis.__SOL_APP__;",
      "/* patched by patch-cloudflare-globals.mjs: Cloudflare sets __SOL_APP__",
      "   synchronously on import, no setInterval needed (and Workers ban",
      "   timers in global scope anyway). */",
    ].join("\n"),
  );
  writeFileSync(mainJsPath, patched);
  console.log("patched main.js __SOL_APP__ poll -> sync access");
}
