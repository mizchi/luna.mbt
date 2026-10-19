import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createRoot } from "../../src/index";
import { useActionForm, SolActionError } from "../../src/sol/form";

const fetchMock = vi.fn<typeof fetch>();
const refresh = vi.fn();
const navigate = vi.fn();
let dispose: () => void;

function form() {
  return createRoot((stop) => {
    dispose = stop;
    return useActionForm({ name: "initial" }, { refresh, navigate });
  });
}

beforeEach(() => {
  vi.stubGlobal("fetch", fetchMock);
  vi.stubGlobal("location", { href: "https://example.com/form", origin: "https://example.com" });
});
afterEach(() => {
  dispose?.();
  vi.unstubAllGlobals();
  vi.clearAllMocks();
});

describe("Sol transport with shared action form state", () => {
  it("compares arrays structurally and non-plain values by identity like Void", () => {
    const fields = createRoot((stop) => {
      dispose = stop;
      return useActionForm({ date: new Date(0), items: [] as string[] }, { refresh, navigate });
    });
    fields.setData("items", []);
    expect(fields.hasChanges).toBe(false);
    fields.setData("date", new Date(0));
    expect(fields.hasChanges).toBe(true);
    fields.reset();
    fields.setData("items", new Array<string>(3));
    expect(fields.hasChanges).toBe(true);
  });
  it("deduplicates submits, preserves edits while pending, and delegates refresh", async () => {
    let resolve!: (response: Response) => void;
    fetchMock.mockReturnValueOnce(
      new Promise((done) => {
        resolve = done;
      }),
    );
    const fields = form();
    fields.setData("name", "submitted");
    const first = fields.post("/_action/save");
    expect(fields.post("/_action/save")).toBe(first);
    expect(fields.pending).toBe(true);
    fields.setData("name", "edited during request");
    resolve(Response.json({ id: 42 }));
    await first;
    expect(fields.pending).toBe(false);
    expect(fields.wasSuccessful).toBe(true);
    expect(fields.hasChanges).toBe(true);
    expect(refresh).toHaveBeenCalledOnce();
    fields.reset();
    expect(fields.data.name).toBe("submitted");
    expect(fetchMock).toHaveBeenCalledWith(
      "https://example.com/_action/save",
      expect.objectContaining({ mode: "same-origin", credentials: "same-origin" }),
    );
  });

  it("keeps input on validation and HTTP errors, redirects through the navigation port", async () => {
    const fields = form();
    fields.setData("name", "edited");
    fetchMock.mockResolvedValueOnce(
      Response.json({ fieldErrors: { name: "required" } }, { status: 422 }),
    );
    await fields.post("/_action/save");
    expect(fields.errors).toEqual({ name: "required" });
    expect(fields.data.name).toBe("edited");
    fetchMock.mockResolvedValueOnce(Response.json({ error: "forbidden" }, { status: 403 }));
    await fields.post("/_action/save");
    expect(fields.error).toBeInstanceOf(SolActionError);
    expect(fields.error?.status).toBe(403);
    expect(fields.data.name).toBe("edited");
    fetchMock.mockResolvedValueOnce(Response.json({ redirect: "/done" }));
    await fields.post("/_action/save");
    expect(navigate).toHaveBeenCalledWith("https://example.com/done");
    expect(refresh).not.toHaveBeenCalled();
  });

  it.each([
    "https://evil.test/action",
    "//evil.test/action",
    "javascript:alert(1)",
    "https://user:secret@example.com/action",
  ])("rejects unsafe action %s before fetch", async (url) => {
    await expect(form().post(url)).rejects.toThrow();
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("distinguishes malformed success JSON from network failure and cancellation", async () => {
    const fields = form();
    fetchMock.mockResolvedValueOnce(new Response("not JSON"));
    await expect(fields.post("/_action/save")).rejects.toMatchObject({ kind: "decode" });
    fetchMock.mockRejectedValueOnce(new TypeError("offline"));
    await expect(fields.post("/_action/save")).rejects.toMatchObject({ kind: "network" });
    fetchMock.mockRejectedValueOnce(new DOMException("aborted", "AbortError"));
    await expect(fields.post("/_action/save")).rejects.toMatchObject({ kind: "aborted" });
    expect(fields.pending).toBe(false);
  });

  it("aborts on owner disposal and suppresses stale success and navigation", async () => {
    let resolve!: (response: Response) => void;
    fetchMock.mockReturnValueOnce(
      new Promise((done) => {
        resolve = done;
      }),
    );
    const fields = form();
    const request = fields.post("/_action/save");
    const signal = fetchMock.mock.calls[0][1]?.signal;
    dispose();
    expect(signal?.aborted).toBe(true);
    resolve(Response.json({ id: 42 }));
    await request;
    expect(refresh).not.toHaveBeenCalled();
    expect(navigate).not.toHaveBeenCalled();
    expect(fields.wasSuccessful).toBe(false);
  });

  it("classifies a connection lost while reading the response as a network failure", async () => {
    const response = new Response("pending");
    vi.spyOn(response, "text").mockRejectedValueOnce(new TypeError("connection closed"));
    fetchMock.mockResolvedValueOnce(response);
    const fields = form();
    await expect(fields.post("/_action/save")).rejects.toMatchObject({ kind: "network" });
    expect(fields.pending).toBe(false);
  });
});
