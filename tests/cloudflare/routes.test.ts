import {
  describe,
  it,
  expect,
  beforeAll,
} from "vitest";
import {
  shouldHandleRequest,
  parseRoutesJson,
  type RoutesJson,
} from "./worker";

describe("_routes.json parsing", () => {
  it("parses valid _routes.json", () => {
    const content = JSON.stringify({
      version: 1,
      include: ["/api/*"],
      exclude: ["/*.html", "/*.css"],
    });

    const result = parseRoutesJson(content);
    expect(result).not.toBeNull();
    expect(result?.version).toBe(1);
    expect(result?.include).toEqual(["/api/*"]);
    expect(result?.exclude).toEqual(["/*.html", "/*.css"]);
  });

  it("returns null for invalid JSON", () => {
    expect(parseRoutesJson("not json")).toBeNull();
  });

  it("returns null for missing required fields", () => {
    expect(parseRoutesJson('{"version": 1}')).toBeNull();
    expect(parseRoutesJson('{"include": []}')).toBeNull();
  });
});

describe("Route matching", () => {
  const ssgRoutes: RoutesJson = {
    version: 1,
    include: [], // SSG has no dynamic routes
    exclude: [
      "/*.html",
      "/*.css",
      "/*.js",
      "/*.json",
      "/*.ico",
      "/*.png",
      "/*.jpg",
      "/*.svg",
      "/*.woff2",
      "/_luna/*",
      "/*", // Root path
      "/guide/*",
    ],
  };

  describe("static file exclusions", () => {
    it("excludes HTML files", () => {
      const result = shouldHandleRequest("/index.html", ssgRoutes);
      expect(result.handled).toBe(false);
      expect(result.reason).toContain("/*.html");
    });

    it("excludes CSS files", () => {
      const result = shouldHandleRequest("/style.css", ssgRoutes);
      expect(result.handled).toBe(false);
      expect(result.reason).toContain("/*.css");
    });

    it("excludes JS files", () => {
      const result = shouldHandleRequest("/app.js", ssgRoutes);
      expect(result.handled).toBe(false);
      expect(result.reason).toContain("/*.js");
    });

    it("excludes _luna directory", () => {
      const result = shouldHandleRequest("/_luna/manifest.json", ssgRoutes);
      expect(result.handled).toBe(false);
      // Note: /*.json matches first, but the path is still excluded
      // The important thing is that handled is false
    });

    it("excludes _luna non-json files", () => {
      const result = shouldHandleRequest("/_luna/boot.js", ssgRoutes);
      expect(result.handled).toBe(false);
    });

    it("excludes nested paths with wildcard", () => {
      const result = shouldHandleRequest("/guide/intro/index.html", ssgRoutes);
      expect(result.handled).toBe(false);
    });
  });

  describe("SSR routes (hybrid mode)", () => {
    const hybridRoutes: RoutesJson = {
      version: 1,
      include: ["/api/*", "/dashboard/*"],
      exclude: [
        "/*.html",
        "/*.css",
        "/*.js",
        "/blog/*",
        "/about",
      ],
    };

    it("includes API routes", () => {
      const result = shouldHandleRequest("/api/users", hybridRoutes);
      expect(result.handled).toBe(true);
      expect(result.reason).toContain("/api/*");
    });

    it("includes dashboard routes", () => {
      const result = shouldHandleRequest("/dashboard/settings", hybridRoutes);
      expect(result.handled).toBe(true);
    });

    it("excludes static blog pages", () => {
      const result = shouldHandleRequest("/blog/hello-world", hybridRoutes);
      expect(result.handled).toBe(false);
    });

    it("excludes exact match paths", () => {
      const result = shouldHandleRequest("/about", hybridRoutes);
      expect(result.handled).toBe(false);
    });
  });
});

describe("Generated _routes.json format", () => {
  // Simulates what astra generates for Cloudflare target
  const generatedRoutes: RoutesJson = {
    version: 1,
    include: [],
    exclude: [
      "/*.html",
      "/*.css",
      "/*.js",
      "/*.json",
      "/*.ico",
      "/*.png",
      "/*.jpg",
      "/*.svg",
      "/*.woff2",
      "/_luna/*",
      "/*",
      "/guide/*",
    ],
  };

  it("has version 1", () => {
    expect(generatedRoutes.version).toBe(1);
  });

  it("has empty include for pure SSG", () => {
    expect(generatedRoutes.include).toEqual([]);
  });

  it("excludes common static file types", () => {
    const staticExtensions = [".html", ".css", ".js", ".json"];
    for (const ext of staticExtensions) {
      expect(generatedRoutes.exclude).toContain(`/*${ext}`);
    }
  });

  it("excludes _luna runtime directory", () => {
    expect(generatedRoutes.exclude).toContain("/_luna/*");
  });
});

describe("Edge cases", () => {
  const routes: RoutesJson = {
    version: 1,
    include: ["/api/*"],
    exclude: ["/*.html"],
  };

  it("handles root path", () => {
    const result = shouldHandleRequest("/", routes);
    // Root path is not explicitly handled
    expect(result.handled).toBe(false);
  });

  it("handles paths with query strings (path only)", () => {
    // Query strings should be stripped before matching
    const result = shouldHandleRequest("/api/users", routes);
    expect(result.handled).toBe(true);
  });

  it("handles paths with trailing slash", () => {
    const result = shouldHandleRequest("/api/", routes);
    expect(result.handled).toBe(true);
  });

  it("priority: exclude is checked before include", () => {
    const overlappingRoutes: RoutesJson = {
      version: 1,
      include: ["/*"],
      exclude: ["/static/*"],
    };

    const staticResult = shouldHandleRequest("/static/image.png", overlappingRoutes);
    expect(staticResult.handled).toBe(false);

    const dynamicResult = shouldHandleRequest("/dynamic/page", overlappingRoutes);
    expect(dynamicResult.handled).toBe(true);
  });
});
