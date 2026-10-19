import { fetchAction, sameOriginActionUrl } from "../../../loader/src/runtime/http";
import type { ActionResult, NavigationPort } from "../form/contracts";
import { createActionForm } from "../form/state";

export type { ActionFormReturn, NavigationPort } from "../form/contracts";

export class SolActionError extends Error {
  constructor(
    public readonly kind: "http" | "network" | "decode" | "aborted",
    message: string,
    public readonly status = 0,
    options?: ErrorOptions,
  ) {
    super(message, options);
    this.name = "SolActionError";
  }
}

function transportError(cause: unknown, signal: AbortSignal): SolActionError {
  const aborted =
    signal.aborted ||
    (cause !== null && typeof cause === "object" && "name" in cause && cause.name === "AbortError");
  return new SolActionError(
    aborted ? "aborted" : "network",
    aborted ? "Action aborted" : "Network error",
    0,
    { cause },
  );
}

async function submit(
  url: string,
  method: string,
  data: Record<string, unknown>,
  signal: AbortSignal,
): Promise<ActionResult<SolActionError>> {
  // URL contract violations stay TypeErrors, before the request starts.
  const target = sameOriginActionUrl(url);
  let response: Response;
  try {
    response = await fetchAction(target, method, data, signal);
  } catch (cause) {
    throw transportError(cause, signal);
  }
  if (response.redirected) return { kind: "redirect", url: sameOriginActionUrl(response.url) };
  const text = await response.text().catch((cause) => {
    throw transportError(cause, signal);
  });
  let body: unknown;
  try {
    body = JSON.parse(text);
  } catch (cause) {
    if (response.ok)
      throw new SolActionError("decode", "Action response is not JSON", response.status, { cause });
  }
  const object = body && typeof body === "object" ? (body as Record<string, unknown>) : undefined;
  if (!response.ok) {
    const errors = object?.fieldErrors;
    if (
      response.status === 422 &&
      errors &&
      typeof errors === "object" &&
      !Array.isArray(errors) &&
      Object.values(errors).every((value) => typeof value === "string")
    ) {
      return { kind: "validation", errors: errors as Record<string, string> };
    }
    return {
      kind: "error",
      error: new SolActionError(
        "http",
        typeof object?.error === "string" ? object.error : text || response.statusText,
        response.status,
      ),
    };
  }
  if (typeof object?.redirect === "string")
    return { kind: "redirect", url: sameOriginActionUrl(object.redirect) };
  return { kind: "success" };
}

function isEqualValue(left: unknown, right: unknown): boolean {
  if (Object.is(left, right)) return true;
  if (Array.isArray(left) || Array.isArray(right)) {
    return (
      Array.isArray(left) &&
      Array.isArray(right) &&
      left.length === right.length &&
      left.every((value, index) => isEqualValue(value, right[index]))
    );
  }
  if (!left || !right || typeof left !== "object" || typeof right !== "object") return false;
  const plain = (value: object) =>
    Object.getPrototypeOf(value) === Object.prototype || Object.getPrototypeOf(value) === null;
  if (!plain(left) || !plain(right)) return false;
  const a = left as Record<string, unknown>;
  const b = right as Record<string, unknown>;
  const keys = Object.keys(a);
  return (
    keys.length === Object.keys(b).length &&
    keys.every((key) => Object.hasOwn(b, key) && isEqualValue(a[key], b[key]))
  );
}

/** JSON forms in Sol islands. The default port is installed by sol-nav. */
export function useActionForm<T extends Record<string, unknown>>(
  defaults: T,
  navigation?: NavigationPort,
) {
  const port = () => {
    const value = (globalThis as typeof globalThis & { __LUNA_NAVIGATION__?: NavigationPort })
      .__LUNA_NAVIGATION__;
    if (!value)
      throw new Error(
        "Sol navigation is not initialized. Load sol-nav or supply a NavigationPort.",
      );
    return value;
  };
  return createActionForm<T, SolActionError>(defaults, {
    submit,
    isEqualValue,
    navigation: navigation ?? {
      navigate: (url) => port().navigate(url),
      refresh: () => port().refresh(),
    },
  });
}
