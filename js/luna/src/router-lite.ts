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
  routePage,
  routePageTitled,
  routePageFull,
  createRouter as _createRouter,
  routerNavigate,
  routerReplace,
  routerGetPath,
  routerGetMatch,
  routerGetBase,
} from "../../../_build/js/release/build/js/api_router_lite/api_router_lite.js";

export {
  routePage,
  routePageTitled,
  routePageFull,
  routerNavigate,
  routerReplace,
  routerGetPath,
  routerGetMatch,
  routerGetBase,
};

export const createRouter = _createRouter as (
  routes: LiteRoute[],
  baseOrOptions?: string | { base?: string },
  ) => BrowserRouterLite;
