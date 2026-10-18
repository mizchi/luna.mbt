import { createComponent } from "solid-js";
import { hydrate } from "solid-js/web";
import type { Island } from "@luna_ui/luna/void/client";
import { SolidCounter } from "./counter.solid";

export default {
  mount(element, props) {
    return hydrate(() => createComponent(SolidCounter, props), element, { renderId: "void-solid" });
  },
} satisfies Island<{ initialCount: number }>;
