import { beforeEach, describe, expect, test } from "vitest";

import {
  createResource,
  createDeferred,
  resourceGet,
  stateValue,
  resourceIsPending,
  resourceIsSuccess,
} from "../js/luna/src/resource";
import {
  routePage,
  createRouter,
  routerNavigate,
  routerGetPath,
  routerGetBase,
  routerGetMatch,
} from "../js/luna/src/router-lite";
import {
  createSignal as createSharedSignal,
} from "../js/luna/src/signals-shared";
import {
  createSignal as createRawSignal,
  get as rawGet,
  set as rawSet,
} from "../js/luna/src/raw";

describe("luna lite/raw entrypoints", () => {
  beforeEach(() => {
    window.history.replaceState(null, "", "/");
  });

  test("resource entrypoint exposes raw resource state helpers", () => {
    const resource = createResource<number>((resolve) => {
      resolve(42);
    });

    expect(resourceIsSuccess(resource)).toBe(true);
    expect(stateValue(resourceGet(resource))).toBe(42);
  });

  test("resource deferred works without index wrapper", () => {
    const [resource, resolve] = createDeferred<number>();

    expect(resourceIsPending(resource)).toBe(true);
    resolve(7);
    expect(stateValue(resourceGet(resource))).toBe(7);
  });

  test("router-lite entrypoint works", () => {
    const router = createRouter([
      routePage("/", "home"),
      routePage("/about", "about"),
    ]);

    routerNavigate(router, "/about");
    expect(routerGetPath(router)).toBe("/about");
  });

  test("router-lite supports base option object", () => {
    const router = createRouter(
      [routePage("/", "home"), routePage("/about", "about")],
      { base: "/app" },
    );

    routerNavigate(router, "/about");
    expect(routerGetBase(router)).toBe("/app");
    expect(routerGetPath(router)).toBe("/about");
  });

  test("router-lite supports dynamic params and query", () => {
    const router = createRouter([routePage("/users/:id", "user")]);

    routerNavigate(router, "/users/42?tab=profile");
    const match = routerGetMatch(router);
    expect(match?.route.component).toBe("user");
    expect(match?.path).toBe("/users/42");
    expect(match?.params).toEqual([{ _0: "id", _1: "42" }]);
    expect(match?.query).toEqual([{ _0: "tab", _1: "profile" }]);
  });

  test("signals-shared exports solid-style signal wrapper", () => {
    const [count, setCount] = createSharedSignal(0);
    setCount(1);
    expect(count()).toBe(1);
  });

  test("raw entrypoint exposes low-level signal api", () => {
    const signal = createRawSignal(1);
    rawSet(signal, 2);
    expect(rawGet(signal)).toBe(2);
  });
});
