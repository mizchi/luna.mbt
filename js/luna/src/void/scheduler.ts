import { initIslands } from "void/pages-client";
import { createIslandLifecycle } from "../../../loader/src/runtime/islands";
import type { Dispose, Island, IslandManifest } from "./contracts";

/** Schedule mixed-renderer islands without loading any rendering runtime. */
export function initLunaIslands(manifest: IslandManifest): Dispose {
  const lifecycle = createIslandLifecycle();
  initIslands(Object.assign(Object.create(null), manifest), async (element, module, props) => {
    const mounted = await lifecycle.mount(element, () => {
      const island = (module as { default?: Island }).default;
      if (!island || typeof island.mount !== "function") {
        throw new TypeError(
          "Void island modules must default-export an object with mount(element, props)",
        );
      }
      return island.mount(element, props);
    });
    if (mounted) element.setAttribute("data-luna-mounted", "true");
  });
  return lifecycle.dispose;
}

export type { Dispose, Island, IslandManifest } from "./contracts";
