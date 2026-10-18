// @vitest-environment node
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, realpathSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createServer } from "vite";
import { describe, expect, it } from "vitest";
import { voidLuna } from "../../src/void/plugin";

describe("Void Vite adapter", () => {
  it("uses Vite's root instead of cwd and supplies all four Void entry points", async () => {
    const root = realpathSync(mkdtempSync(join(tmpdir(), "luna-void-plugin-")));
    mkdirSync(join(root, "pages"));
    writeFileSync(join(root, "pages/index.island.tsx"), "export default () => null;");
    writeFileSync(join(root, "pages/layout.tsx"), "export default () => null;");
    const server = await createServer({
      root,
      configFile: false,
      plugins: [voidLuna({ islands: { counter: './src/quote"counter.ts' } })],
      server: { middlewareMode: true },
      optimizeDeps: { noDiscovery: true, exclude: ["@luna_ui/luna", "@luna_ui/luna/jsx-runtime"] },
    });
    try {
      for (const name of ["pages", "islands"]) {
        const renderer = await server.pluginContainer.resolveId(`virtual:void-${name}-renderer`);
        expect(renderer).toBeTruthy();
        const source = await server.pluginContainer.load(renderer!.id);
        const code = typeof source === "string" ? source : source!.code;
        expect(code).toContain("createPageRenderer(components, layoutTree)");
        expect(code).toContain(join(root, "pages/index.island.tsx"));
        expect(code).toContain('"index": ["layout"]');
        const client = await server.pluginContainer.resolveId(`virtual:void-${name}-client`);
        const entry = await server.pluginContainer.load(client!.id);
        const clientCode = typeof entry === "string" ? entry : entry!.code;
        expect(clientCode).toContain(JSON.stringify(join(root, 'src/quote"counter.ts')));
        expect(clientCode).toContain("initLunaIslands");
        expect(clientCode).not.toContain("pages/index");
      }
    } finally {
      await server.close();
      rmSync(root, { recursive: true, force: true });
    }
  });

  it("rejects invalid registry entries before Vite starts", () => {
    expect(() => voidLuna({ islands: { 'invalid"id': "./counter.ts" } })).toThrow(/island/i);
    expect(() => voidLuna({ islands: { counter: "" } })).toThrow(/module/i);
  });
});
