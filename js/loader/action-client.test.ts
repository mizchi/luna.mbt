import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

// Exercise the actual inline FFI, including callbacks, without depending on MoonBit's enum layout.
const source = readFileSync(
  resolve(import.meta.dirname, "../../sol/src/action/client.mbt"),
  "utf8",
);
const block = source.match(
  /extern "js" fn ffi_request_action_cb\([\s\S]*?\) -> Unit =\n((?:  #\|[^\n]*\n?)+)/,
);
if (!block) throw new Error("Missing Sol request transport");
const request = Function(`return (${block[1].replace(/^  #\| ?/gm, "")})`)() as (
  url: string,
  data: object,
  method: string,
  headers: unknown[],
  signals: AbortSignal[],
  timeout: number,
  callback: (kind: string, status: number, message: string, data: unknown) => void,
) => Promise<void>;
const fetchMock = vi.fn<typeof fetch>();

beforeEach(() => {
  vi.stubGlobal("fetch", fetchMock);
  vi.stubGlobal("location", { href: "https://example.com/form", origin: "https://example.com" });
});
afterEach(() => {
  vi.unstubAllGlobals();
  vi.clearAllMocks();
});

async function invoke(url = "/_action/save", signals: AbortSignal[] = []) {
  const callback = vi.fn();
  await request(url, { name: "private" }, "POST", [], signals, 0, callback);
  expect(callback).toHaveBeenCalledOnce();
  return callback.mock.calls[0];
}

describe("Sol MoonBit action transport", () => {
  it.each([
    "https://evil.test/action",
    "//evil.test/action",
    "javascript:alert(1)",
    "https://user:secret@example.com/action",
  ])("blocks %s before sending data", async (url) => {
    expect((await invoke(url))[0]).toBe("network");
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("sends absolute same-origin JSON and returns a stable success contract", async () => {
    fetchMock.mockResolvedValueOnce(Response.json({ id: 42 }));
    expect(await invoke()).toEqual(["success", 200, "", { id: 42 }]);
    expect(fetchMock).toHaveBeenCalledWith(
      "https://example.com/_action/save",
      expect.objectContaining({ mode: "same-origin", credentials: "same-origin" }),
    );
  });

  it("handles HTTP redirects before decoding HTML", async () => {
    const response = new Response("<html>done</html>");
    Object.defineProperties(response, {
      redirected: { value: true },
      url: { value: "https://example.com/done" },
    });
    fetchMock.mockResolvedValueOnce(response);
    expect((await invoke()).slice(0, 3)).toEqual(["redirect", 200, "https://example.com/done"]);
  });

  it("rejects unsafe JSON redirect instructions", async () => {
    fetchMock.mockResolvedValueOnce(Response.json({ redirect: "javascript:alert(1)" }));
    expect((await invoke())[0]).toBe("network");
  });

  it("separates validation, HTTP error, malformed JSON, cancellation and network errors", async () => {
    fetchMock.mockResolvedValueOnce(
      Response.json({ fieldErrors: { name: "required" } }, { status: 422 }),
    );
    expect(await invoke()).toEqual(["validation", 422, "", { name: "required" }]);
    fetchMock.mockResolvedValueOnce(new Response("unauthorized", { status: 401 }));
    expect((await invoke()).slice(0, 3)).toEqual(["error", 401, "unauthorized"]);
    fetchMock.mockResolvedValueOnce(new Response("not JSON"));
    expect((await invoke())[0]).toBe("decode");
    fetchMock.mockRejectedValueOnce(new DOMException("stopped", "AbortError"));
    expect((await invoke())[0]).toBe("aborted");
    fetchMock.mockRejectedValueOnce(new TypeError("offline"));
    expect((await invoke())[0]).toBe("network");
  });

  it("honors the timeout and calls the callback once", async () => {
    fetchMock.mockImplementationOnce(
      (_url, options) =>
        new Promise((_resolve, reject) => {
          options!.signal!.addEventListener("abort", () => reject(options!.signal!.reason), {
            once: true,
          });
        }),
    );
    const callback = vi.fn();
    await request("/_action/save", {}, "POST", [], [], 5, callback);
    expect(callback).toHaveBeenCalledExactlyOnceWith("aborted", 0, "Action aborted", null);
  });

  it("does not turn an exception in user code into a second transport callback", async () => {
    fetchMock.mockResolvedValueOnce(Response.json({ id: 42 }));
    const callback = vi.fn(() => {
      throw new Error("user callback failed");
    });
    await expect(request("/_action/save", {}, "POST", [], [], 0, callback)).rejects.toThrow(
      "user callback failed",
    );
    expect(callback).toHaveBeenCalledOnce();
  });
});
