// @ts-nocheck
// Router-focused lightweight entrypoint implemented in TypeScript

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

function normalizePath(input: string): string {
  if (!input) return "/";
  const qIndex = input.indexOf("?");
  const hashIndex = input.indexOf("#");
  const end =
    qIndex >= 0 && hashIndex >= 0
      ? Math.min(qIndex, hashIndex)
      : qIndex >= 0
        ? qIndex
        : hashIndex;
  const rawPath = end >= 0 ? input.slice(0, end) : input;
  const withLeading = rawPath.startsWith("/") ? rawPath : `/${rawPath}`;
  if (withLeading.length > 1 && withLeading.endsWith("/")) {
    return withLeading.slice(0, -1);
  }
  return withLeading;
}

function splitPathAndSearch(input: string): { pathname: string; search: string } {
  const hashIndex = input.indexOf("#");
  const source = hashIndex >= 0 ? input.slice(0, hashIndex) : input;
  const qIndex = source.indexOf("?");
  if (qIndex < 0) {
    return { pathname: normalizePath(source), search: "" };
  }
  return {
    pathname: normalizePath(source.slice(0, qIndex)),
    search: source.slice(qIndex),
  };
}

function normalizeBase(base: string): string {
  if (!base || base === "/") return "";
  return normalizePath(base);
}

function resolveBaseArg(baseOrOptions?: string | { base?: string }): string {
  if (typeof baseOrOptions === "string") return baseOrOptions;
  if (baseOrOptions && typeof baseOrOptions.base === "string") return baseOrOptions.base;
  return "";
}

function withBase(base: string, path: string): string {
  if (!base) return path;
  return path === "/" ? base : `${base}${path}`;
}

function withoutBase(base: string, path: string): string {
  if (!base) return path;
  if (path === base) return "/";
  if (path.startsWith(`${base}/`)) {
    return path.slice(base.length) || "/";
  }
  return path;
}

function splitSegments(path: string): string[] {
  if (path === "/") return [];
  return path.split("/").filter(Boolean);
}

function decodeSegment(segment: string): string {
  try {
    return decodeURIComponent(segment);
  } catch {
    return segment;
  }
}

function parseQuery(search: string): KvTuple[] {
  if (!search || search === "?") return [];
  const src = search.startsWith("?") ? search.slice(1) : search;
  const params = new URLSearchParams(src);
  const out: KvTuple[] = [];
  for (const [key, value] of params.entries()) {
    if (key) {
      out.push({ _0: key, _1: value });
    }
  }
  return out;
}

function extractDynamicName(patternSegment: string): string | null {
  if (patternSegment.startsWith(":")) {
    return patternSegment.slice(1);
  }
  if (
    patternSegment.startsWith("[") &&
    patternSegment.endsWith("]") &&
    !patternSegment.startsWith("[...") &&
    !patternSegment.startsWith("[[...")
  ) {
    return patternSegment.slice(1, -1);
  }
  return null;
}

function extractCatchAll(patternSegment: string): { name: string; optional: boolean } | null {
  if (patternSegment.startsWith("[[...") && patternSegment.endsWith("]]")) {
    return {
      name: patternSegment.slice(5, -2),
      optional: true,
    };
  }
  if (patternSegment.startsWith("[...") && patternSegment.endsWith("]")) {
    return {
      name: patternSegment.slice(4, -1),
      optional: false,
    };
  }
  return null;
}

function matchRoute(patternPath: string, currentPath: string): KvTuple[] | null {
  const pattern = splitSegments(normalizePath(patternPath));
  const current = splitSegments(normalizePath(currentPath));
  const params: KvTuple[] = [];

  let i = 0;
  let j = 0;

  while (i < pattern.length) {
    const part = pattern[i];
    const catchAll = extractCatchAll(part);
    if (catchAll) {
      const rest = current.slice(j).map(decodeSegment).join("/");
      if (!rest && !catchAll.optional) {
        return null;
      }
      params.push({ _0: catchAll.name, _1: rest });
      return params;
    }

    if (j >= current.length) {
      return null;
    }

    const dyn = extractDynamicName(part);
    if (dyn) {
      params.push({ _0: dyn, _1: decodeSegment(current[j]) });
      i += 1;
      j += 1;
      continue;
    }

    if (part !== current[j]) {
      return null;
    }

    i += 1;
    j += 1;
  }

  if (j !== current.length) {
    return null;
  }

  return params;
}

function findMatch(routes: LiteRoute[], pathname: string, search: string): LiteRouteMatch | undefined {
  for (let i = 0; i < routes.length; i += 1) {
    const route = routes[i];
    const params = matchRoute(route.path, pathname);
    if (params) {
      return {
        route,
        params,
        query: parseQuery(search),
        path: pathname,
      };
    }
  }
  return undefined;
}

function readLocation(): { pathname: string; search: string } {
  if (typeof window === "undefined") {
    return { pathname: "/", search: "" };
  }
  return {
    pathname: normalizePath(window.location.pathname),
    search: window.location.search || "",
  };
}

function syncRouter(router: BrowserRouterLite, pathname: string, search: string): void {
  const normalizedPath = normalizePath(pathname);
  const pathWithoutBase = withoutBase(router.base, normalizedPath);
  router.currentPath = `${pathWithoutBase}${search}`;
  router.currentMatch = findMatch(router.routes, pathWithoutBase, search);
}

export function routePage(path: string, component: unknown): LiteRoute {
  return {
    $tag: 0,
    path: normalizePath(path),
    component,
    title: "",
    meta: [],
  };
}

export function routePageTitled(path: string, component: unknown, title: string): LiteRoute {
  return {
    $tag: 0,
    path: normalizePath(path),
    component,
    title,
    meta: [],
  };
}

export function routePageFull(
  path: string,
  component: unknown,
  title: string,
  meta: KvTuple[],
): LiteRoute {
  return {
    $tag: 0,
    path: normalizePath(path),
    component,
    title,
    meta: meta || [],
  };
}

export function createRouter(
  routes: LiteRoute[],
  baseOrOptions?: string | { base?: string },
): BrowserRouterLite {
  const base = normalizeBase(resolveBaseArg(baseOrOptions));
  const router: BrowserRouterLite = {
    routes,
    base,
    currentPath: "/",
    currentMatch: undefined,
    dispose: () => {},
  };

  const initial = readLocation();
  syncRouter(router, initial.pathname, initial.search);

  if (typeof window !== "undefined") {
    const onPopState = () => {
      const next = readLocation();
      syncRouter(router, next.pathname, next.search);
    };
    window.addEventListener("popstate", onPopState);
    router.dispose = () => {
      window.removeEventListener("popstate", onPopState);
    };
  }

  return router;
}

export function routerNavigate(router: BrowserRouterLite, path: string): void {
  const target = splitPathAndSearch(path);
  const fullPath = `${withBase(router.base, target.pathname)}${target.search}`;
  if (typeof window !== "undefined") {
    window.history.pushState(null, "", fullPath);
  }
  syncRouter(router, target.pathname, target.search);
}

export function routerReplace(router: BrowserRouterLite, path: string): void {
  const target = splitPathAndSearch(path);
  const fullPath = `${withBase(router.base, target.pathname)}${target.search}`;
  if (typeof window !== "undefined") {
    window.history.replaceState(null, "", fullPath);
  }
  syncRouter(router, target.pathname, target.search);
}

export function routerGetPath(router: BrowserRouterLite): string {
  return router.currentPath;
}

export function routerGetMatch(router: BrowserRouterLite): LiteRouteMatch | undefined {
  return router.currentMatch;
}

export function routerGetBase(router: BrowserRouterLite): string {
  return router.base;
}
