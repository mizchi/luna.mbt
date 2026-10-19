import type { NavigationPort } from "../../../loader/src/runtime/navigation";
export type { NavigationPort } from "../../../loader/src/runtime/navigation";

export type ActionResult<E> =
  | { kind: "success" }
  | { kind: "redirect"; url: string }
  | { kind: "validation"; errors: Record<string, string> }
  | { kind: "error"; error: E };

export interface FormAdapter<T extends Record<string, unknown>, E> {
  submit(url: string, method: string, data: T, signal: AbortSignal): Promise<ActionResult<E>>;
  navigation: NavigationPort;
  isEqualValue(left: unknown, right: unknown): boolean;
}

/** Reactive getters; read them inside a Luna JSX accessor or effect. */
export interface ActionFormReturn<T extends Record<string, unknown>, E> {
  readonly data: Readonly<T>;
  readonly errors: Readonly<Record<string, string>>;
  readonly error: E | null;
  readonly pending: boolean;
  readonly hasChanges: boolean;
  readonly wasSuccessful: boolean;
  readonly recentlySuccessful: boolean;
  setData<K extends keyof T & string>(field: K, value: T[K]): void;
  reset(...fields: ReadonlyArray<keyof T & string>): void;
  clearErrors(...fields: ReadonlyArray<string>): void;
  clearError(): void;
  post(url: string): Promise<void>;
  put(url: string): Promise<void>;
  patch(url: string): Promise<void>;
  delete(url: string): Promise<void>;
}
