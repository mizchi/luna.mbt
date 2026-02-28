import { beforeEach, describe, expect, test, vi } from "vitest";

describe("loader scan dedupe", () => {
  beforeEach(() => {
    vi.resetModules();
    document.body.innerHTML = "";
    (window as any).__LUNA_STATE__ = undefined;
    (window as any).__LUNA_HYDRATE__ = undefined;
    (window as any).__LUNA_SCAN__ = undefined;
  });

  test("scan does not register trigger multiple times for same element", async () => {
    let observeCount = 0;
    const originalIO = window.IntersectionObserver;
    const originalQSA = document.querySelectorAll.bind(document);

    window.IntersectionObserver = class MockIntersectionObserver {
      observe() {
        observeCount += 1;
      }
      disconnect() {}
      takeRecords() {
        return [];
      }
      unobserve() {}
      root = null;
      rootMargin = "0px";
      thresholds = [];
    } as unknown as typeof IntersectionObserver;

    document.body.innerHTML =
      `<div luna:id="counter" luna:url="./counter.js" luna:client-trigger="visible">Counter</div>`;
    const island = document.querySelector("div") as HTMLElement;
    island.setAttribute("luna:url", "./counter.js");
    island.setAttribute("luna:client-trigger", "visible");

    vi.spyOn(document, "querySelectorAll").mockImplementation((selector: string) => {
      if (selector === "[luna\\:url]") {
        return [island] as unknown as NodeListOf<Element>;
      }
      return originalQSA(selector);
    });

    await import("./src/loader.ts");
    (window as any).__LUNA_SCAN__?.();
    (window as any).__LUNA_SCAN__?.();

    expect(observeCount).toBe(1);

    window.IntersectionObserver = originalIO;
  });
});
