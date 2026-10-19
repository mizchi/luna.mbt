import type { VoidActionError } from "void/pages-client";
import type { ActionFormReturn } from "../../form/contracts";

export type IslandFormReturn<T extends Record<string, unknown>> = ActionFormReturn<
  T,
  VoidActionError
>;
