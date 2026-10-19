// @vitest-environment node
import { resolve } from "node:path";
import { rolldown, type OutputChunk } from "rolldown";
import { expect, it } from "vitest";
import configs from "./rolldown.config.mjs";

it("native loader imports exclude the legacy tracker while lib keeps its public export", async () => {
  const files = new Map<string, OutputChunk>();
  for (const { output: options, ...input } of configs.filter(
    (config) => config.output.format === "esm",
  )) {
    const bundle = await rolldown({
      ...input,
      input:
        typeof input.input === "string"
          ? resolve(import.meta.dirname, input.input)
          : Object.fromEntries(
              Object.entries(input.input).map(([name, path]) => [
                name,
                resolve(import.meta.dirname, path),
              ]),
            ),
    });
    try {
      const { output } = await bundle.generate(options);
      for (const chunk of output) if (chunk.type === "chunk") files.set(chunk.fileName, chunk);
    } finally {
      await bundle.close();
    }
  }
  function imports(file: string, seen = new Set<string>()): string {
    if (seen.has(file)) return "";
    seen.add(file);
    const chunk = files.get(file)!;
    return chunk.code + chunk.imports.map((dependency) => imports(dependency, seen)).join("");
  }
  for (const entry of ["loader.js", "wc-loader.js"]) {
    expect(imports(entry)).not.toContain("createLoadedTracker");
  }
  expect(imports("lib.js")).toContain("createLoadedTracker");
  // Sol copies lib.js as a standalone built-in asset.
  expect(files.get("lib.js")!.imports).toEqual([]);
});
