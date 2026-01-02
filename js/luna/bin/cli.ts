#!/usr/bin/env node
import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
import {
  extract,
  extractSplit,
  minify,
  formatSize,
  inlineCSS,
  inlineFromSource,
  removeRegistryCode,
  injectAndWrite,
} from "../src/css/index.js";
import { analyzeDirectory } from "../src/css-optimizer/moonbit-analyzer.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

interface Template {
  path: string;
  content: string;
}

// =============================================================================
// Help Messages
// =============================================================================

function printMainHelp() {
  console.log(`
@luna_ui/luna CLI

Usage:
  luna <command> [options]

Commands:
  new <name>      Create a new Luna project
  css             CSS utilities (extract, minify, inline)

Options:
  --help, -h      Show this help message

Examples:
  luna new myapp              # Create TSX project
  luna new myapp --mbt        # Create MoonBit project
  luna css extract src        # Extract CSS from source
  luna css minify style.css   # Minify CSS file
`);
}

function printNewHelp() {
  console.log(`
luna new - Create a new Luna project

Usage:
  luna new <project-name> [options]

Options:
  --mbt       Generate MoonBit template (default: TSX)
  --help, -h  Show this help message

Examples:
  luna new myapp         # TSX template
  luna new myapp --mbt   # MoonBit template
`);
}

function printCssHelp() {
  console.log(`
luna css - CSS utilities

Usage:
  luna css <subcommand> [options]

Subcommands:
  extract <dir>     Extract CSS from .mbt files
  minify <file>     Minify CSS file
  inline <file>     Inline CSS class names into compiled JS
  inject <html>     Inject extracted CSS into HTML file
  analyze-mbt <dir> Analyze MoonBit source for CSS co-occurrences

Extract Options:
  -o, --output <file>   Output file (default: stdout)
  --pretty              Pretty print output
  --json                Output as JSON with mapping
  -v, --verbose         Show extraction details
  --no-warn             Disable non-literal argument warnings
  --strict              Exit with error if warnings found
  --split               Split CSS by file (outputs to --output-dir)
  --split-dir           Split CSS by directory (outputs to --output-dir)
  --output-dir <dir>    Output directory for split mode
  --shared-threshold <n>  Min usages to be "shared" (default: 3)

Minify Options:
  -o, --output <file>   Output file (default: stdout)
  -v, --verbose         Show minification stats

Inline Options:
  -m, --mapping <file>  JSON file with css -> classname mapping
  --extract-from <dir>  Extract mapping from source directory
  -o, --output <file>   Output file (default: stdout)
  --remove-registry     Remove CSS registry code after inlining
  -v, --verbose         Show replacement details
  --dry-run             Show what would be replaced

Inject Options:
  --src <dir>           Source directory for CSS extraction (required)
  -o, --output <file>   Output file (default: modify in-place)
  -m, --mode <mode>     Output mode: inline, external, or auto (default: inline)
  -t, --threshold <n>   Size threshold for auto mode in bytes (default: 4096)
  --css-file <name>     CSS filename for external mode (default: luna.css)
  -v, --verbose         Show injection details

Analyze-mbt Options:
  -o, --output <file>   Output file (default: stdout)
  --no-recursive        Don't search recursively
  -v, --verbose         Show analysis details

Examples:
  luna css extract src -o dist/styles.css
  luna css extract src --json -o mapping.json
  luna css extract src --split --output-dir dist/css
  luna css extract src --split-dir --output-dir dist/css --shared-threshold 2
  luna css minify input.css -o output.min.css
  luna css inline bundle.js --extract-from src -o bundle.inlined.js
  luna css inject index.html --src src
  luna css inject index.html --src src --mode external --css-file styles.css
  luna css inject index.html --src src --mode auto --threshold 2048
  luna css analyze-mbt src/luna -o cooccurrences.json
`);
}

// =============================================================================
// Project Templates
// =============================================================================

function getTsxTemplates(projectName: string): Template[] {
  return [
    {
      path: "package.json",
      content: JSON.stringify(
        {
          name: projectName,
          private: true,
          type: "module",
          scripts: {
            dev: "vite",
            build: "vite build",
            preview: "vite preview",
          },
          dependencies: {
            "@luna_ui/luna": "latest",
          },
          devDependencies: {
            vite: "^6.0.0",
            typescript: "^5.7.0",
          },
        },
        null,
        2
      ),
    },
    {
      path: "tsconfig.json",
      content: JSON.stringify(
        {
          compilerOptions: {
            target: "ES2023",
            module: "ESNext",
            moduleResolution: "bundler",
            noEmit: true,
            allowJs: true,
            strict: true,
            esModuleInterop: true,
            skipLibCheck: true,
            jsx: "preserve",
            jsxImportSource: "@luna_ui/luna",
          },
          include: ["src/**/*"],
        },
        null,
        2
      ),
    },
    {
      path: "vite.config.ts",
      content: `import { defineConfig } from "vite";

export default defineConfig({
  esbuild: {
    jsx: "automatic",
    jsxImportSource: "@luna_ui/luna",
  },
});
`,
    },
    {
      path: "index.html",
      content: `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${projectName}</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
`,
    },
    {
      path: "src/main.tsx",
      content: `import { render } from "@luna_ui/luna";
import { App } from "./App";

render(() => <App />, document.getElementById("app")!);
`,
    },
    {
      path: "src/App.tsx",
      content: `import { createSignal, For, Show } from "@luna_ui/luna";

export function App() {
  const [count, setCount] = createSignal(0);
  const [items, setItems] = createSignal<string[]>([]);

  const increment = () => setCount((c) => c + 1);
  const decrement = () => setCount((c) => c - 1);
  const reset = () => setCount(0);
  const addItem = () => setItems((prev) => [...prev, \`Item \${prev.length + 1}\`]);

  return (
    <div>
      <h1>Luna Counter</h1>
      <p>Count: {count}</p>
      <p>Doubled: {() => count() * 2}</p>
      <div>
        <button onClick={increment}>+1</button>
        <button onClick={decrement}>-1</button>
        <button onClick={reset}>Reset</button>
      </div>

      <h2>Items</h2>
      <button onClick={addItem}>Add Item</button>
      <Show when={() => items().length > 0} fallback={<p>No items yet</p>}>
        <ul>
          <For each={items}>
            {(item, index) => (
              <li>
                {index}: {item}
              </li>
            )}
          </For>
        </ul>
      </Show>
    </div>
  );
}
`,
    },
    {
      path: ".gitignore",
      content: `node_modules
dist
.vite
`,
    },
  ];
}

function getMbtTemplates(projectName: string): Template[] {
  return [
    {
      path: "package.json",
      content: JSON.stringify(
        {
          name: projectName,
          private: true,
          type: "module",
          scripts: {
            dev: "vite",
            build: "moon build && vite build",
          },
          devDependencies: {
            vite: "^6.0.0",
            "vite-plugin-moonbit": "^0.1.0",
          },
        },
        null,
        2
      ),
    },
    {
      path: "moon.mod.json",
      content: JSON.stringify(
        {
          name: `internal/${projectName}`,
          version: "0.0.1",
          deps: {
            "mizchi/luna": "0.1.3",
            "mizchi/js": "0.10.6",
          },
          source: "src",
          "preferred-target": "js",
        },
        null,
        2
      ),
    },
    {
      path: "tsconfig.json",
      content: JSON.stringify(
        {
          compilerOptions: {
            target: "ES2023",
            module: "ESNext",
            moduleResolution: "bundler",
            noEmit: true,
            allowJs: true,
            strict: true,
            esModuleInterop: true,
            skipLibCheck: true,
            paths: {
              [`mbt:internal/${projectName}`]: [
                "./target/js/release/build/app/app.js",
              ],
            },
          },
          include: ["*.ts"],
        },
        null,
        2
      ),
    },
    {
      path: "vite.config.ts",
      content: `import { defineConfig } from "vite";
import { moonbit } from "vite-plugin-moonbit";

export default defineConfig({
  plugins: [
    moonbit({
      watch: true,
      showLogs: true,
    }),
  ],
});
`,
    },
    {
      path: "index.html",
      content: `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${projectName}</title>
  </head>
  <body>
    <h1>${projectName}</h1>
    <div id="app"></div>
    <script type="module" src="/main.ts"></script>
  </body>
</html>
`,
    },
    {
      path: "main.ts",
      content: `// Import MoonBit module via mbt: prefix
import "mbt:internal/${projectName}";
`,
    },
    {
      path: "src/moon.pkg.json",
      content: JSON.stringify(
        {
          "is-main": true,
          "supported-targets": ["js"],
          import: [
            "mizchi/luna/luna/signal",
            {
              path: "mizchi/luna/platform/dom/element",
              alias: "dom",
            },
            {
              path: "mizchi/js/browser/dom",
              alias: "js_dom",
            },
          ],
          link: {
            js: {
              format: "esm",
            },
          },
        },
        null,
        2
      ),
    },
    {
      path: "src/lib.mbt",
      content: `// Luna Counter App

fn main {
  let count = @signal.signal(0)
  let doubled = @signal.memo(fn() { count.get() * 2 })

  let doc = @js_dom.document()
  match doc.getElementById("app") {
    Some(el) => {
      let app = @dom.div([
        @dom.h1([@dom.text("Luna Counter (MoonBit)")]),
        @dom.p([
          @dom.text_dyn(fn() { "Count: " + count.get().to_string() }),
        ]),
        @dom.p([
          @dom.text_dyn(fn() { "Doubled: " + doubled().to_string() }),
        ]),
        @dom.div(class="buttons", [
          @dom.button(
            on=@dom.events().click(_ => count.update(fn(n) { n + 1 })),
            [@dom.text("+1")],
          ),
          @dom.button(
            on=@dom.events().click(_ => count.update(fn(n) { n - 1 })),
            [@dom.text("-1")],
          ),
          @dom.button(
            on=@dom.events().click(_ => count.set(0)),
            [@dom.text("Reset")],
          ),
        ]),
      ])
      @dom.render(el |> @dom.DomElement::from_jsdom, app)
    }
    None => ()
  }
}
`,
    },
    {
      path: ".gitignore",
      content: `node_modules
dist
target
.mooncakes
`,
    },
  ];
}

function createProject(
  projectName: string,
  templates: Template[],
  targetDir: string
) {
  if (fs.existsSync(targetDir)) {
    console.error(`Error: Directory "${projectName}" already exists.`);
    process.exit(1);
  }

  fs.mkdirSync(targetDir, { recursive: true });

  for (const template of templates) {
    const filePath = path.join(targetDir, template.path);
    const dir = path.dirname(filePath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(filePath, template.content);
    console.log(`  Created: ${template.path}`);
  }
}

// =============================================================================
// Command Handlers
// =============================================================================

function handleNew(args: string[]) {
  if (args.includes("--help") || args.includes("-h")) {
    printNewHelp();
    process.exit(0);
  }

  const projectName = args.find((a) => !a.startsWith("-"));
  if (!projectName) {
    console.error("Error: Project name is required.");
    printNewHelp();
    process.exit(1);
  }

  if (!/^[a-zA-Z0-9_-]+$/.test(projectName)) {
    console.error(
      "Error: Project name can only contain letters, numbers, hyphens, and underscores."
    );
    process.exit(1);
  }

  const useMbt = args.includes("--mbt");
  const targetDir = path.resolve(process.cwd(), projectName);

  console.log(
    `\nCreating ${useMbt ? "MoonBit" : "TSX"} project: ${projectName}\n`
  );

  const templates = useMbt
    ? getMbtTemplates(projectName)
    : getTsxTemplates(projectName);

  createProject(projectName, templates, targetDir);

  console.log(`\nDone! To get started:\n`);
  console.log(`  cd ${projectName}`);

  if (useMbt) {
    console.log(`  moon update`);
    console.log(`  npm install`);
    console.log(`  moon build`);
    console.log(`  npm run dev`);
  } else {
    console.log(`  npm install`);
    console.log(`  npm run dev`);
  }

  console.log();
}

function handleCssExtract(args: string[]) {
  let dir = ".";
  let outputFile: string | null = null;
  let outputDir: string | null = null;
  let pretty = false;
  let jsonOutput = false;
  let verbose = false;
  let warn = true;
  let strict = false;
  let splitMode: "file" | "dir" | null = null;
  let sharedThreshold = 3;

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === "--output" || arg === "-o") {
      outputFile = args[++i];
    } else if (arg === "--output-dir") {
      outputDir = args[++i];
    } else if (arg === "--pretty") {
      pretty = true;
    } else if (arg === "--json") {
      jsonOutput = true;
    } else if (arg === "--verbose" || arg === "-v") {
      verbose = true;
    } else if (arg === "--no-warn") {
      warn = false;
    } else if (arg === "--strict") {
      strict = true;
      warn = true;
    } else if (arg === "--split") {
      splitMode = "file";
    } else if (arg === "--split-dir") {
      splitMode = "dir";
    } else if (arg === "--shared-threshold") {
      sharedThreshold = parseInt(args[++i], 10);
      if (isNaN(sharedThreshold) || sharedThreshold < 1) {
        console.error("Error: --shared-threshold must be a positive number");
        process.exit(1);
      }
    } else if (!arg.startsWith("-")) {
      dir = arg;
    }
  }

  try {
    // Split mode
    if (splitMode) {
      if (!outputDir) {
        console.error("Error: --output-dir is required for split mode");
        process.exit(1);
      }

      const result = extractSplit(dir, splitMode, {
        pretty,
        warn,
        strict,
        verbose,
        sharedThreshold,
      });

      // Ensure output directory exists
      fs.mkdirSync(outputDir, { recursive: true });

      // Write shared CSS
      const sharedPath = path.join(outputDir, "_shared.css");
      fs.writeFileSync(sharedPath, result.shared.css);
      if (verbose) {
        console.error(`Written shared CSS to ${sharedPath}`);
      }

      // Write per-chunk CSS
      for (const [chunkKey, chunk] of result.chunks) {
        if (!chunk.css) continue; // Skip empty chunks

        let chunkPath: string;
        if (splitMode === "file") {
          // Replace .mbt with .css
          chunkPath = path.join(outputDir, chunkKey.replace(/\.mbt$/, ".css"));
        } else {
          // Use directory name
          const dirName = chunkKey === "." ? "root" : chunkKey.replace(/\//g, "_");
          chunkPath = path.join(outputDir, `${dirName}.css`);
        }

        // Ensure parent directory exists
        fs.mkdirSync(path.dirname(chunkPath), { recursive: true });
        fs.writeFileSync(chunkPath, chunk.css);
        if (verbose) {
          console.error(`Written chunk CSS to ${chunkPath}`);
        }
      }

      // Write mapping JSON if requested
      if (jsonOutput) {
        const mappingPath = path.join(outputDir, "mapping.json");
        const mappingData = {
          mapping: result.mapping,
          chunks: Object.fromEntries(
            Array.from(result.chunks.entries()).map(([k, v]) => [
              k,
              { size: v.css.length },
            ])
          ),
          shared: { size: result.shared.css.length },
          warnings: result.warnings,
        };
        fs.writeFileSync(mappingPath, JSON.stringify(mappingData, null, pretty ? 2 : 0));
        if (verbose) {
          console.error(`Written mapping to ${mappingPath}`);
        }
      }

      // Print summary
      if (verbose) {
        console.error("\nSplit extraction summary:");
        console.error(`  Shared: ${result.shared.css.length} bytes`);
        for (const [chunkKey, chunk] of result.chunks) {
          console.error(`  ${chunkKey}: ${chunk.css.length} bytes`);
        }
        console.error(`  Combined: ${result.combined.length} bytes`);
      }

      // Print warnings
      if (warn && result.warnings && result.warnings.length > 0) {
        printWarnings(result.warnings, strict);
      }

      return;
    }

    // Normal (non-split) mode
    const result = extract(dir, { pretty, warn, strict, verbose });

    let output: string;
    if (jsonOutput) {
      output = JSON.stringify(
        {
          css: result.css,
          mapping: result.mapping,
          stats: result.stats,
          warnings: result.warnings,
        },
        null,
        pretty ? 2 : 0
      );
    } else {
      output = result.css;
    }

    if (outputFile) {
      fs.writeFileSync(outputFile, output);
      if (verbose) {
        console.error(`Written to ${outputFile}`);
      }
    } else {
      console.log(output);
    }

    // Print warnings
    if (warn && result.warnings && result.warnings.length > 0) {
      printWarnings(result.warnings, strict);
    }
  } catch (err) {
    console.error(`Error: ${(err as Error).message}`);
    process.exit(1);
  }
}

function printWarnings(
  warnings: { file: string; line: number; func: string; code: string; reason: string }[],
  strict: boolean
) {
  console.error(
    `\n⚠️  ${warnings.length} warning(s): non-literal CSS arguments detected\n`
  );
  for (const w of warnings) {
    console.error(`  ${w.file}:${w.line}`);
    console.error(`    ${w.func}(...) - ${w.reason}`);
    console.error(`    Code: ${w.code}`);
    console.error("");
  }

  if (strict) {
    console.error("❌ Strict mode: exiting with error due to warnings.");
    process.exit(1);
  }
}

function handleCssMinify(args: string[]) {
  let inputFile: string | null = null;
  let outputFile: string | null = null;
  let verbose = false;

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === "--output" || arg === "-o") {
      outputFile = args[++i];
    } else if (arg === "--verbose" || arg === "-v") {
      verbose = true;
    } else if (!arg.startsWith("-")) {
      inputFile = arg;
    }
  }

  if (!inputFile) {
    console.error("Error: No input file specified");
    printCssHelp();
    process.exit(1);
  }

  try {
    const css = fs.readFileSync(inputFile, "utf-8");
    const result = minify(css, { verbose });

    if (outputFile) {
      fs.writeFileSync(outputFile, result.minified);
      console.error(
        `Minified: ${formatSize(result.originalSize)} → ${formatSize(result.minifiedSize)} (${result.reduction.toFixed(1)}% reduction)`
      );
      console.error(`Written to: ${outputFile}`);
    } else {
      console.log(result.minified);
    }
  } catch (err) {
    console.error(`Error: ${(err as Error).message}`);
    process.exit(1);
  }
}

function handleCssInline(args: string[]) {
  let inputFile: string | null = null;
  let outputFile: string | null = null;
  let mappingFile: string | null = null;
  let extractFrom: string | null = null;
  let verbose = false;
  let dryRun = false;
  let removeRegistry = false;

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === "--mapping" || arg === "-m") {
      mappingFile = args[++i];
    } else if (arg === "--extract-from") {
      extractFrom = args[++i];
    } else if (arg === "--output" || arg === "-o") {
      outputFile = args[++i];
    } else if (arg === "--verbose" || arg === "-v") {
      verbose = true;
    } else if (arg === "--dry-run") {
      dryRun = true;
      verbose = true;
    } else if (arg === "--remove-registry") {
      removeRegistry = true;
    } else if (!arg.startsWith("-")) {
      inputFile = arg;
    }
  }

  if (!inputFile) {
    console.error("Error: No input file specified");
    printCssHelp();
    process.exit(1);
  }

  if (!mappingFile && !extractFrom) {
    console.error("Error: Must specify --mapping or --extract-from");
    printCssHelp();
    process.exit(1);
  }

  try {
    const code = fs.readFileSync(inputFile, "utf-8");
    let result;

    if (extractFrom) {
      result = inlineFromSource(code, extractFrom, {
        verbose,
        dryRun,
        removeRegistry,
      });
    } else {
      const mappingContent = fs.readFileSync(mappingFile!, "utf-8");
      const mappingData = JSON.parse(mappingContent);
      const mapping = mappingData.mapping || mappingData;
      result = inlineCSS(code, mapping, { verbose, dryRun });

      if (removeRegistry) {
        result = {
          ...result,
          code: removeRegistryCode(result.code),
          finalSize: Buffer.byteLength(removeRegistryCode(result.code), "utf-8"),
        };
      }
    }

    if (verbose) {
      console.error(`Loaded mapping, found ${result.replacements.length} replacements`);
      for (const r of result.replacements) {
        console.error(`  [${r.type}] ${r.key || r.decl} → ${r.to}`);
      }
      console.error(
        `\nSize: ${result.originalSize} → ${result.finalSize} (${((1 - result.finalSize / result.originalSize) * 100).toFixed(1)}% reduction)`
      );
    }

    if (dryRun) {
      console.error("\n[Dry run - no files modified]");
    } else if (outputFile) {
      fs.writeFileSync(outputFile, result.code);
      if (verbose) {
        console.error(`Written to ${outputFile}`);
      }
    } else {
      console.log(result.code);
    }
  } catch (err) {
    console.error(`Error: ${(err as Error).message}`);
    process.exit(1);
  }
}

function handleCssInject(args: string[]) {
  let htmlFile: string | null = null;
  let srcDir: string | null = null;
  let outputFile: string | null = null;
  let mode: "inline" | "external" | "auto" = "inline";
  let threshold = 4096;
  let cssFileName = "luna.css";
  let verbose = false;

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === "--src") {
      srcDir = args[++i];
    } else if (arg === "--output" || arg === "-o") {
      outputFile = args[++i];
    } else if (arg === "--mode" || arg === "-m") {
      const m = args[++i];
      if (m === "inline" || m === "external" || m === "auto") {
        mode = m;
      } else {
        console.error(`Error: Invalid mode "${m}". Use inline, external, or auto.`);
        process.exit(1);
      }
    } else if (arg === "--threshold" || arg === "-t") {
      threshold = parseInt(args[++i], 10);
      if (isNaN(threshold)) {
        console.error("Error: --threshold must be a number");
        process.exit(1);
      }
    } else if (arg === "--css-file") {
      cssFileName = args[++i];
    } else if (arg === "--verbose" || arg === "-v") {
      verbose = true;
    } else if (!arg.startsWith("-")) {
      htmlFile = arg;
    }
  }

  if (!htmlFile) {
    console.error("Error: No HTML file specified");
    printCssHelp();
    process.exit(1);
  }

  if (!srcDir) {
    console.error("Error: --src <dir> is required");
    printCssHelp();
    process.exit(1);
  }

  try {
    const result = injectAndWrite({
      srcDir,
      htmlFile,
      outputFile: outputFile || undefined,
      mode,
      threshold,
      cssFileName,
      verbose,
    });

    if (!result.replaced) {
      console.error(
        "Warning: CSS markers not found. Add /* LUNA_CSS_START */ and /* LUNA_CSS_END */ to your HTML."
      );
      process.exit(1);
    }

    if (verbose) {
      console.error(`Mode: ${result.mode}, injected ${result.css.length} bytes of CSS`);
      if (result.cssFile) {
        console.error(`External CSS file: ${result.cssFile}`);
      }
    }
  } catch (err) {
    console.error(`Error: ${(err as Error).message}`);
    process.exit(1);
  }
}

async function handleCssAnalyzeMbt(args: string[]) {
  let dir = ".";
  let outputFile: string | null = null;
  let recursive = true;
  let verbose = false;

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === "--output" || arg === "-o") {
      outputFile = args[++i];
    } else if (arg === "--no-recursive") {
      recursive = false;
    } else if (arg === "--verbose" || arg === "-v") {
      verbose = true;
    } else if (!arg.startsWith("-")) {
      dir = arg;
    }
  }

  try {
    if (verbose) {
      console.error(`Analyzing MoonBit files in: ${dir}`);
    }

    const result = await analyzeDirectory(dir, { recursive });

    const output = JSON.stringify(result, null, 2);

    if (outputFile) {
      fs.writeFileSync(outputFile, output);
      if (verbose) {
        console.error(`Written to ${outputFile}`);
      }
    } else {
      console.log(output);
    }

    if (verbose) {
      console.error(`\nFound ${result.cooccurrences.length} class co-occurrences`);
      if (result.warnings.length > 0) {
        console.error(`Warnings: ${result.warnings.length}`);
        for (const w of result.warnings) {
          console.error(`  ${w.file}:${w.line} - ${w.kind}: ${w.message}`);
        }
      }
    }
  } catch (err) {
    console.error(`Error: ${(err as Error).message}`);
    process.exit(1);
  }
}

async function handleCss(args: string[]) {
  if (args.length === 0 || args.includes("--help") || args.includes("-h")) {
    printCssHelp();
    process.exit(0);
  }

  const subcommand = args[0];
  const subArgs = args.slice(1);

  switch (subcommand) {
    case "extract":
      handleCssExtract(subArgs);
      break;
    case "minify":
      handleCssMinify(subArgs);
      break;
    case "inline":
      handleCssInline(subArgs);
      break;
    case "inject":
      handleCssInject(subArgs);
      break;
    case "analyze-mbt":
      await handleCssAnalyzeMbt(subArgs);
      break;
    default:
      console.error(`Unknown css subcommand: ${subcommand}`);
      printCssHelp();
      process.exit(1);
  }
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    printMainHelp();
    process.exit(0);
  }

  const command = args[0];

  // Show main help only if --help is the first arg
  if (command === "--help" || command === "-h") {
    printMainHelp();
    process.exit(0);
  }

  const commandArgs = args.slice(1);

  switch (command) {
    case "new":
      handleNew(commandArgs);
      break;
    case "css":
      await handleCss(commandArgs);
      break;
    default:
      console.error(`Unknown command: ${command}`);
      printMainHelp();
      process.exit(1);
  }
}

main().catch((err) => {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});
