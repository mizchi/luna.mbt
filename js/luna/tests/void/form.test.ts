import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createRoot, createRenderEffect } from "../../src/index";
import { hydrate, renderToString } from "../../src/ssr";
import { jsx } from "../../src/ssr/jsx-runtime";
import { useIslandForm } from "../../src/void/form";

const disposers: Array<() => void> = [];
const reload = vi.fn();
const assign = vi.fn();
const fetchMock = vi.fn<typeof fetch>();

function form<T extends Record<string, unknown>>(defaults: T) {
  return createRoot((dispose) => {
    disposers.push(dispose);
    return useIslandForm(defaults);
  });
}

function deferred<T>() {
  let resolve!: (value: T) => void;
  let reject!: (error: unknown) => void;
  const promise = new Promise<T>((yes, no) => {
    resolve = yes;
    reject = no;
  });
  return { promise, resolve, reject };
}

beforeEach(() => {
  vi.useFakeTimers();
  vi.stubGlobal("fetch", fetchMock);
  vi.stubGlobal("location", {
    href: "https://example.com/notes/42?view=current",
    origin: "https://example.com",
    reload,
    assign,
  });
});

afterEach(() => {
  for (const dispose of disposers.splice(0)) dispose();
  vi.useRealTimers();
  vi.unstubAllGlobals();
  vi.clearAllMocks();
  document.body.innerHTML = "";
});

describe("Void Luna useIslandForm", () => {
  it("tracks independent form values, structural changes, and partial resets", () => {
    const defaults = { title: "First", tags: ["a"], count: 1 };
    const first = form(defaults);
    const second = form(defaults);
    const changed: boolean[] = [];
    createRoot((dispose) => {
      disposers.push(dispose);
      createRenderEffect(() => changed.push(first.hasChanges));
    });
    expect(first.data).toEqual(defaults);
    expect(first.pending).toBe(false);
    expect(first.errors).toEqual({});
    expect(first.error).toBeNull();
    expect(first.wasSuccessful).toBe(false);
    expect(first.recentlySuccessful).toBe(false);
    first.setData("tags", ["a"]);
    expect(first.hasChanges).toBe(false);
    first.setData("title", "Edited");
    first.setData("count", 2);
    expect(first.hasChanges).toBe(true);
    expect(changed.at(-1)).toBe(true);
    expect(defaults.title).toBe("First");
    expect(second.data.title).toBe("First");
    first.reset("title");
    expect(first.data).toEqual({ ...defaults, count: 2 });
    first.reset();
    expect(first.data).toEqual(defaults);
    expect(first.hasChanges).toBe(false);
  });

  it.each(["post", "put", "patch", "delete"] as const)(
    "sends %s as JSON and reloads on success",
    async (method) => {
      fetchMock.mockResolvedValueOnce(Response.json({ success: true }));
      const fields = form({ title: "Saved" });
      await fields[method]("/?add");
      expect(fetchMock).toHaveBeenCalledWith(
        "https://example.com/?add",
        expect.objectContaining({
          method: method.toUpperCase(),
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ title: "Saved" }),
          signal: expect.any(AbortSignal),
          mode: "same-origin",
          credentials: "same-origin",
        }),
      );
      expect(fields.pending).toBe(false);
      expect(fields.wasSuccessful).toBe(true);
      expect(fields.recentlySuccessful).toBe(true);
      expect(reload).toHaveBeenCalledOnce();
      expect(assign).not.toHaveBeenCalled();
      vi.advanceTimersByTime(2000);
      expect(fields.recentlySuccessful).toBe(false);
      expect(fields.wasSuccessful).toBe(true);
    },
  );

  it.each([
    "https://external.invalid/?add",
    "//external.invalid/?add",
    "/\\external.invalid/?add",
    "https://example.com.external.invalid/?add",
    "https://example.com:444/?add",
    "http://example.com/?add",
    "https://user:password@example.com/?add",
    "javascript:void(0)",
    "data:text/plain,review",
    "blob:https://example.com/review",
    "http://[",
  ])("rejects unsafe action URL %s without sending form data", async (url) => {
    const fields = form({ title: "Draft" });
    await expect(fields.post(url)).rejects.toBeInstanceOf(TypeError);
    expect(fetchMock).not.toHaveBeenCalled();
    expect(assign).not.toHaveBeenCalled();
    expect(reload).not.toHaveBeenCalled();
    expect(fields.pending).toBe(false);
    expect(fields.data.title).toBe("Draft");
  });

  it.each([
    ["?add", "https://example.com/notes/42?add"],
    ["./edit?update", "https://example.com/notes/edit?update"],
    ["https://example.com:443/?add", "https://example.com/?add"],
    ["//example.com/?add", "https://example.com/?add"],
  ])("resolves same-origin URL %s against the current page", async (url, resolved) => {
    fetchMock.mockResolvedValueOnce(Response.json({ success: true }));
    const fields = form({ title: "Draft" });
    await fields.post(url);
    expect(fetchMock.mock.calls[0][0]).toBe(resolved);
    expect(reload).toHaveBeenCalledOnce();
  });

  it("does not resolve the request through an external document base URL", async () => {
    document.head.innerHTML = '<base href="https://external.invalid/">';
    try {
      fetchMock.mockResolvedValueOnce(Response.json({ success: true }));
      await form({ title: "Draft" }).post("?add");
      expect(fetchMock.mock.calls[0][0]).toBe("https://example.com/notes/42?add");
    } finally {
      document.head.innerHTML = "";
    }
  });

  it("retains fields and displays 422 errors without navigating", async () => {
    fetchMock.mockResolvedValueOnce(
      Response.json({ errors: { title: "Too long", count: "Invalid" } }, { status: 422 }),
    );
    const fields = form({ title: "Draft", count: 0 });
    await fields.post("/?add");
    expect(fields.data.title).toBe("Draft");
    expect(fields.errors).toEqual({ title: "Too long", count: "Invalid" });
    expect(fields.error).toBeNull();
    expect(fields.pending).toBe(false);
    expect(fields.wasSuccessful).toBe(false);
    expect(reload).not.toHaveBeenCalled();
    fields.clearErrors("title");
    expect(fields.errors).toEqual({ count: "Invalid" });
    fields.clearErrors();
    expect(fields.errors).toEqual({});
  });

  it.each([400, 409, 429])("keeps expected %s errors with the form", async (status) => {
    fetchMock.mockResolvedValueOnce(Response.json({ message: "Try later" }, { status }));
    const fields = form({ title: "Draft" });
    await fields.post("/?add");
    expect(fields.error).toMatchObject({
      name: "VoidActionError",
      status,
      body: { message: "Try later" },
      url: "/?add",
    });
    expect(fields.data.title).toBe("Draft");
    expect(reload).not.toHaveBeenCalled();
    fields.clearError();
    expect(fields.error).toBeNull();
  });

  it("handles a non-JSON validation failure as a form error", async () => {
    fetchMock.mockResolvedValueOnce(new Response("Invalid title", { status: 422 }));
    const fields = form({ title: "Draft" });
    await fields.post("/?add");
    expect(fields.error).toMatchObject({ status: 422, body: "Invalid title" });
    expect(fields.errors).toEqual({});
  });

  it.each([401, 403, 500])("throws %s failures for the caller to handle", async (status) => {
    fetchMock.mockResolvedValueOnce(Response.json({ message: "Failed" }, { status }));
    const fields = form({ title: "Draft" });
    await expect(fields.post("/?add")).rejects.toMatchObject({ name: "VoidActionError", status });
    expect(fields.pending).toBe(false);
    expect(fields.data.title).toBe("Draft");
    expect(reload).not.toHaveBeenCalled();
  });

  it("clears pending after a network failure and allows retry", async () => {
    fetchMock.mockRejectedValueOnce(new TypeError("Offline"));
    const fields = form({ title: "Draft" });
    await expect(fields.post("/?add")).rejects.toThrow("Offline");
    expect(fields.pending).toBe(false);
    fetchMock.mockResolvedValueOnce(
      Response.json({ errors: { title: "Required" } }, { status: 422 }),
    );
    await fields.post("/?add");
    expect(fields.errors.title).toBe("Required");
  });

  it("follows action redirects instead of reloading the old URL", async () => {
    const response = Response.json({});
    Object.defineProperties(response, {
      redirected: { value: true },
      url: { value: "https://example.com/done" },
    });
    fetchMock.mockResolvedValueOnce(response);
    const fields = form({ title: "Draft" });
    await fields.post("/?add");
    expect(assign).toHaveBeenCalledWith("https://example.com/done");
    expect(reload).not.toHaveBeenCalled();
    expect(fields.pending).toBe(false);
  });

  it.each(["https://external.invalid/done", "http://example.com/done", "javascript:void(0)"])(
    "rejects an unsafe redirect response URL %s without navigating",
    async (url) => {
      const response = Response.json({});
      Object.defineProperties(response, { redirected: { value: true }, url: { value: url } });
      fetchMock.mockResolvedValueOnce(response);
      const fields = form({ title: "Draft" });
      await expect(fields.post("/?add")).rejects.toBeInstanceOf(TypeError);
      expect(assign).not.toHaveBeenCalled();
      expect(reload).not.toHaveBeenCalled();
      expect(fields.pending).toBe(false);
      expect(fields.data.title).toBe("Draft");
    },
  );

  it("prevents duplicate writes and retains edits made during submission", async () => {
    const request = deferred<Response>();
    fetchMock.mockReturnValueOnce(request.promise);
    const fields = form({ title: "Initial" });
    fields.setData("title", "Submitted");
    const first = fields.post("/?add");
    expect(fields.pending).toBe(true);
    const duplicate = fields.post("/?add");
    expect(duplicate).toBe(first);
    expect(fetchMock).toHaveBeenCalledOnce();
    fields.setData("title", "Edited during request");
    request.resolve(Response.json({ success: true }));
    await Promise.all([first, duplicate]);
    expect(fields.data.title).toBe("Edited during request");
    expect(fields.hasChanges).toBe(true);
    fields.reset();
    expect(fields.data.title).toBe("Submitted");
    expect(fields.hasChanges).toBe(false);
    expect(reload).toHaveBeenCalledOnce();
  });

  it("clears previous errors and success state at the next submission", async () => {
    fetchMock.mockResolvedValueOnce(Response.json({ success: true }));
    const fields = form({ title: "Draft" });
    await fields.post("/?add");
    const request = deferred<Response>();
    fetchMock.mockReturnValueOnce(request.promise);
    const next = fields.post("/?add");
    expect(fields.wasSuccessful).toBe(false);
    expect(fields.recentlySuccessful).toBe(false);
    request.resolve(Response.json({ errors: { title: "Invalid" } }, { status: 422 }));
    await next;
    fetchMock.mockResolvedValueOnce(Response.json({ success: true }));
    await fields.post("/?add");
    expect(fields.errors).toEqual({});
    expect(fields.error).toBeNull();
  });

  it("aborts a removed island and ignores a late success", async () => {
    const request = deferred<Response>();
    fetchMock.mockReturnValueOnce(request.promise);
    const fields = form({ title: "Draft" });
    const submitted = fields.post("/?add");
    const signal = fetchMock.mock.calls[0][1]!.signal!;
    disposers.pop()!();
    expect(signal.aborted).toBe(true);
    request.resolve(Response.json({ success: true }));
    await submitted;
    expect(reload).not.toHaveBeenCalled();
    expect(fields.wasSuccessful).toBe(false);
    await expect(fields.post("/?add")).rejects.toThrow(/disposed/i);
    expect(fetchMock).toHaveBeenCalledOnce();
  });

  it("clears success timers on disposal", async () => {
    fetchMock.mockResolvedValueOnce(Response.json({ success: true }));
    const fields = form({ title: "Draft" });
    await fields.post("/?add");
    expect(vi.getTimerCount()).toBe(1);
    disposers.pop()!();
    expect(vi.getTimerCount()).toBe(0);
  });

  it("consumes an abort rejection after the island is disposed", async () => {
    fetchMock.mockImplementationOnce(
      (_url, options) =>
        new Promise((_resolve, reject) => {
          options!.signal!.addEventListener("abort", () =>
            reject(new DOMException("Removed", "AbortError")),
          );
        }),
    );
    const fields = form({ title: "Draft" });
    const submitted = fields.post("/?add");
    disposers.pop()!();
    await expect(submitted).resolves.toBeUndefined();
    expect(fields.pending).toBe(false);
    expect(reload).not.toHaveBeenCalled();
  });

  it("renders without browser globals or side effects on the server", () => {
    vi.stubGlobal("window", undefined);
    vi.stubGlobal("location", undefined);
    vi.stubGlobal("document", undefined);
    const markup = renderToString(() => {
      const fields = useIslandForm({ title: "Server" });
      return jsx("button", { disabled: () => fields.pending, children: () => fields.data.title });
    });
    expect(markup).toContain("Server");
    expect(fetchMock).not.toHaveBeenCalled();
    expect(vi.getTimerCount()).toBe(0);
  });

  it("hydrates a form and updates pending, validation, and input values reactively", async () => {
    const component = () => {
      const fields = useIslandForm({ title: "" });
      return jsx("form", {
        onSubmit: (event: Event) => {
          event.preventDefault();
          void fields.post("/?add");
        },
        children: [
          jsx("input", {
            value: () => fields.data.title,
            onInput: (event: Event) =>
              fields.setData("title", (event.target as HTMLInputElement).value),
          }),
          jsx("span", { children: () => fields.errors.title ?? "" }),
          jsx("button", { disabled: () => fields.pending, children: "Save" }),
        ],
      });
    };
    document.body.innerHTML = renderToString(component);
    const input = document.querySelector("input")!;
    const button = document.querySelector("button")!;
    disposers.push(hydrate(document.body, component));
    expect(document.querySelector("input")).toBe(input);
    input.value = "Keep my draft";
    input.dispatchEvent(new Event("input", { bubbles: true }));
    const request = deferred<Response>();
    fetchMock.mockReturnValueOnce(request.promise);
    document
      .querySelector("form")!
      .dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
    expect(button.disabled).toBe(true);
    request.resolve(Response.json({ errors: { title: "Invalid title" } }, { status: 422 }));
    await vi.waitFor(() => expect(button.disabled).toBe(false));
    expect(document.querySelector("span")!.textContent).toBe("Invalid title");
    expect(input.value).toBe("Keep my draft");
    expect(JSON.parse(fetchMock.mock.calls[0][1]!.body as string)).toEqual({
      title: "Keep my draft",
    });
  });
});
