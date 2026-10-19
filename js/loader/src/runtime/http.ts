/** Resolve against location, not document.baseURI, before sending user data. */
export function sameOriginActionUrl(value: string): string {
  const current = globalThis.location;
  const target = new URL(value, current.href);
  if (
    (target.protocol !== "http:" && target.protocol !== "https:") ||
    target.origin !== current.origin ||
    target.username ||
    target.password
  )
    throw new TypeError("Actions and redirects must use the current HTTP(S) origin.");
  return target.href;
}

export async function fetchAction(
  url: string,
  method: string,
  data: Record<string, unknown>,
  signal: AbortSignal,
): Promise<Response> {
  return fetch(sameOriginActionUrl(url), {
    method,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
    signal,
    mode: "same-origin",
    credentials: "same-origin",
  });
}
