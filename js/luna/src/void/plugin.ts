import { resolve } from "node:path";
import type { Plugin } from "vite";
import { generateComponentManifest, resolvePagesDir, scanPages } from "void/pages";
import { assertIslandId } from "./contracts";

export interface VoidLunaOptions {
  /** Module paths relative to Vite's root. Each module default-exports an Island. */
  islands: Record<string, string>;
  /** Defaults to Void's configured pages directory, including sourceDir. */
  pagesDir?: string;
}

const ids = [
  "virtual:void-pages-renderer",
  "virtual:void-islands-renderer",
  "virtual:void-pages-client",
  "virtual:void-islands-client",
];

/** Full-document Void Pages with explicitly registered, mixed-renderer islands. */
export function voidLuna(options: VoidLunaOptions): Plugin {
  for (const [id, path] of Object.entries(options.islands)) {
    assertIslandId(id);
    if (typeof path !== "string" || !path.trim()) throw new Error(`Invalid island module: ${id}`);
  }
  let root: string;
  let pagesDir: string;
  return {
    name: "luna:void",
    configResolved(config) {
      root = config.root;
      pagesDir = options.pagesDir ? resolve(root, options.pagesDir) : resolvePagesDir(root);
    },
    config(_, env) {
      return {
        resolve: { dedupe: ["@luna_ui/luna"] },
        optimizeDeps: { include: ["@luna_ui/luna", "@luna_ui/luna/jsx-runtime"] },
        ...(env.command === "build"
          ? {
              build: {
                manifest: true,
                rollupOptions: { input: { "pages-client": ids[2], "islands-client": ids[3] } },
              },
            }
          : {}),
      };
    },
    resolveId(id) {
      if (ids.includes(id)) return `\0${id}`;
    },
    async load(id) {
      if (!ids.some((value) => id === `\0${value}`)) return;
      if (id.endsWith("-client")) {
        const entries = Object.entries(options.islands).map(
          ([name, path]) =>
            `${JSON.stringify(name)}: () => import(${JSON.stringify(resolve(root, path))})`,
        );
        return `import { initLunaIslands } from "@luna_ui/luna/void/client";
          const dispose = initLunaIslands({${entries.join(",")}});
          if (import.meta.hot) import.meta.hot.dispose(dispose);`;
      }
      const scan = await scanPages(root, { pagesDir });
      for (const page of scan.pages) {
        if (page.ssrMode === "client")
          throw new Error("The Luna Void adapter requires server-rendered pages");
      }
      return `import { createPageRenderer } from "@luna_ui/luna/void/server";
        ${generateComponentManifest(scan, pagesDir)}
        export const renderPage = createPageRenderer(components, layoutTree);
        export const renderIslandPage = renderPage;`;
    },
    configureServer(server) {
      const reload = (file: string) => {
        if (!file.startsWith(`${pagesDir}/`)) return;
        for (const environment of Object.values(server.environments)) {
          for (const id of ids) {
            const module = environment.moduleGraph.getModuleById(`\0${id}`);
            if (module) environment.moduleGraph.invalidateModule(module);
          }
        }
        server.ws.send({ type: "full-reload" });
      };
      server.watcher.on("add", reload).on("unlink", reload);
      server.httpServer?.once("close", () => {
        server.watcher.off("add", reload).off("unlink", reload);
      });
    },
  };
}
