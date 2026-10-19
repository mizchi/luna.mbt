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

  function unmountWhere(predicate: (element: Element) => boolean): boolean {
    let found = false;
    for (const element of records.keys()) {
      if (predicate(element)) found = unmount(element) || found;
    }
    return found;
  }

  function unmountAll(root?: Element) {
    unmountWhere((element) => !root || root.contains(element));
  }

  const observer = new MutationObserver(() => {
    unmountWhere((element) => !element.isConnected);
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
        const current = isCurrent();
        if (!current && records.get(element) === record) unmount(element);
        if (typeof dispose === "function") {
          if (current) record.dispose = dispose;
          else dispose();
        }
        return current;
      } catch (error) {
        if (records.get(element) === record) unmount(element);
        throw error;
      }
    },
    unmount,
    unmountAll,
    unmountWhere,
    dispose() {
      if (stopped) return;
      stopped = true;
      observer.disconnect();
      unmountAll();
    },
  };
}
