/** A Void scheduling strategy. Rendering is delegated to each island module. */
export type IslandStrategy = "load" | "idle" | "visible" | `media:${string}`;
import type { Island } from "../../../loader/src/runtime/islands";
export type { Dispose, Island } from "../../../loader/src/runtime/islands";

export type IslandManifest = Record<string, () => Promise<{ default: Island<never> }>>;

export function assertIslandId(id: string): void {
  if (!/^[a-zA-Z][\w-]*$/.test(id)) throw new Error(`Invalid island ID: ${id}`);
}

export function assertStrategy(strategy: string): asserts strategy is IslandStrategy {
  if (!["load", "idle", "visible"].includes(strategy) && !/^media:.+/.test(strategy)) {
    throw new Error(`Invalid island strategy: ${strategy}`);
  }
}
