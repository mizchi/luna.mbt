// @vitest-environment node
import { join } from "node:path";
import { gzipSync } from "node:zlib";
import { build } from "esbuild";
import { createServer } from "vite";
import { describe, expect, it } from "vitest";
import { voidLuna } from "../../src/void/plugin";

const sourceDir = join(import.meta.dirname, "../../src");
const counter = `
  function Counter() {
    const [count, setCount] = createSignal(0);
    return jsx('button', {
      onClick: () => setCount(n => n + 1), children: () => 'Luna ' + count()
    });
  }
`;

function bundle(contents: string) {
  return build({
    stdin: { contents, resolveDir: sourceDir, sourcefile: "size-fixture.ts" },
    alias: {
      "@luna_ui/luna/void/client": join(sourceDir, "void/client.ts"),
      "@luna_ui/luna/void/scheduler": join(sourceDir, "void/scheduler.ts"),
    },
    bundle: true,
    minify: true,
    treeShaking: true,
    format: "esm",
    platform: "browser",
    write: false,
    metafile: true,
  });
}

describe("Void bundle boundaries", () => {
  it("boots the island scheduler without importing the Luna renderer", async () => {
    const server = await createServer({
      root: join(import.meta.dirname, "../../examples-void"),
      configFile: false,
      plugins: [voidLuna({ islands: {} })],
      server: { middlewareMode: true },
      optimizeDeps: {
        noDiscovery: true,
        exclude: ["@luna_ui/luna", "@luna_ui/luna/jsx-runtime"],
      },
    });
    try {
      const resolved = await server.pluginContainer.resolveId("virtual:void-islands-client");
      const entry = await server.pluginContainer.load(resolved!.id);
      const code = typeof entry === "string" ? entry : entry!.code;
      const result = await bundle(code);
      const moonModules = Object.keys(result.metafile!.inputs).filter((path) =>
        path.includes("_build/"),
      );
      expect(moonModules).toEqual([]);
    } finally {
      await server.close();
    }
  });

  // Leave headroom for normal changes while catching whole-API retention.
  it("keeps DOM-only Void islands independent of the hydrator", async () => {
    const result = await bundle(`
      import { createSignal } from './index';
      import { jsx } from './jsx-runtime';
      import { defineLunaIsland, initLunaIslands } from './void/client';
      ${counter}
      initLunaIslands({ counter: async () => ({ default: defineLunaIsland(Counter) }) });
    `);
    expect(gzipSync(result.outputFiles[0].contents).length).toBeLessThan(8 * 1024);
  });

  it("loads the form helper without an SSR renderer or another UI runtime", async () => {
    const result = await bundle(`export { useIslandForm } from './void/form';`);
    const inputs = Object.keys(result.metafile!.inputs);
    expect(inputs.some((path) => /src\/ssr[/.]|node_modules\/(react|solid-js)\//.test(path))).toBe(
      false,
    );
    expect(gzipSync(result.outputFiles[0].contents).length).toBeLessThan(10 * 1024);
  });

  it.each([
    { name: "hydrate", invoke: "hydrate(document.body, Counter)", budget: 18 * 1024 },
    {
      name: "renderToString",
      invoke: "export const html = renderToString(Counter)",
      budget: 12 * 1024,
    },
  ])("tree-shakes the $name counter", async ({ name, invoke, budget }) => {
    const result = await bundle(`
      import { createSignal } from './index';
      import { jsx } from './ssr/jsx-runtime';
      import { ${name} } from './ssr';
      ${counter}
      ${invoke};
    `);
    expect(gzipSync(result.outputFiles[0].contents).length).toBeLessThan(budget);
  });
});
