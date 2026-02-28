// @ts-nocheck
// Router-focused entrypoint bound from MoonBit api_router_lite

type KvTuple = { _0: string; _1: string };

export interface LiteRoute {
  $tag: 0;
  path: string;
  component: unknown;
  title: string;
  meta: KvTuple[];
}

export interface LiteRouteMatch {
  route: LiteRoute;
  params: KvTuple[];
  query: KvTuple[];
  path: string;
}

export interface BrowserRouterLite {
  routes: LiteRoute[];
  base: string;
  currentPath: string;
  currentMatch: LiteRouteMatch | undefined;
  dispose: () => void;
}

import {
  routePage as _routePage,
  routePageTitled as _routePageTitled,
  routePageFull as _routePageFull,
  createRouter as _createRouter,
  routerNavigate as _routerNavigate,
  routerReplace as _routerReplace,
  routerGetPath as _routerGetPath,
  routerGetMatch as _routerGetMatch,
  routerGetBase as _routerGetBase,
} from "../../../_build/js/release/build/js/api_router_lite/api_router_lite.js";

function resolveBaseArg(baseOrOptions?: string | { base?: string }): string {
  if (typeof baseOrOptions === "string") return baseOrOptions;
  if (baseOrOptions && typeof baseOrOptions.base === "string") return baseOrOptions.base;
  return "";
}

export function routePage(path: string, component: unknown): LiteRoute {
  return _routePage(path, component);
}

export function routePageTitled(path: string, component: unknown, title: string): LiteRoute {
  return _routePageTitled(path, component, title);
}

export function routePageFull(
  path: string,
  component: unknown,
  title: string,
  meta: KvTuple[],
): LiteRoute {
  return _routePageFull(path, component, title, meta);
}

export function createRouter(
  routes: LiteRoute[],
  baseOrOptions?: string | { base?: string },
): BrowserRouterLite {
  return _createRouter(routes, resolveBaseArg(baseOrOptions));
}

export function routerNavigate(router: BrowserRouterLite, path: string): void {
  _routerNavigate(router, path);
}

export function routerReplace(router: BrowserRouterLite, path: string): void {
  _routerReplace(router, path);
}

export function routerGetPath(router: BrowserRouterLite): string {
  return _routerGetPath(router);
}

export function routerGetMatch(router: BrowserRouterLite): LiteRouteMatch | undefined {
  return _routerGetMatch(router);
}

export function routerGetBase(router: BrowserRouterLite): string {
  return _routerGetBase(router);
}
