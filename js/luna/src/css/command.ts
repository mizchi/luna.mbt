import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { pathToFileURL } from "node:url";
import type { ViteDevServer } from "vite";
import { compileStyleDirectory } from "./compile.js";
import { extract } from "./extract.js";

const help = `Luna CSS CLI (Node.js 24+)

Commands:
  compile <input> --output-dir <output> [--css-package <path>]
  extract <input> [-o <file>] [--json] [--pretty] [--strict] [--no-warn]
  watch [--root <project>] [--config <file>] [--host <host>] [--port <port>]

compile stages static CSS and MoonBit sources without an npm dependency.
watch starts the project's installed Vite using its vite.config file.
Configure lunaCssCompile in that file to watch and compile MoonBit CSS.
`;

function parse(args: string[], values: string[], flags: string[]) {
  const options: Record<string, string | boolean> = {};
  const positional: string[] = [];
  for (let i = 0; i < args.length; i++) {
    const name = args[i] === "-o" ? "--output" : args[i];
    if (values.includes(name)) {
      if (i + 1 >= args.length || args[i + 1].startsWith("--")) throw new Error(`Missing value for ${name}`);
      options[name] = args[++i];
    } else if (flags.includes(name)) options[name] = true;
    else if (name === "--") { positional.push(...args.slice(i + 1)); break; }
    else if (name.startsWith("-")) throw new Error(`Unknown option: ${name}`);
    else positional.push(name);
  }
  return { options, positional };
}

/** Shared by the npm CLI and the self-contained Mooncake command. */
export async function runCssCommand(args: string[]): Promise<void> {
  if (args.length === 0 || args.includes("--help") || args.includes("-h") || args[0] === "help") {
    console.log(help);
    return;
  }
  const [command, ...rest] = args;
  if (command === "compile") {
    const { options, positional } = parse(rest, ["--output-dir", "--css-package"], []);
    if (positional.length !== 1 || !options["--output-dir"]) throw new Error("Usage: compile <input> --output-dir <output>");
    const result = compileStyleDirectory(positional[0], { outputDir: options["--output-dir"] as string, cssPackage: options["--css-package"] as string | undefined });
    console.log(`CSS compiled: ${result.files} files, ${result.stats.folded} constants, ${result.stats.precompiled} precompiled expressions, ${result.written} files written (${result.elapsedMs.toFixed(1)}ms)`);
    console.log(result.outputDir);
    return;
  }
  if (command === "extract") {
    const { options, positional } = parse(rest, ["--output"], ["--json", "--pretty", "--strict", "--no-warn"]);
    if (positional.length !== 1) throw new Error("Usage: extract <input> [-o <file>] [--json] [--strict]");
    const result = extract(positional[0], { pretty: !!options["--pretty"], strict: !!options["--strict"], warn: !options["--no-warn"] });
    const text = options["--json"] ? JSON.stringify(result, null, 2) : result.css;
    if (options["--output"]) fs.writeFileSync(options["--output"] as string, text + "\n");
    else console.log(text);
    return;
  }
  if (command === "watch") {
    const { options, positional } = parse(rest, ["--root", "--config", "--host", "--port"], []);
    if (positional.length) throw new Error("Usage: watch [--root <project>] [--port <port>]");
    const root = fs.realpathSync(path.resolve(options["--root"] as string ?? "."));
    const port = options["--port"] === undefined ? undefined : Number(options["--port"]);
    if (port !== undefined && (!Number.isInteger(port) || port < 0 || port > 65535)) throw new Error("Port must be an integer between 0 and 65535");
    let vitePath: string;
    try {
      vitePath = createRequire(path.join(root, "package.json")).resolve("vite");
    } catch {
      throw new Error(`Vite is not installed for ${root}. Install Vite in that project and configure lunaCssCompile in vite.config.`);
    }
    // Resolve from the caller, never from the Mooncake or the generated JS directory.
    const vite = await import(pathToFileURL(vitePath).href);
    const server: ViteDevServer = await vite.createServer({
      root,
      ...(options["--config"] ? { configFile: path.resolve(root, options["--config"] as string) } : {}),
      server: {
        ...(port !== undefined ? { port } : {}),
        ...(options["--host"] ? { host: options["--host"] as string } : {}),
      },
    });
    try { await server.listen(); } catch (error) { await server.close(); throw error; }
    server.printUrls();
    let closing = false;
    const stop = (status: number) => {
      if (closing) return;
      closing = true;
      void server.close().then(() => { process.exitCode = status; }).catch(error => {
        console.error(error);
        process.exitCode = 1;
      }).finally(() => {
        process.off("SIGINT", interrupt);
        process.off("SIGTERM", terminate);
      });
    };
    const interrupt = () => stop(130);
    const terminate = () => stop(143);
    process.on("SIGINT", interrupt);
    process.on("SIGTERM", terminate);
    return;
  }
  throw new Error(`Unknown CSS command: ${command}`);
}
