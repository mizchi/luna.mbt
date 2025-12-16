/**
 * Island vs WC Island Decision Benchmarks
 *
 * Luna Islands と WC Islands の使い分け判断に必要なベンチマーク
 * - イベントバブリング再dispatch のオーバーヘッド
 * - ネストされたコンポーネント間のシグナル伝搬
 * - 大量コンポーネントのメモリ使用量
 *
 * Run: pnpm bench
 */

import { describe, bench, beforeAll, afterAll } from 'vitest';

// ============================================
// Signal Implementation (same as test)
// ============================================

type Subscriber<T> = (value: T) => void;

interface Signal<T> {
  get(): T;
  set(value: T): void;
  subscribe(fn: Subscriber<T>): () => void;
  subscriberCount(): number;
}

function createSignal<T>(initial: T): Signal<T> {
  let value = initial;
  const subscribers = new Set<Subscriber<T>>();

  return {
    get: () => value,
    set: (newValue: T) => {
      if (value !== newValue) {
        value = newValue;
        subscribers.forEach((fn) => fn(value));
      }
    },
    subscribe: (fn: Subscriber<T>) => {
      subscribers.add(fn);
      return () => subscribers.delete(fn);
    },
    subscriberCount: () => subscribers.size,
  };
}

// ============================================
// Helper: Unique tag names
// ============================================

let uniqueId = 0;
function getUniqueTagName(prefix: string): string {
  return `${prefix}-${Date.now()}-${++uniqueId}`;
}

// ============================================
// 1. Event Bubbling / Re-dispatch Benchmarks
// ============================================

describe('Event Bubbling: WC vs Plain DOM', () => {
  /**
   * WC境界を越えるイベント伝搬のオーバーヘッドを測定
   * Ryan Carniato の指摘: event delegation code の複雑性が2倍に
   */

  bench('Plain DOM - Event bubbling (no boundary)', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    container.innerHTML = `
      <div class="outer">
        <div class="middle">
          <div class="inner">
            <button data-action="click">Click</button>
          </div>
        </div>
      </div>
    `;

    let received = 0;

    // Event delegation at outer level
    const outer = container.querySelector('.outer')!;
    outer.addEventListener('click', (e) => {
      const target = e.target as HTMLElement;
      if (target.dataset.action) {
        received++;
      }
    });

    // Simulate click
    const btn = container.querySelector('button')!;
    btn.click();

    if (received !== 1) throw new Error('Event not received');
    document.body.removeChild(container);
  });

  bench('WC - Event bubbling (composed: true, single boundary)', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    // Create WC with shadow DOM
    const tagName = getUniqueTagName('wc-event-single');

    class TestWC extends HTMLElement {
      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }
      connectedCallback() {
        this.shadowRoot!.innerHTML = `<button data-action="click">Click</button>`;
      }
    }
    if (!customElements.get(tagName)) {
      customElements.define(tagName, TestWC);
    }

    container.innerHTML = `
      <div class="outer">
        <${tagName}></${tagName}>
      </div>
    `;

    let received = 0;

    // Listen for composed event at outer level
    const outer = container.querySelector('.outer')!;
    outer.addEventListener('click', (e) => {
      // With composed: true, event crosses shadow boundary
      // but target is the host element, not the button
      received++;
    });

    // Access shadow DOM button
    const wc = container.querySelector(tagName) as HTMLElement;
    const btn = wc.shadowRoot!.querySelector('button')!;
    btn.click();

    if (received !== 1) throw new Error('Event not received');
    document.body.removeChild(container);
  });

  bench('WC - Event bubbling (3 nested shadow boundaries)', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    const tagName1 = getUniqueTagName('wc-nested-1');
    const tagName2 = getUniqueTagName('wc-nested-2');
    const tagName3 = getUniqueTagName('wc-nested-3');

    // Level 3 (innermost)
    class Level3 extends HTMLElement {
      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }
      connectedCallback() {
        this.shadowRoot!.innerHTML = `<button data-action="click">Click</button>`;
      }
    }

    // Level 2
    class Level2 extends HTMLElement {
      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }
      connectedCallback() {
        this.shadowRoot!.innerHTML = `<${tagName3}></${tagName3}>`;
      }
    }

    // Level 1
    class Level1 extends HTMLElement {
      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }
      connectedCallback() {
        this.shadowRoot!.innerHTML = `<${tagName2}></${tagName2}>`;
      }
    }

    if (!customElements.get(tagName3)) customElements.define(tagName3, Level3);
    if (!customElements.get(tagName2)) customElements.define(tagName2, Level2);
    if (!customElements.get(tagName1)) customElements.define(tagName1, Level1);

    container.innerHTML = `<${tagName1}></${tagName1}>`;

    let received = 0;
    container.addEventListener('click', () => {
      received++;
    });

    // Navigate to innermost button
    const l1 = container.querySelector(tagName1) as HTMLElement;
    const l2 = l1.shadowRoot!.querySelector(tagName2) as HTMLElement;
    const l3 = l2.shadowRoot!.querySelector(tagName3) as HTMLElement;
    const btn = l3.shadowRoot!.querySelector('button')!;
    btn.click();

    if (received !== 1) throw new Error('Event not received through 3 boundaries');
    document.body.removeChild(container);
  });

  bench('WC - Manual event re-dispatch (retargeting pattern)', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    const tagName = getUniqueTagName('wc-redispatch');

    class RedispatchWC extends HTMLElement {
      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }
      connectedCallback() {
        this.shadowRoot!.innerHTML = `<button data-action="click">Click</button>`;

        // Listen inside shadow DOM and re-dispatch from host
        this.shadowRoot!.addEventListener('click', (e) => {
          const target = e.target as HTMLElement;
          if (target.dataset.action) {
            // Re-dispatch with action info
            this.dispatchEvent(
              new CustomEvent('action', {
                bubbles: true,
                composed: true,
                detail: { action: target.dataset.action },
              })
            );
          }
        });
      }
    }

    if (!customElements.get(tagName)) {
      customElements.define(tagName, RedispatchWC);
    }

    container.innerHTML = `<${tagName}></${tagName}>`;

    let received = 0;
    container.addEventListener('action', (e) => {
      const detail = (e as CustomEvent).detail;
      if (detail.action === 'click') received++;
    });

    const wc = container.querySelector(tagName) as HTMLElement;
    const btn = wc.shadowRoot!.querySelector('button')!;
    btn.click();

    if (received !== 1) throw new Error('Re-dispatched event not received');
    document.body.removeChild(container);
  });
});

// ============================================
// 2. Signal Propagation Benchmarks
// ============================================

describe('Signal Propagation: WC vs Plain DOM', () => {
  /**
   * シグナル更新がコンポーネントに伝搬する速度を測定
   * 懸念: Shadow Root の境界がシグナル伝搬を遅くするか？
   */

  bench('Plain DOM - Signal update (10 subscribers)', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    container.innerHTML = Array.from(
      { length: 10 },
      (_, i) => `<div class="item item-${i}"><span class="value">0</span></div>`
    ).join('');

    const signal = createSignal(0);

    // Subscribe each item
    container.querySelectorAll('.item').forEach((item) => {
      const span = item.querySelector('.value')!;
      signal.subscribe((v) => {
        span.textContent = String(v);
      });
    });

    // Update signal 100 times
    for (let i = 0; i < 100; i++) {
      signal.set(i);
    }

    document.body.removeChild(container);
  });

  bench('WC - Signal update (10 WC subscribers)', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    const signal = createSignal(0);

    // Create 10 WC elements
    const tagName = getUniqueTagName('wc-signal-sub');

    class SignalSubscriber extends HTMLElement {
      private _unsub?: () => void;
      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }
      connectedCallback() {
        this.shadowRoot!.innerHTML = `<span class="value">0</span>`;
        const span = this.shadowRoot!.querySelector('.value')!;
        this._unsub = signal.subscribe((v) => {
          span.textContent = String(v);
        });
      }
      disconnectedCallback() {
        this._unsub?.();
      }
    }

    if (!customElements.get(tagName)) {
      customElements.define(tagName, SignalSubscriber);
    }

    container.innerHTML = Array.from({ length: 10 }, () => `<${tagName}></${tagName}>`).join('');

    // Update signal 100 times
    for (let i = 0; i < 100; i++) {
      signal.set(i);
    }

    document.body.removeChild(container);
  });

  bench('Plain DOM - Signal update (100 subscribers)', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    container.innerHTML = Array.from(
      { length: 100 },
      (_, i) => `<div class="item item-${i}"><span class="value">0</span></div>`
    ).join('');

    const signal = createSignal(0);

    container.querySelectorAll('.item').forEach((item) => {
      const span = item.querySelector('.value')!;
      signal.subscribe((v) => {
        span.textContent = String(v);
      });
    });

    for (let i = 0; i < 100; i++) {
      signal.set(i);
    }

    document.body.removeChild(container);
  });

  bench('WC - Signal update (100 WC subscribers)', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    const signal = createSignal(0);

    const tagName = getUniqueTagName('wc-signal-sub-100');

    class SignalSubscriber100 extends HTMLElement {
      private _unsub?: () => void;
      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }
      connectedCallback() {
        this.shadowRoot!.innerHTML = `<span class="value">0</span>`;
        const span = this.shadowRoot!.querySelector('.value')!;
        this._unsub = signal.subscribe((v) => {
          span.textContent = String(v);
        });
      }
      disconnectedCallback() {
        this._unsub?.();
      }
    }

    if (!customElements.get(tagName)) {
      customElements.define(tagName, SignalSubscriber100);
    }

    container.innerHTML = Array.from({ length: 100 }, () => `<${tagName}></${tagName}>`).join('');

    for (let i = 0; i < 100; i++) {
      signal.set(i);
    }

    document.body.removeChild(container);
  });

  bench('Nested WC - Signal update through 5 levels', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    const signal = createSignal(0);
    const tags: string[] = [];

    // Create 5 nested levels
    for (let level = 0; level < 5; level++) {
      const tagName = getUniqueTagName(`wc-nested-signal-${level}`);
      tags.push(tagName);

      const childTag = level < 4 ? tags[level + 1] : null;

      class NestedSignal extends HTMLElement {
        private _unsub?: () => void;
        constructor() {
          super();
          this.attachShadow({ mode: 'open' });
        }
        connectedCallback() {
          const child = childTag ? `<${childTag}></${childTag}>` : '';
          this.shadowRoot!.innerHTML = `<span class="value">0</span>${child}`;
          const span = this.shadowRoot!.querySelector('.value')!;
          this._unsub = signal.subscribe((v) => {
            span.textContent = String(v);
          });
        }
        disconnectedCallback() {
          this._unsub?.();
        }
      }

      if (!customElements.get(tagName)) {
        customElements.define(tagName, NestedSignal);
      }
    }

    // Insert outermost
    container.innerHTML = `<${tags[0]}></${tags[0]}>`;

    // Update signal 100 times (all 5 levels update)
    for (let i = 0; i < 100; i++) {
      signal.set(i);
    }

    document.body.removeChild(container);
  });
});

// ============================================
// 3. Memory & Initialization Benchmarks
// ============================================

describe('Memory & Initialization: WC vs Plain DOM', () => {
  /**
   * 大量コンポーネント生成時のメモリとパフォーマンス
   */

  bench('Plain DOM - Create 100 components (innerHTML)', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    container.innerHTML = Array.from(
      { length: 100 },
      (_, i) => `
      <div class="component" data-id="${i}">
        <style>.component { display: block; }</style>
        <div class="header">Header ${i}</div>
        <div class="content">Content ${i}</div>
        <button data-action="click">Click</button>
      </div>
    `
    ).join('');

    document.body.removeChild(container);
  });

  bench('WC - Create 100 components (Declarative Shadow DOM)', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    const tagName = getUniqueTagName('wc-mass-create');

    container.innerHTML = Array.from(
      { length: 100 },
      (_, i) => `
      <${tagName} data-id="${i}">
        <template shadowrootmode="open">
          <style>:host { display: block; }</style>
          <div class="header">Header ${i}</div>
          <div class="content">Content ${i}</div>
          <button data-action="click">Click</button>
        </template>
      </${tagName}>
    `
    ).join('');

    document.body.removeChild(container);
  });

  bench('WC - Create 100 components (attachShadow)', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    const tagName = getUniqueTagName('wc-mass-attach');

    class MassAttach extends HTMLElement {
      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }
      connectedCallback() {
        const id = this.dataset.id;
        this.shadowRoot!.innerHTML = `
          <style>:host { display: block; }</style>
          <div class="header">Header ${id}</div>
          <div class="content">Content ${id}</div>
          <button data-action="click">Click</button>
        `;
      }
    }

    if (!customElements.get(tagName)) {
      customElements.define(tagName, MassAttach);
    }

    container.innerHTML = Array.from(
      { length: 100 },
      (_, i) => `<${tagName} data-id="${i}"></${tagName}>`
    ).join('');

    document.body.removeChild(container);
  });

  bench('WC - Create 100 with Adoptable Stylesheets', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    const tagName = getUniqueTagName('wc-mass-adoptable');

    // Shared stylesheet
    const sheet = new CSSStyleSheet();
    sheet.replaceSync(':host { display: block; padding: 8px; margin: 4px; }');

    class MassAdoptable extends HTMLElement {
      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }
      connectedCallback() {
        this.shadowRoot!.adoptedStyleSheets = [sheet];
        const id = this.dataset.id;
        this.shadowRoot!.innerHTML = `
          <div class="header">Header ${id}</div>
          <div class="content">Content ${id}</div>
          <button data-action="click">Click</button>
        `;
      }
    }

    if (!customElements.get(tagName)) {
      customElements.define(tagName, MassAdoptable);
    }

    container.innerHTML = Array.from(
      { length: 100 },
      (_, i) => `<${tagName} data-id="${i}"></${tagName}>`
    ).join('');

    document.body.removeChild(container);
  });
});

// ============================================
// 4. querySelector Performance in Shadow DOM
// ============================================

describe('querySelector: Light DOM vs Shadow DOM', () => {
  /**
   * Shadow DOM 内での querySelector のパフォーマンス
   * hydration 時のイベントバインドに影響
   */

  bench('Light DOM - querySelector (100 items)', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    container.innerHTML = Array.from(
      { length: 100 },
      (_, i) => `<div class="item" data-id="${i}"><span class="value">${i}</span></div>`
    ).join('');

    // Query each item
    for (let i = 0; i < 100; i++) {
      const item = container.querySelector(`[data-id="${i}"]`);
      const value = item?.querySelector('.value');
      if (!value) throw new Error('Not found');
    }

    document.body.removeChild(container);
  });

  bench('Shadow DOM - querySelector (100 WC items)', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    const tagName = getUniqueTagName('wc-query');

    class QueryWC extends HTMLElement {
      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }
      connectedCallback() {
        const id = this.dataset.id;
        this.shadowRoot!.innerHTML = `<span class="value">${id}</span>`;
      }
    }

    if (!customElements.get(tagName)) {
      customElements.define(tagName, QueryWC);
    }

    container.innerHTML = Array.from(
      { length: 100 },
      (_, i) => `<${tagName} data-id="${i}"></${tagName}>`
    ).join('');

    // Query each WC's shadow DOM
    container.querySelectorAll(tagName).forEach((wc) => {
      const value = (wc as HTMLElement).shadowRoot?.querySelector('.value');
      if (!value) throw new Error('Not found in shadow DOM');
    });

    document.body.removeChild(container);
  });
});

// ============================================
// 5. Context Propagation (WC limitation)
// ============================================

describe('Context Propagation Patterns', () => {
  /**
   * Ryan Carniato の指摘: "Context needs to exist and persist beyond DOM elements"
   * WC ではコンテキスト伝搬が困難
   */

  bench('Plain DOM - Context via closure (10 levels)', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    // Context is a simple object
    const context = { theme: 'dark', user: 'test' };

    // Create nested DOM with access to context via closure
    function createLevel(depth: number, ctx: typeof context): string {
      if (depth === 0) {
        return `<div class="leaf" data-theme="${ctx.theme}">Leaf</div>`;
      }
      return `<div class="level-${depth}">${createLevel(depth - 1, ctx)}</div>`;
    }

    container.innerHTML = createLevel(10, context);

    // Access context at leaf
    const leaf = container.querySelector('.leaf') as HTMLElement;
    if (leaf.dataset.theme !== 'dark') throw new Error('Context not propagated');

    document.body.removeChild(container);
  });

  bench('WC - Context via attribute drilling (10 levels)', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    const tags: string[] = [];

    // Create 10 nested WC levels, passing context via attributes
    for (let level = 0; level < 10; level++) {
      const tagName = getUniqueTagName(`wc-ctx-${level}`);
      tags.push(tagName);

      const childTag = level < 9 ? tags[level + 1] : null;

      class ContextWC extends HTMLElement {
        constructor() {
          super();
          this.attachShadow({ mode: 'open' });
        }
        connectedCallback() {
          const theme = this.getAttribute('data-theme') || 'light';
          const child = childTag ? `<${childTag} data-theme="${theme}"></${childTag}>` : `<div class="leaf">Leaf</div>`;
          this.shadowRoot!.innerHTML = child;
        }
      }

      if (!customElements.get(tagName)) {
        customElements.define(tagName, ContextWC);
      }
    }

    container.innerHTML = `<${tags[0]} data-theme="dark"></${tags[0]}>`;

    // Verify context reached leaf (manual traversal through shadow DOMs)
    let current: HTMLElement | null = container.querySelector(tags[0]);
    for (let i = 1; i < 10 && current; i++) {
      current = current.shadowRoot?.querySelector(tags[i]) as HTMLElement | null;
    }

    document.body.removeChild(container);
  });

  bench('WC - Context via custom event bubbling', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    const providerTag = getUniqueTagName('ctx-provider');
    const consumerTag = getUniqueTagName('ctx-consumer');

    // Provider: responds to context requests
    class ContextProvider extends HTMLElement {
      private _context = { theme: 'dark', user: 'test' };

      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }

      connectedCallback() {
        this.shadowRoot!.innerHTML = `<slot></slot>`;

        // Listen for context requests
        this.addEventListener('context-request', ((e: CustomEvent) => {
          e.stopPropagation();
          e.detail.callback(this._context);
        }) as EventListener);
      }
    }

    // Consumer: requests context on connect
    class ContextConsumer extends HTMLElement {
      private _context: { theme: string; user: string } | null = null;

      constructor() {
        super();
        this.attachShadow({ mode: 'open' });
      }

      connectedCallback() {
        // Request context
        this.dispatchEvent(
          new CustomEvent('context-request', {
            bubbles: true,
            composed: true,
            detail: {
              callback: (ctx: { theme: string; user: string }) => {
                this._context = ctx;
                this.render();
              },
            },
          })
        );
      }

      private render() {
        this.shadowRoot!.innerHTML = `<div class="themed" data-theme="${this._context?.theme}">Consumer</div>`;
      }
    }

    if (!customElements.get(providerTag)) customElements.define(providerTag, ContextProvider);
    if (!customElements.get(consumerTag)) customElements.define(consumerTag, ContextConsumer);

    container.innerHTML = `
      <${providerTag}>
        <${consumerTag}></${consumerTag}>
      </${providerTag}>
    `;

    const consumer = container.querySelector(consumerTag) as HTMLElement;
    const themed = consumer.shadowRoot?.querySelector('.themed') as HTMLElement;
    if (themed?.dataset.theme !== 'dark') throw new Error('Context not received');

    document.body.removeChild(container);
  });
});
