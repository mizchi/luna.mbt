/** @jsxImportSource ../src */
import { describe, it, expect, beforeEach, afterEach } from "vitest";
import "global-jsdom/register";
import {
  createSignal,
  onMount,
  onCleanup,
  render,
  mount,
  Show,
  show,
} from "../src/index";
import type { JSX } from "../src/jsx-runtime";

const flushMicrotasks = () => new Promise<void>((resolve) => queueMicrotask(resolve));
const countLogs = (log: string[]) => {
  const created = log.filter((item) => item.endsWith(" created")).length;
  const mounted = log.filter((item) => item.endsWith(" mounted")).length;
  const cleanups = log.filter((item) => item.endsWith(" cleanup")).length;
  return { created, mounted, cleanups };
};

const expectCounts = (
  log: string[],
  expected: { created: number; mounted: number; cleanups: number },
) => {
  const { created, mounted, cleanups } = countLogs(log);
  try {
    expect(created).toBe(expected.created);
    expect(mounted).toBe(expected.mounted);
    expect(cleanups).toBe(expected.cleanups);
  } catch (error) {
    console.log({ counts: { created, mounted, cleanups }, log });
    throw error;
  }
};

describe("Show initial mount behavior", () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  afterEach(() => {
    container.remove();
  });

  it("reproduces multiple instances with Show when=true on initial render", async () => {
    const log: string[] = [];
    let gId = 1;

    function Child(): JSX.Element {
      const id = gId++;

      onMount(() => {
        log.push(`${id} mounted`);
      });

      onCleanup(() => {
        log.push(`${id} cleanup`);
      });

      log.push(`${id} created`);

      return <p>I'm here</p>;
    }

    function Counter(): JSX.Element {
      return (
        <div>
          <Show when={true}>{() => <Child />}</Show>
        </div>
      );
    }

    render(container, <Counter />);

    await flushMicrotasks();
    await flushMicrotasks();
    await flushMicrotasks();
    await flushMicrotasks();

    expectCounts(log, { created: 1, mounted: 1, cleanups: 0 });
  });

  it("does not create multiple instances without Show", async () => {
    const log: string[] = [];
    let gId = 1;

    function Child(): JSX.Element {
      const id = gId++;

      onMount(() => {
        log.push(`${id} mounted`);
      });

      onCleanup(() => {
        log.push(`${id} cleanup`);
      });

      log.push(`${id} created`);

      return <p>I'm here</p>;
    }

    function Counter(): JSX.Element {
      return (
        <div>
          <Child />
        </div>
      );
    }

    render(container, <Counter />);

    await flushMicrotasks();
    await flushMicrotasks();

    expectCounts(log, { created: 1, mounted: 1, cleanups: 0 });
  });

  it("does not create multiple instances with Show when=true using mount", async () => {
    const log: string[] = [];
    let gId = 1;

    function Child(): JSX.Element {
      const id = gId++;

      onMount(() => {
        log.push(`${id} mounted`);
      });

      onCleanup(() => {
        log.push(`${id} cleanup`);
      });

      log.push(`${id} created`);

      return <p>I'm here</p>;
    }

    const node = Show({ when: true, children: () => <Child /> });
    mount(container, node);

    await flushMicrotasks();
    await flushMicrotasks();

    expectCounts(log, { created: 1, mounted: 1, cleanups: 0 });
  });

  it("does not create multiple instances when render uses show() primitive", async () => {
    const log: string[] = [];
    let gId = 1;
    const [visible] = createSignal(true);

    function Child(): JSX.Element {
      const id = gId++;

      onMount(() => {
        log.push(`${id} mounted`);
      });

      onCleanup(() => {
        log.push(`${id} cleanup`);
      });

      log.push(`${id} created`);

      return <p>I'm here</p>;
    }

    const node = show(visible, () => <Child />);
    render(container, node);

    await flushMicrotasks();
    await flushMicrotasks();

    expectCounts(log, { created: 1, mounted: 1, cleanups: 0 });
  });
});
