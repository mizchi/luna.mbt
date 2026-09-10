import { normalizePath, type Plugin, type ResolvedConfig, type ViteDevServer } from "vite";
import fs from "node:fs";
import path from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { compileStyleDirectory, styleCompileIgnoredDirectories, type StyleDirectoryResult } from "./compile.js";

export interface LunaCssBuildContext {
  inputDir: string;
  outputDir: string;
  command: "serve" | "build";
  signal: AbortSignal;
  result: StyleDirectoryResult;
}
export interface LunaCssCompileOptions {
  /** A complete MoonBit module/workspace, relative to Vite root. */
  input: string;
  /** Compiler-owned directory outside input, relative to Vite root. */
  outputDir: string;
  cssPackage?: string;
  /** Delay after the latest filesystem event. Defaults to 30ms. */
  debounceMs?: number;
  /**
   * Default: moon build --target js, with --release for vite build.
   * Override to integrate a server/client build pipeline. Honor signal on shutdown.
   * Set false only if another integration compiles the generated MoonBit sources.
   */
  build?: false | ((context: LunaCssBuildContext) => void | Promise<void>);
}

const runFile = promisify(execFile);
const virtualCss = "virtual:luna-compiled.css";
const resolvedCss = "\0" + virtualCss;
const virtualJsPrefix = "virtual:luna-compiled/";
const ignored = new Set<string>(styleCompileIgnoredDirectories);
const within = (dir: string, file: string) => {
  const relative = path.relative(dir, file);
  return !path.isAbsolute(relative) && relative !== ".." && !relative.startsWith(".." + path.sep);
};

/** Static CSS preprocessing + MoonBit compilation, shared by Vite dev and build. */
export function lunaCssCompile(options: LunaCssCompileOptions): Plugin {
  const debounceMs = options.debounceMs ?? 30;
  if (!Number.isFinite(debounceMs) || debounceMs < 0) throw new Error("debounceMs must be non-negative");
  let config: ResolvedConfig;
  let server: ViteDevServer | undefined;
  let inputDir: string;
  let inputPath: string;
  let outputDir: string;
  let css = ""; // Only publish CSS after the associated JS build succeeds.
  let initialized = false;
  let dirty = false;
  let needsBuild = true;
  let unpublished = false;
  let closed = false;
  let running: Promise<void> | undefined;
  let controller: AbortController | undefined;
  let timer: ReturnType<typeof setTimeout> | undefined;
  let lastError: Error | undefined;
  let watchFiles: string[] = [];

  const isInput = (file: string) => {
    const absolute = path.resolve(file);
    // Watchers may report either spelling of a symlinked project root, including
    // unlink events where realpath(file) is no longer available.
    const base = within(inputDir, absolute) ? inputDir : inputPath;
    return within(base, absolute) && !path.relative(base, absolute).split(path.sep).some(part => ignored.has(part));
  };
  const publish = () => {
    css = fs.readFileSync(path.join(outputDir, "luna.css"), "utf8");
    if (!server || closed) return;
    // Both client and SSR module graphs must observe the same completed build.
    for (const environment of Object.values(server.environments)) environment.moduleGraph.invalidateAll();
    server.ws.send({ type: "full-reload" });
  };
  const report = (cause: unknown) => {
    if (closed) return;
    const error = cause instanceof Error ? cause : new Error(String(cause));
    config.logger.error(`[luna-css-compile] ${error.message}`, { error });
    server?.ws.send({ type: "error", err: { message: error.message, stack: error.stack ?? "", plugin: "luna-css-compile" } });
  };
  const drain = (): Promise<void> => {
    if (running) return running;
    running = (async () => {
      while (dirty && !closed) {
        dirty = false;
        try {
          const result = compileStyleDirectory(inputDir, { outputDir, cssPackage: options.cssPackage });
          outputDir = result.outputDir;
          if (result.written > 0 || needsBuild || !initialized) {
            needsBuild = true;
            controller = new AbortController();
            const context: LunaCssBuildContext = { inputDir, outputDir, command: config.command, signal: controller.signal, result };
            if (options.build === undefined) {
              const args = ["build", "--target", "js", ...(config.command === "build" ? ["--release"] : [])];
              await runFile("moon", args, { cwd: outputDir, signal: controller.signal, maxBuffer: 16 * 1024 * 1024 });
            } else if (options.build !== false) {
              await options.build(context);
            }
            controller = undefined;
            needsBuild = false;
            initialized = true;
            unpublished = true;
          }
          if (dirty || closed) continue;
          lastError = undefined;
          if (unpublished) {
            publish();
            unpublished = false;
          }
        } catch (error) {
          controller = undefined;
          needsBuild = true;
          lastError = error instanceof Error ? error : new Error(String(error));
          if (closed) return;
          if (dirty) continue; // Retry a newer edit before reporting an obsolete failure.
          throw error;
        }
      }
    })().finally(() => { running = undefined; });
    return running;
  };
  const onEvent = (event: string, file: string) => {
    if (closed || !["add", "change", "unlink", "addDir", "unlinkDir"].includes(event) || !isInput(file)) return;
    dirty = true; // Set immediately: an in-flight build must not publish stale output.
    if (timer) clearTimeout(timer);
    timer = setTimeout(() => {
      timer = undefined;
      // The running loop already owns newer edits and its error handler.
      if (!running) void drain().catch(report);
    }, debounceMs);
  };
  const close = async () => {
    if (closed) return;
    closed = true;
    if (timer) clearTimeout(timer);
    server?.watcher.off("all", onEvent);
    controller?.abort();
    await running?.catch(() => {});
  };

  return {
    name: "luna-css-compile",
    enforce: "pre",
    async configResolved(resolved) {
      config = resolved;
      inputPath = path.resolve(config.root, options.input);
      inputDir = fs.realpathSync(inputPath);
      outputDir = path.resolve(config.root, options.outputDir);
      // Generate import targets before dependency scanning starts.
      dirty = true;
      try {
        await drain();
      } catch (error) {
        if (config.command === "build") throw error;
        report(error); // Keep the dev server alive so the first edit can repair it.
      }
    },
    configureServer(devServer) {
      server = devServer;
      server.watcher.add(inputDir); // Watch the directory itself, including new files.
      server.watcher.on("all", onEvent);
    },
    async buildStart() {
      // Rolldown build --watch also needs source dependencies outside its JS graph.
      if (config.command === "build") {
        watchFiles = [];
        const watch = (dir: string) => {
          this.addWatchFile(dir);
          watchFiles.push(dir);
          for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
            if (ignored.has(entry.name) || entry.isSymbolicLink()) continue;
            const file = path.join(dir, entry.name);
            if (entry.isDirectory()) watch(file);
            else { this.addWatchFile(file); watchFiles.push(file); }
          }
        };
        watch(inputDir);
        if (dirty) await drain();
      }
    },
    watchChange(file) {
      if (config.command === "build" && isInput(file)) dirty = true;
    },
    resolveId(id) {
      if (id === virtualCss) return resolvedCss;
      if (id.startsWith(virtualJsPrefix)) {
        const relative = id.slice(virtualJsPrefix.length);
        if (!relative.endsWith(".js") || relative.split(/[\\/]/).some(part => !part || part === ".." || part === ".") || path.isAbsolute(relative)) throw new Error("Expected a JS path relative to MoonBit's build directory");
        return normalizePath(path.join(outputDir, "_build/js", config.command === "build" ? "release" : "debug", "build", relative));
      }
    },
    load(id) {
      if (id === resolvedCss) {
        if (!initialized && lastError) throw lastError;
        for (const file of watchFiles) this.addWatchFile(file);
        return css;
      }
    },
    transform(_code, id) {
      if (config.command === "build" && within(outputDir, id.split("?")[0])) {
        for (const file of watchFiles) this.addWatchFile(file);
      }
    },
    hotUpdate({ file }) {
      // Generated files may change before the compiler finishes writing all outputs.
      // The queue performs one coordinated reload after success instead of early HMR.
      if (within(outputDir, path.resolve(file)) || isInput(file)) return [];
    },
    async closeBundle() {
      if (config.command === "serve") await close();
    },
    closeWatcher: close,
  };
}
