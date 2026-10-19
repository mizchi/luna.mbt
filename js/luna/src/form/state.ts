import { batch, createSignal, onCleanup } from "../index";
import type { ActionFormReturn, FormAdapter } from "./contracts";

/** Shared reactive form state. Protocol and navigation belong to the adapter. */
export function createActionForm<T extends Record<string, unknown>, E>(
  defaults: T,
  adapter: FormAdapter<T, E>,
): ActionFormReturn<T, E> {
  const [data, setData] = createSignal<T>({ ...defaults });
  const [initial, setInitial] = createSignal<T>({ ...defaults });
  const [errors, setErrors] = createSignal<Record<string, string>>({});
  const [error, setError] = createSignal<E | null>(null);
  const [pending, setPending] = createSignal(false);
  const [wasSuccessful, setWasSuccessful] = createSignal(false);
  const [recentlySuccessful, setRecentlySuccessful] = createSignal(false);
  let disposed = false;
  let active: Promise<void> | undefined;
  let controller: AbortController | undefined;
  let successTimeout: ReturnType<typeof setTimeout> | undefined;

  function clearSuccessTimeout() {
    if (successTimeout !== undefined) {
      clearTimeout(successTimeout);
      successTimeout = undefined;
    }
  }

  onCleanup(() => {
    disposed = true;
    controller?.abort();
    clearSuccessTimeout();
    setPending(false);
  });

  async function perform(url: string, method: string) {
    const submitted = { ...data() };
    controller = new AbortController();
    clearSuccessTimeout();
    batch(() => {
      setPending(true);
      setWasSuccessful(false);
      setRecentlySuccessful(false);
      setErrors({});
      setError(null);
    });
    try {
      const result = await adapter.submit(url, method, submitted, controller.signal);
      if (disposed) return;
      switch (result.kind) {
        case "redirect":
          await adapter.navigation.navigate(result.url);
          break;
        case "validation":
          setErrors(result.errors);
          break;
        case "error":
          setError(result.error);
          break;
        case "success":
          batch(() => {
            setInitial(submitted);
            setWasSuccessful(true);
            setRecentlySuccessful(true);
          });
          successTimeout = setTimeout(() => {
            successTimeout = undefined;
            setRecentlySuccessful(false);
          }, 2000);
          await adapter.navigation.refresh();
          break;
      }
    } catch (cause) {
      if (!disposed) throw cause;
    } finally {
      if (!disposed) setPending(false);
      controller = undefined;
    }
  }

  function submit(url: string, method: string): Promise<void> {
    if (disposed) return Promise.reject(new Error("Action form owner has been disposed."));
    if (pending()) return active ?? Promise.resolve();
    active = perform(url, method).finally(() => {
      active = undefined;
    });
    return active;
  }

  return {
    get data() {
      return data();
    },
    get errors() {
      return errors();
    },
    get error() {
      return error();
    },
    get pending() {
      return pending();
    },
    get wasSuccessful() {
      return wasSuccessful();
    },
    get recentlySuccessful() {
      return recentlySuccessful();
    },
    get hasChanges() {
      const current = data();
      const baseline = initial();
      return Object.keys(baseline).some(
        (key) => !adapter.isEqualValue(current[key], baseline[key]),
      );
    },
    setData(field, value) {
      setData((previous) => ({ ...previous, [field]: value }));
    },
    reset(...fields) {
      const baseline = initial();
      if (fields.length === 0) setData({ ...baseline });
      else
        setData((previous) => {
          const next = { ...previous };
          for (const field of fields) next[field] = baseline[field];
          return next;
        });
    },
    clearErrors(...fields) {
      if (fields.length === 0) setErrors({});
      else
        setErrors((previous) => {
          const next = { ...previous };
          for (const field of fields) delete next[field];
          return next;
        });
    },
    clearError() {
      setError(null);
    },
    post: (url) => submit(url, "POST"),
    put: (url) => submit(url, "PUT"),
    patch: (url) => submit(url, "PATCH"),
    delete: (url) => submit(url, "DELETE"),
  };
}
