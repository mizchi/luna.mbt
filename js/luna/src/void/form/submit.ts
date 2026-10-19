import { VoidActionError, categorizeActionError, getValidationErrors } from "void/pages-client";
import { fetchAction, sameOriginActionUrl } from "../../../../loader/src/runtime/http";
import type { ActionResult } from "../../form/contracts";

async function readErrorBody(response: Response): Promise<unknown> {
  try {
    if (response.headers.get("content-type")?.includes("application/json"))
      return await response.json();
    return (await response.text()) || null;
  } catch {
    return null;
  }
}

/** Void island actions use JSON and refresh the document after a successful write. */
export async function submitIslandAction(
  url: string,
  method: string,
  data: Record<string, unknown>,
  signal: AbortSignal,
): Promise<ActionResult<VoidActionError>> {
  // Use the validated absolute URL so a document <base> cannot change its origin.
  const response = await fetchAction(url, method, data, signal);
  if (response.redirected) return { kind: "redirect", url: sameOriginActionUrl(response.url) };
  if (response.ok) return { kind: "success" };

  const body = await readErrorBody(response);
  const errors = response.status === 422 ? getValidationErrors(body) : null;
  if (errors) return { kind: "validation", errors };
  const error = new VoidActionError({
    body,
    status: response.status,
    statusText: response.statusText,
    url,
  });
  if (categorizeActionError(response.status) === "boundary") throw error;
  return { kind: "error", error };
}
