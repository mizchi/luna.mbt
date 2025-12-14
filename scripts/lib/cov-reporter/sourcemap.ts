/**
 * Source map loading utilities
 */

import { readFile, readdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { SourceMapConsumer } from "source-map";

export async function loadSourceMaps(
  sourceMapDir: string
): Promise<Map<string, SourceMapConsumer>> {
  const maps = new Map<string, SourceMapConsumer>();

  if (!existsSync(sourceMapDir)) {
    return maps;
  }

  async function scanDir(dir: string) {
    const entries = await readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = join(dir, entry.name);
      if (entry.isDirectory()) {
        await scanDir(fullPath);
      } else if (entry.name.endsWith(".js.map")) {
        const content = await readFile(fullPath, "utf-8");
        const rawMap = JSON.parse(content);
        const consumer = await new SourceMapConsumer(rawMap);
        const jsFile = fullPath.replace(".map", "");
        maps.set(jsFile, consumer);
      }
    }
  }

  await scanDir(sourceMapDir);
  return maps;
}

export function destroySourceMaps(
  maps: Map<string, SourceMapConsumer>
): void {
  for (const sm of maps.values()) {
    sm.destroy();
  }
}
