export interface NavigateEvent {
  path: string;
  params: Record<string, string>;
  segment?: string;
  isSpa?: boolean;
  isPopState: boolean;
}

export type NavigateHandler = (event: NavigateEvent) => void | Promise<void>;

export interface NavigationRouter {
  onNavigate(handler: NavigateHandler): () => void;
  navigate(path: string, options?: { replace?: boolean }): Promise<void>;
}

export const NAV_ROUTER_KEY = "__LUNA_NAV_ROUTER__";

type NavWindow = Window & {
  [NAV_ROUTER_KEY]?: NavigationRouter;
};

export function getNavigationRouter(): NavigationRouter {
  if (typeof window === "undefined") {
    throw new Error("Navigation router is unavailable outside browser");
  }

  const router = (window as NavWindow)[NAV_ROUTER_KEY];
  if (!router) {
    throw new Error(
      "Navigation router is not initialized. Call startRouter() or import '@luna_ui/luna-loader/router/navigation-fallback'."
    );
  }
  return router;
}

export function setNavigationRouter(router: NavigationRouter): void {
  if (typeof window !== "undefined") {
    (window as NavWindow)[NAV_ROUTER_KEY] = router;
  }
}

declare global {
  interface Window {
    __LUNA_NAV_ROUTER__?: NavigationRouter;
  }
}
