#!/usr/bin/env node
// Build a self-contained static tree of luna examples for Cloudflare Workers Static Assets.
//
// Output layout (luna/dist-demo/):
//   index.html                 — landing page (rewritten from luna/index.html)
//   <example>/index.html       — example HTML, with <script> rewritten to ./index.js
//   <example>/index.js         — moonbit-built JS for the example
//
// Prereq: `moon build --target js --release` so artifacts exist at
// _build/js/release/build/mizchi/luna/examples/<id>/<id>.js.
import { readFile, writeFile, mkdir, rm } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const lunaRoot = resolve(__dirname, "..");
const repoRoot = resolve(lunaRoot, "..");

const moonBuildBase = join(repoRoot, "_build", "js", "release", "build", "mizchi");
// luna's own examples build under mizchi/luna/examples, but apg-playground
// moved out into the mizchi/luna_components mooncake — different build root.
const buildSrcByMooncake = {
  luna: join(moonBuildBase, "luna", "examples"),
  luna_components: join(moonBuildBase, "luna_components", "examples"),
};
const examplesSrcByMooncake = {
  luna: join(lunaRoot, "src", "examples"),
  luna_components: join(repoRoot, "luna_components", "src", "examples"),
};
const outDir = join(lunaRoot, "dist-demo");

// css_split_test depends on Vite's `virtual:luna.css` plugin and is excluded
// from the static bundle. wc_counter / wiki are not part of the landing page.
const examples = [
  {
    id: "hello_luna",
    mooncake: "luna",
    title: "Hello Luna",
    desc: "Basic Luna Web Components examples",
  },
  {
    id: "todomvc",
    mooncake: "luna",
    title: "TodoMVC",
    desc: "Classic TodoMVC implementation with Luna",
  },
  {
    id: "spa",
    mooncake: "luna",
    title: "SPA Example",
    desc: "Single Page Application with signals and reactive components",
  },
  {
    id: "browser_router",
    mooncake: "luna",
    title: "Browser Router",
    desc: "Client-side routing with dynamic parameters and nested routes",
  },
  {
    id: "game",
    mooncake: "luna",
    title: "Game Demo",
    desc: "Interactive game built with Luna's reactive primitives",
  },
  {
    id: "wc",
    mooncake: "luna",
    title: "Web Components",
    desc: "Luna components as custom elements with shadow DOM",
  },
  {
    id: "apg-playground",
    mooncake: "luna_components",
    title: "APG Playground",
    desc: "WAI-ARIA APG compliant UI components playground",
  },
];

function rewriteExampleHtml(html) {
  // Replace the inline <script>...loadModule(primaryModule)...</script>
  // block with a single <script type="module" src="./index.js"></script>.
  const pattern =
    /<script>\s*const loadModule[\s\S]*?loadModule\(primaryModule\)[\s\S]*?<\/script>/;
  if (!pattern.test(html)) {
    throw new Error(
      "loadModule(primaryModule) script block not found; example HTML format may have changed",
    );
  }
  return html.replace(
    pattern,
    `<script type="module" src="./index.js"></script>`,
  );
}

function rewriteLanding(html) {
  // ./src/examples/<id>/  →  ./<id>/
  let out = html.replace(
    /href="\.\/src\/examples\/([^"\/]+)\//g,
    'href="./$1/',
  );
  // Drop entries we don't ship (css_split_test).
  out = out.replace(
    /\s*<li class="demo-item">\s*<a href="\.\/css_split_test\/"[\s\S]*?<\/li>/,
    "",
  );
  return out;
}

async function main() {
  await rm(outDir, { recursive: true, force: true });
  await mkdir(outDir, { recursive: true });

  for (const ex of examples) {
    const buildSrc = buildSrcByMooncake[ex.mooncake];
    const examplesSrc = examplesSrcByMooncake[ex.mooncake];
    if (!buildSrc || !examplesSrc) {
      throw new Error(`Unknown mooncake "${ex.mooncake}" for example "${ex.id}"`);
    }
    const jsSrc = join(buildSrc, ex.id, `${ex.id}.js`);
    const htmlSrc = join(examplesSrc, ex.id, "index.html");
    if (!existsSync(jsSrc)) {
      throw new Error(
        `Missing build artifact: ${jsSrc}\nRun \`moon build --target js --release\` first.`,
      );
    }
    if (!existsSync(htmlSrc)) {
      throw new Error(`Missing example HTML: ${htmlSrc}`);
    }

    const dest = join(outDir, ex.id);
    await mkdir(dest, { recursive: true });
    let js = await readFile(jsSrc, "utf8");
    if (ex.id === "browser_router") {
      // The example hard-codes `let base = "/demo/browser_router"` for vite
      // dev where vite.config.ts mounts at base "/demo/". On the
      // luna-examples worker the route prefix is "/browser_router". Patching
      // the compiled JS keeps the source compatible with vite dev.
      js = js.replace(/"\/demo\/browser_router"/g, '"/browser_router"');
    }
    await writeFile(join(dest, "index.js"), js);

    const html = await readFile(htmlSrc, "utf8");
    await writeFile(join(dest, "index.html"), rewriteExampleHtml(html));
  }

  const landing = await readFile(join(lunaRoot, "index.html"), "utf8");
  await writeFile(join(outDir, "index.html"), rewriteLanding(landing));

  console.log(
    `built ${examples.length} examples + landing → ${outDir.replace(repoRoot + "/", "")}`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
