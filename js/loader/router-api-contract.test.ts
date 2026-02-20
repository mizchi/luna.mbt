import { describe, test, expect, beforeEach } from "vitest";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

type LoaderPackageJson = {
  exports: Record<string, string>;
};

function readPackageJson(): LoaderPackageJson {
  const raw = readFileSync(join(__dirname, "package.json"), "utf-8");
  return JSON.parse(raw) as LoaderPackageJson;
}

describe("Loader Router Public API Contract", () => {
  test("package exports include required router and boot entry points", () => {
    const pkg = readPackageJson();
    const requiredSubpaths = [
      ".",
      "./boot",
      "./boot/loader",
      "./boot/router",
      "./hydration",
      "./router",
      "./router/hybrid",
      "./router/spa",
      "./router/scroll",
      "./router/navigation",
      "./router/navigation-fallback",
      "./src/boot",
      "./src/boot/loader",
      "./src/boot/router",
      "./src/hydration",
      "./src/router",
      "./src/router/hybrid",
      "./src/router/spa",
      "./src/router/scroll",
      "./src/router/navigation",
      "./src/router/navigation-fallback",
    ];

    requiredSubpaths.forEach((subpath) => {
      expect(pkg.exports[subpath], `missing export: ${subpath}`).toBeTypeOf("string");
    });
  });

  test("build config includes entries for exported runtime modules", async () => {
    const config = (await import("./rolldown.config.mjs")).default as Array<{
      input?: Record<string, string>;
    }>;
    const entryInput = config[0]?.input ?? {};

    expect(entryInput.hydration).toBe("./src/hydration.ts");
    expect(entryInput["router/navigation"]).toBe("./src/router/navigation.ts");
  });

  test("boot entry keeps core boot API symbols", async () => {
    const boot = await import("./src/boot/index.ts");

    expect(typeof boot.boot).toBe("function");
    expect(typeof boot.autoBoot).toBe("function");
    expect(typeof boot.ChunkLoader).toBe("function");
    expect(typeof boot.MinimalRouter).toBe("function");
    expect(typeof boot.getLoader).toBe("function");
    expect(typeof boot.getRouter).toBe("function");
  });

  describe("navigation runtime contract", () => {
    beforeEach(() => {
      delete (window as Window & { __LUNA_NAV_ROUTER__?: unknown }).__LUNA_NAV_ROUTER__;
    });

    test("getRouter registers a global navigation router singleton", async () => {
      const { getRouter } = await import("./src/boot/router.ts");
      const { NAV_ROUTER_KEY, getNavigationRouter } = await import("./src/router/navigation.ts");

      const router = getRouter();

      expect((window as Record<string, unknown>)[NAV_ROUTER_KEY]).toBe(router);
      expect(getNavigationRouter()).toBe(router);
      expect(getRouter()).toBe(router);
    });

    test("fallback installer is idempotent", async () => {
      const { installFallbackNavigationRouter } = await import(
        "./src/router/navigation-fallback.ts"
      );
      const { getNavigationRouter } = await import("./src/router/navigation.ts");

      const router1 = installFallbackNavigationRouter();
      const router2 = installFallbackNavigationRouter();

      expect(router1).toBe(router2);
      expect(getNavigationRouter()).toBe(router1);
    });
  });
});
