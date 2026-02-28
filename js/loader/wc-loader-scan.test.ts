import { beforeEach, describe, expect, test, vi } from "vitest";

describe("wc-loader scan dedupe", () => {
  beforeEach(() => {
    vi.resetModules();
    document.body.innerHTML = "";
    (window as any).__LUNA_WC_STATE__ = undefined;
    (window as any).__LUNA_WC_HYDRATE__ = undefined;
    (window as any).__LUNA_WC_SCAN__ = undefined;
  });

  test("scan does not register WC trigger multiple times for same element", async () => {
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
      `<wc-counter luna:wc-url="./wc-counter.js" luna:wc-trigger="visible"></wc-counter>`;
    const island = document.querySelector("wc-counter") as HTMLElement;
    island.setAttribute("luna:wc-url", "./wc-counter.js");
    island.setAttribute("luna:wc-trigger", "visible");

    vi.spyOn(document, "querySelectorAll").mockImplementation((selector: string) => {
      if (selector === "[luna\\:wc-url]") {
        return [island] as unknown as NodeListOf<Element>;
      }
      return originalQSA(selector);
    });

    await import("./src/wc-loader.ts");
    (window as any).__LUNA_WC_SCAN__?.();
    (window as any).__LUNA_WC_SCAN__?.();

    expect(observeCount).toBe(1);

    window.IntersectionObserver = originalIO;
  });
});
