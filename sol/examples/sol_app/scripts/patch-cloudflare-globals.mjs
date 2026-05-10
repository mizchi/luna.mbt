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
  let body = readFileSync(serverJsPath, "utf8");

  const SEED_PATTERN = /const _M0FPB4seed = _M0FPB12random__seed\(\);/;
  const SEED_PATCHED = /const _M0FPB4seed = 0;/;
  if (SEED_PATTERN.test(body)) {
    body = body.replace(
      SEED_PATTERN,
      "const _M0FPB4seed = 0; /* patched: Workers disallow crypto in global scope */",
    );
    console.log("patched _M0FPB4seed eager init -> 0");
  } else if (SEED_PATCHED.test(body)) {
    console.log("_M0FPB4seed already patched, skipping");
  } else {
    throw new Error(
      `patch-cloudflare-globals: \`const _M0FPB4seed = ...\` not found in ${serverJsPath}.\n` +
        "MoonBit core may have changed the mangled symbol — update this script.",
    );
  }

  // Sol's run_app picks mode 0 (sync export of __SOL_APP__) only when
  // is_adapter_mode && !runtime_is_node. On Workers with nodejs_compat,
  // process.versions.node is populated, so runtime_is_node returns true and
  // run_app falls into mode 1 — which awaits a dynamic `import('node:fs')`
  // on the microtask queue and only then sets __SOL_APP__. main.js used to
  // setInterval-poll to wait, but Workers ban timers in global scope.
  // Force mode 0 so __SOL_APP__ lands synchronously when server.js is imported.
  const MODE_PATTERN = /const mode = _p && !_p\$2 \? 0 : 1;/;
  const MODE_PATCHED = /const mode = 0;/;
  if (MODE_PATTERN.test(body)) {
    body = body.replace(
      MODE_PATTERN,
      "const mode = 0; /* patched: force sync sol_app export on Cloudflare Workers */",
    );
    console.log("patched run_app mode -> 0 (sync export)");
  } else if (MODE_PATCHED.test(body)) {
    console.log("run_app mode already patched, skipping");
  } else {
    throw new Error(
      `patch-cloudflare-globals: run_app mode selector not found in ${serverJsPath}.`,
    );
  }

  writeFileSync(serverJsPath, body);
}

// 1.5) Build the assets tree the Workers ASSETS binding will serve.
//      `.sol/prod/__sol__/` (loader scripts) and `.sol/prod/static/` (island
//      bundles) live as siblings under .sol/prod/. The binding maps a single
//      directory to URL paths, so we materialize a dist-assets/ subtree that
//      preserves the `__sol__/` and `static/` URL prefixes the SSR HTML
//      references. Sibling `server/` is left out (it would expose worker
//      source as a static asset).
import { cpSync, rmSync, mkdirSync, existsSync } from "node:fs";
{
  const distAssets = resolve(sol_app, ".sol", "prod", "dist-assets");
  rmSync(distAssets, { recursive: true, force: true });
  mkdirSync(distAssets, { recursive: true });
  const srcSol = resolve(sol_app, ".sol", "prod", "__sol__");
  const srcStatic = resolve(sol_app, ".sol", "prod", "static");
  if (!existsSync(srcSol) || !existsSync(srcStatic)) {
    throw new Error(
      `patch-cloudflare-globals: expected .sol/prod/__sol__ and .sol/prod/static to exist; run \`sol build\` first.`,
    );
  }
  cpSync(srcSol, resolve(distAssets, "__sol__"), { recursive: true });
  cpSync(srcStatic, resolve(distAssets, "static"), { recursive: true });
  console.log("staged dist-assets/{__sol__,static}/ for ASSETS binding");
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
  const POLL_PATCHED = /const app = globalThis\.__SOL_APP__;/;
  if (POLL_PATTERN.test(original)) {
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
  } else if (POLL_PATCHED.test(original)) {
    console.log("main.js __SOL_APP__ poll already patched, skipping");
  } else {
    throw new Error(
      `patch-cloudflare-globals: setInterval poll block not found in ${mainJsPath}.\n` +
        "Sol's main.js template may have changed — update this script.",
    );
  }
}
