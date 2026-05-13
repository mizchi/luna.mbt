import { beforeAll, beforeEach, describe, expect, test, vi } from "vitest";

describe("sol-nav security", () => {
  const fetchMock = vi.fn();

  beforeAll(async () => {
    vi.stubGlobal("fetch", fetchMock);
    await import("./src/sol-nav.ts");
  });

  beforeEach(() => {
    fetchMock.mockReset();
    fetchMock.mockResolvedValue(
      new Response(
        "<html><head><title>ok</title></head><body><div id=\"app\">ok</div></body></html>",
        {
          status: 200,
          headers: {
            "X-Sol-Fragment-Response": "true",
          },
        }
      )
    );
    document.body.innerHTML = `<div id="app"></div>`;
    history.replaceState({}, "", "/");
  });

  test("internal link is intercepted", async () => {
    document.body.innerHTML = `<div id="app"></div><a id="link" data-sol-link href="/next">Next</a>`;
    const link = document.getElementById("link") as HTMLAnchorElement;
    const event = new MouseEvent("click", { bubbles: true, cancelable: true });

    const notCanceled = link.dispatchEvent(event);

    expect(notCanceled).toBe(false);
    expect(fetchMock).toHaveBeenCalledWith("/next", { headers: { "X-Sol-Fragment": "true" } });
  });

  test("javascript: link is not intercepted", () => {
    document.body.innerHTML =
      `<div id="app"></div><a id="link" data-sol-link href="javascript:alert(1)">X</a>`;
    const link = document.getElementById("link") as HTMLAnchorElement;
    const event = new MouseEvent("click", { bubbles: true, cancelable: true });

    const notCanceled = link.dispatchEvent(event);

    expect(notCanceled).toBe(true);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  test("data: link is not intercepted", () => {
    document.body.innerHTML =
      `<div id="app"></div><a id="link" data-sol-link href="data:text/html,<h1>x</h1>">X</a>`;
    const link = document.getElementById("link") as HTMLAnchorElement;
    const event = new MouseEvent("click", { bubbles: true, cancelable: true });

    const notCanceled = link.dispatchEvent(event);

    expect(notCanceled).toBe(true);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  test("fragment head assets are appended once", async () => {
    fetchMock.mockResolvedValue(
      new Response(
        `<template data-sol-outlet="main"><p>Assets</p></template><template data-sol-title>Assets</template><template data-sol-head-assets><link rel="stylesheet" href="/static/panel.css"><script type="module" src="/static/panel.client.ts"></script></template>`,
        {
          status: 200,
          headers: {
            "X-Sol-Fragment-Response": "true",
          },
        }
      )
    );
    document.head.innerHTML = "";
    document.body.innerHTML = `<main data-sol-outlet="main"></main>`;

    const nav = (window as unknown as {
      __SOL_NAVIGATE__: (url: string, replace?: boolean) => Promise<void>;
    }).__SOL_NAVIGATE__;
    await nav("/assets");
    await nav("/assets");

    expect(document.querySelectorAll('link[href="/static/panel.css"]')).toHaveLength(
      1
    );
    expect(
      document.querySelectorAll('script[src="/static/panel.client.ts"]')
    ).toHaveLength(1);
    expect(document.querySelector('[data-sol-outlet="main"]')?.innerHTML).toBe(
      "<p>Assets</p>"
    );
  });
});
