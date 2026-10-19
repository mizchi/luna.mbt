import { isEqualFormValue } from "void/pages-client";
import type { VoidActionError } from "void/pages-client";
import { createActionForm } from "../form/state";
import type { IslandFormReturn } from "./form/contracts";
import { submitIslandAction } from "./form/submit";

export type { IslandFormReturn } from "./form/contracts";

/** Router-free form state for a Luna island. Create inside its reactive root. */
export function useIslandForm<T extends Record<string, unknown>>(defaults: T): IslandFormReturn<T> {
  return createActionForm<T, VoidActionError>(defaults, {
    submit: submitIslandAction,
    navigation: {
      navigate: (url) => globalThis.location.assign(url),
      refresh: () => globalThis.location.reload(),
    },
    isEqualValue: isEqualFormValue,
  });
}
