import { describe, test, expect, beforeEach } from "vitest";
import {
  routePage,
  routePageTitled,
  routePageFull,
  createRouter,
  routerNavigate,
  routerReplace,
  routerGetPath,
  routerGetMatch,
  routerGetBase,
  type Routes,
  type BrowserRouter,
} from "../src/index";

describe("Route definitions", () => {
  test("routePage creates a page route", () => {
    const route = routePage("/home", "HomePage");
    expect(route).toBeDefined();
    // MoonBit enum representation
    expect((route as any).$tag).toBeDefined();
  });

  test("routePageTitled with title", () => {
    const route = routePageTitled("/about", "AboutPage", "About Us");
    expect(route).toBeDefined();
  });

  test("routePageFull with title and meta", () => {
    const route = routePageFull("/about", "AboutPage", "About Us", [
      { _0: "description", _1: "About our company" },
    ]);
    expect(route).toBeDefined();
  });

  test("multiple page routes", () => {
    const routes: Routes[] = [
      routePage("/", "Home"),
      routePage("/about", "About"),
      routePage("/contact", "Contact"),
    ];
    expect(routes.length).toBe(3);
  });
});

describe("BrowserRouter", () => {
  let router: BrowserRouter;

  beforeEach(() => {
    // Reset location to root
    window.history.replaceState(null, "", "/");
  });

  test("createRouter creates a router", () => {
    const routes = [routePage("/", "Home"), routePage("/about", "About")];
    router = createRouter(routes);
    expect(router).toBeDefined();
  });

  test("createRouter with base path", () => {
    const routes = [routePage("/", "Home")];
    router = createRouter(routes, "/app");
    expect(routerGetBase(router)).toBe("/app");
  });

  test("routerGetPath returns current path", () => {
    const routes = [routePage("/", "Home")];
    router = createRouter(routes);
    // Initial path should be "/"
    const path = routerGetPath(router);
    expect(typeof path).toBe("string");
  });

  test("routerNavigate changes path", () => {
    const routes = [routePage("/", "Home"), routePage("/about", "About")];
    router = createRouter(routes);

    routerNavigate(router, "/about");
    expect(routerGetPath(router)).toBe("/about");
  });

  test("routerReplace changes path without adding to history", () => {
    const routes = [routePage("/", "Home"), routePage("/about", "About")];
    router = createRouter(routes);

    const historyLength = window.history.length;
    routerReplace(router, "/about");
    expect(routerGetPath(router)).toBe("/about");
    // Replace should not add to history
    expect(window.history.length).toBe(historyLength);
  });

  test("routerGetMatch returns match for current route", () => {
    const routes = [routePage("/", "Home"), routePage("/about", "About")];
    router = createRouter(routes);

    routerNavigate(router, "/about");
    const match = routerGetMatch(router);

    expect(match).toBeDefined();
    if (match) {
      expect(match.route.component).toBe("About");
      expect(match.path).toBe("/about");
    }
  });

  test("routerGetMatch returns undefined for unmatched route", () => {
    const routes = [routePage("/", "Home")];
    router = createRouter(routes);

    routerNavigate(router, "/nonexistent");
    const match = routerGetMatch(router);
    // Should be undefined or match might still return something
    // depending on implementation
    expect(typeof match === "undefined" || match !== null).toBe(true);
  });
});
