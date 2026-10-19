/** Renderer-free contracts, bundled into each npm package (no runtime dependency). */
export type Dispose = () => void;
export type MountResult = void | Dispose | Promise<void | Dispose>;

export interface Island<P extends object = Record<string, unknown>> {
  mount(element: Element, props: P): MountResult;
}

/** Own mounts per DOM instance, including imports and asynchronous renderers. */
export function createIslandLifecycle(onUnmount?: (element: Element) => void) {
  const records = new Map<Element, { dispose?: Dispose }>();
  let stopped = false;

  function unmount(element: Element): boolean {
    const record = records.get(element);
    if (!record) return false;
    records.delete(element);
    onUnmount?.(element);
    record.dispose?.();
    return true;
  }

  function unmountAll(root?: Element) {
    for (const element of records.keys()) {
      if (!root || root.contains(element)) unmount(element);
    }
  }

  const observer = new MutationObserver(() => {
    for (const element of records.keys()) {
      if (!element.isConnected) unmount(element);
    }
  });
  observer.observe(document.documentElement, { childList: true, subtree: true });

  return {
    async mount(
      element: Element,
      mount: (isCurrent: () => boolean) => MountResult,
    ): Promise<boolean> {
      if (stopped || !element.isConnected || records.has(element)) return false;
      const record: { dispose?: Dispose } = {};
      records.set(element, record);
      const isCurrent = () => !stopped && element.isConnected && records.get(element) === record;
      try {
        const dispose = await mount(isCurrent);
        if (!isCurrent()) {
          if (records.get(element) === record) unmount(element);
          if (typeof dispose === "function") dispose();
          return false;
        }
        if (typeof dispose === "function") record.dispose = dispose;
        return true;
      } catch (error) {
        if (records.get(element) === record) unmount(element);
        throw error;
      }
    },
    unmount,
    unmountAll,
    unmountWhere(predicate: (element: Element) => boolean): boolean {
      let found = false;
      for (const element of records.keys()) {
        if (predicate(element)) found = unmount(element) || found;
      }
      return found;
    },
    dispose() {
      if (stopped) return;
      stopped = true;
      observer.disconnect();
      unmountAll();
    },
  };
}
