// JS Router Lite API - minimal runtime with JS extern implementations

///|
/// Opaque type for JS interop
#external
pub type Any

///|
extern "js" fn _route_page(path : String, component : Any) -> Any =
  #| (path, component) => ({ $tag: 0, path, component, title: "", meta: [] })

///|
extern "js" fn _route_page_titled(
  path : String,
  component : Any,
  title : String,
) -> Any =
  #| (path, component, title) => ({ $tag: 0, path, component, title, meta: [] })

///|
extern "js" fn _route_page_full(
  path : String,
  component : Any,
  title : String,
  meta : Array[(String, String)],
) -> Any =
  #| (path, component, title, meta) => ({ $tag: 0, path, component, title, meta: meta || [] })

///|
extern "js" fn _create_router(routes : Array[Any], base : String) -> Any =
  #| (routes, base) => {
  #|   const normalizePath = (input) => {
  #|     if (!input) return "/";
  #|     const q = input.indexOf("?");
  #|     const h = input.indexOf("#");
  #|     const e = q >= 0 && h >= 0 ? Math.min(q, h) : q >= 0 ? q : h;
  #|     const raw = e >= 0 ? input.slice(0, e) : input;
  #|     const withLeading = raw.startsWith("/") ? raw : `/${raw}`;
  #|     return withLeading.length > 1 && withLeading.endsWith("/")
  #|       ? withLeading.slice(0, -1)
  #|       : withLeading;
  #|   };
  #|   const normalizeBase = (v) => {
  #|     if (!v || v === "/") return "";
  #|     if (typeof v === "string") return normalizePath(v);
  #|     if (typeof v.base === "string") return normalizePath(v.base);
  #|     return "";
  #|   };
  #|   const splitSegments = (path) => (path === "/" ? [] : path.split("/").filter(Boolean));
  #|   const decodeSegment = (s) => {
  #|     try {
  #|       return decodeURIComponent(s);
  #|     } catch {
  #|       return s;
  #|     }
  #|   };
  #|   const parseQuery = (search) => {
  #|     if (!search || search === "?") return [];
  #|     const src = search.startsWith("?") ? search.slice(1) : search;
  #|     const params = new URLSearchParams(src);
  #|     const out = [];
  #|     for (const [k, v] of params.entries()) {
  #|       if (k) out.push({ _0: k, _1: v });
  #|     }
  #|     return out;
  #|   };
  #|   const dynamicName = (part) => {
  #|     if (part.startsWith(":")) return part.slice(1);
  #|     if (part.startsWith("[") && part.endsWith("]") && !part.startsWith("[...") && !part.startsWith("[[...")) {
  #|       return part.slice(1, -1);
  #|     }
  #|     return null;
  #|   };
  #|   const catchAll = (part) => {
  #|     if (part.startsWith("[[...") && part.endsWith("]]")) {
  #|       return { name: part.slice(5, -2), optional: true };
  #|     }
  #|     if (part.startsWith("[...") && part.endsWith("]")) {
  #|       return { name: part.slice(4, -1), optional: false };
  #|     }
  #|     return null;
  #|   };
  #|   const matchRoute = (patternPath, currentPath) => {
  #|     const pattern = splitSegments(normalizePath(patternPath));
  #|     const current = splitSegments(normalizePath(currentPath));
  #|     const params = [];
  #|     let i = 0;
  #|     let j = 0;
  #|     while (i < pattern.length) {
  #|       const part = pattern[i];
  #|       const c = catchAll(part);
  #|       if (c) {
  #|         const rest = current.slice(j).map(decodeSegment).join("/");
  #|         if (!rest && !c.optional) return null;
  #|         params.push({ _0: c.name, _1: rest });
  #|         return params;
  #|       }
  #|       if (j >= current.length) return null;
  #|       const dn = dynamicName(part);
  #|       if (dn) {
  #|         params.push({ _0: dn, _1: decodeSegment(current[j]) });
  #|         i += 1;
  #|         j += 1;
  #|         continue;
  #|       }
  #|       if (part !== current[j]) return null;
  #|       i += 1;
  #|       j += 1;
  #|     }
  #|     return j === current.length ? params : null;
  #|   };
  #|   const findMatch = (pathname, search) => {
  #|     for (let i = 0; i < routes.length; i += 1) {
  #|       const route = routes[i];
  #|       const params = matchRoute(route.path, pathname);
  #|       if (params) {
  #|         return { route, params, query: parseQuery(search), path: pathname };
  #|       }
  #|     }
  #|     return undefined;
  #|   };
  #|   const withBase = (b, path) => (!b ? path : path === "/" ? b : `${b}${path}`);
  #|   const withoutBase = (b, path) => {
  #|     if (!b) return path;
  #|     if (path === b) return "/";
  #|     if (path.startsWith(`${b}/`)) return path.slice(b.length) || "/";
  #|     return path;
  #|   };
  #|   const splitPathAndSearch = (input) => {
  #|     const h = input.indexOf("#");
  #|     const source = h >= 0 ? input.slice(0, h) : input;
  #|     const q = source.indexOf("?");
  #|     if (q < 0) return { pathname: normalizePath(source), search: "" };
  #|     return { pathname: normalizePath(source.slice(0, q)), search: source.slice(q) };
  #|   };
  #|   const readLocation = () => {
  #|     if (typeof window === "undefined") return { pathname: "/", search: "" };
  #|     return { pathname: normalizePath(window.location.pathname), search: window.location.search || "" };
  #|   };
  #|   const router = {
  #|     routes,
  #|     base: normalizeBase(base),
  #|     currentPath: "/",
  #|     currentMatch: undefined,
  #|     dispose: () => {},
  #|   };
  #|   const sync = (pathname, search) => {
  #|     const normalizedPath = normalizePath(pathname);
  #|     const pathWithoutBase = withoutBase(router.base, normalizedPath);
  #|     router.currentPath = `${pathWithoutBase}${search}`;
  #|     router.currentMatch = findMatch(pathWithoutBase, search);
  #|   };
  #|   router.navigate = (path) => {
  #|     const target = splitPathAndSearch(path);
  #|     const fullPath = `${withBase(router.base, target.pathname)}${target.search}`;
  #|     if (typeof window !== "undefined") window.history.pushState(null, "", fullPath);
  #|     sync(target.pathname, target.search);
  #|   };
  #|   router.replace = (path) => {
  #|     const target = splitPathAndSearch(path);
  #|     const fullPath = `${withBase(router.base, target.pathname)}${target.search}`;
  #|     if (typeof window !== "undefined") window.history.replaceState(null, "", fullPath);
  #|     sync(target.pathname, target.search);
  #|   };
  #|   const initial = readLocation();
  #|   sync(initial.pathname, initial.search);
  #|   if (typeof window !== "undefined") {
  #|     const onPopState = () => {
  #|       const next = readLocation();
  #|       sync(next.pathname, next.search);
  #|     };
  #|     window.addEventListener("popstate", onPopState);
  #|     router.dispose = () => {
  #|       window.removeEventListener("popstate", onPopState);
  #|     };
  #|   }
  #|   return router;
  #| }

///|
extern "js" fn _router_navigate(router : Any, path : String) -> Unit =
  #| (router, path) => { router.navigate(path); }

///|
extern "js" fn _router_replace(router : Any, path : String) -> Unit =
  #| (router, path) => { router.replace(path); }

///|
extern "js" fn _router_get_path(router : Any) -> String =
  #| (router) => router.currentPath

///|
extern "js" fn _router_get_match(router : Any) -> Any =
  #| (router) => router.currentMatch

///|
extern "js" fn _router_get_base(router : Any) -> String =
  #| (router) => router.base

///|
/// Create a page route
pub fn route_page(path : String, component : Any) -> Any {
  _route_page(path, component)
}

///|
/// Create a page route with title
pub fn route_page_titled(path : String, component : Any, title : String) -> Any {
  _route_page_titled(path, component, title)
}

///|
/// Create a page route with full options
pub fn route_page_full(
  path : String,
  component : Any,
  title : String,
  meta : Array[(String, String)],
) -> Any {
  _route_page_full(path, component, title, meta)
}

///|
/// Create a BrowserRouter from routes definition
pub fn create_router(routes : Array[Any], base : String) -> Any {
  _create_router(routes, base)
}

///|
/// Navigate to a path
pub fn router_navigate(router : Any, path : String) -> Unit {
  _router_navigate(router, path)
}

///|
/// Replace current path
pub fn router_replace(router : Any, path : String) -> Unit {
  _router_replace(router, path)
}

///|
/// Get current path
pub fn router_get_path(router : Any) -> String {
  _router_get_path(router)
}

///|
/// Get current match result
pub fn router_get_match(router : Any) -> Any {
  _router_get_match(router)
}

///|
/// Get base path
pub fn router_get_base(router : Any) -> String {
  _router_get_base(router)
}
