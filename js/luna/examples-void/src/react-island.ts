import { createElement } from "react";
import { hydrateRoot } from "react-dom/client";
import type { Island } from "@luna_ui/luna/void/client";
import { ReactCounter } from "./react-counter";

export default {
  mount(element, props) {
    const root = hydrateRoot(element, createElement(ReactCounter, props));
    return () => root.unmount();
  },
} satisfies Island<{ initialCount: number }>;
