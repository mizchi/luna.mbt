import {
  getNavigationRouter,
  setNavigationRouter,
  type NavigateEvent,
  type NavigateHandler,
  type NavigationRouter,
} from "./navigation";

function isInternalLink(href: string): boolean {
  if (
    href.startsWith("http://") ||
    href.startsWith("https://") ||
    href.startsWith("//")
  ) {
    try {
      const url = new URL(href, window.location.origin);
      return url.origin === window.location.origin;
    } catch {
      return false;
    }
  }
  return href.startsWith("/") || !href.includes(":");
}

export function createFallbackNavigationRouter(): NavigationRouter {
  const handlers = new Set<NavigateHandler>();
  let started = false;

  const notify = async (event: NavigateEvent): Promise<void> => {
    const list = Array.from(handlers);
    for (let i = 0; i < list.length; i += 1) {
      await list[i](event);
    }
  };

  const navigate = async (
    path: string,
    options: { replace?: boolean } = {}
  ): Promise<void> => {
    if (options.replace) {
      history.replaceState({ luna: true }, "", path);
    } else {
      history.pushState({ luna: true }, "", path);
    }
    await notify({
      path,
      params: {},
      isPopState: false,
    });
  };

  const handleClick = (e: MouseEvent): void => {
    const target = e.target as Element | null;
    const link = target?.closest<HTMLAnchorElement>("a[href]");
    if (!link) return;

    const href = link.getAttribute("href");
    if (!href || href.startsWith("#")) return;
    if (!isInternalLink(href)) return;
    if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
    if (link.getAttribute("target")) return;

    e.preventDefault();
    void navigate(href, { replace: link.hasAttribute("data-replace") });
  };

  const handlePopState = (): void => {
    void notify({
      path: window.location.pathname,
      params: {},
      isPopState: true,
    });
  };

  const start = (): void => {
    if (started) return;
    started = true;
    document.addEventListener("click", handleClick);
    window.addEventListener("popstate", handlePopState);
  };

  start();

  return {
    onNavigate(handler: NavigateHandler): () => void {
      handlers.add(handler);
      return () => handlers.delete(handler);
    },
    navigate,
  };
}

export function installFallbackNavigationRouter(): NavigationRouter {
  try {
    return getNavigationRouter();
  } catch {
    const router = createFallbackNavigationRouter();
    setNavigationRouter(router);
    return router;
  }
}
