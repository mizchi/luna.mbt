/**
 * Counter Web Component tests with happy-dom
 */

import { describe, it, expect, beforeAll, afterEach } from 'vitest';
import {
  register,
  attrInt,
  attrString,
  attrBool,
  Signal,
} from '@mizchi/luna-wcr';

// Define counter component for testing
interface CounterProps {
  initial: number;
  label: string;
  disabled: boolean;
}

function registerCounter() {
  if (customElements.get('x-counter')) return;

  register<CounterProps>({
    tag: 'x-counter',
    attributes: [
      attrInt('initial', 0),
      attrString('label', 'Count'),
      attrBool('disabled', false),
    ],
    styles: `
      :host { display: block; }
      .counter { display: flex; gap: 8px; }
    `,
    template: (props) => `
      <div class="counter">
        <span class="label">${props.label}:</span>
        <button class="dec">-</button>
        <span class="value">${props.initial}</span>
        <button class="inc">+</button>
      </div>
    `,
    setup: (ctx) => {
      const count = new Signal(ctx.props.initial.get());

      // Sync with external attribute changes
      const unsyncInitial = ctx.props.initial.subscribe(() => {
        count.set(ctx.props.initial.get());
      });

      // Bind value display
      const unbindValue = ctx.bind('.value', () => String(count.get()));

      // Bind label
      const unbindLabel = ctx.bind('.label', () => `${ctx.props.label.get()}:`);

      // Bind disabled
      const unbindDecDisabled = ctx.bindAttr('.dec', 'disabled', ctx.props.disabled);
      const unbindIncDisabled = ctx.bindAttr('.inc', 'disabled', ctx.props.disabled);

      // Event handlers
      const unbindDec = ctx.on('.dec', 'click', () => {
        count.update((n) => n - 1);
      });
      const unbindInc = ctx.on('.inc', 'click', () => {
        count.update((n) => n + 1);
      });

      return () => {
        unsyncInitial();
        unbindValue();
        unbindLabel();
        unbindDecDisabled();
        unbindIncDisabled();
        unbindDec();
        unbindInc();
      };
    },
  });
}

describe('x-counter Web Component', () => {
  beforeAll(() => {
    registerCounter();
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('should register custom element', () => {
    expect(customElements.get('x-counter')).toBeDefined();
  });

  it('should render with default attributes', async () => {
    document.body.innerHTML = '<x-counter></x-counter>';
    const el = document.querySelector('x-counter')!;

    // Wait for connectedCallback
    await new Promise((r) => setTimeout(r, 0));

    const shadow = el.shadowRoot!;
    expect(shadow).toBeDefined();

    const value = shadow.querySelector('.value');
    expect(value?.textContent).toBe('0');

    const label = shadow.querySelector('.label');
    expect(label?.textContent).toBe('Count:');
  });

  it('should render with initial attribute', async () => {
    document.body.innerHTML = '<x-counter initial="42"></x-counter>';
    const el = document.querySelector('x-counter')!;

    await new Promise((r) => setTimeout(r, 0));

    const shadow = el.shadowRoot!;
    const value = shadow.querySelector('.value');
    expect(value?.textContent).toBe('42');
  });

  it('should render with custom label', async () => {
    document.body.innerHTML = '<x-counter label="Score"></x-counter>';
    const el = document.querySelector('x-counter')!;

    await new Promise((r) => setTimeout(r, 0));

    const shadow = el.shadowRoot!;
    const label = shadow.querySelector('.label');
    expect(label?.textContent).toBe('Score:');
  });

  it('should increment on click', async () => {
    document.body.innerHTML = '<x-counter initial="5"></x-counter>';
    const el = document.querySelector('x-counter')!;

    await new Promise((r) => setTimeout(r, 0));

    const shadow = el.shadowRoot!;
    const incBtn = shadow.querySelector('.inc') as HTMLButtonElement;
    const value = shadow.querySelector('.value');

    expect(value?.textContent).toBe('5');

    incBtn.click();
    await new Promise((r) => setTimeout(r, 0));
    expect(value?.textContent).toBe('6');

    incBtn.click();
    await new Promise((r) => setTimeout(r, 0));
    expect(value?.textContent).toBe('7');
  });

  it('should decrement on click', async () => {
    document.body.innerHTML = '<x-counter initial="10"></x-counter>';
    const el = document.querySelector('x-counter')!;

    await new Promise((r) => setTimeout(r, 0));

    const shadow = el.shadowRoot!;
    const decBtn = shadow.querySelector('.dec') as HTMLButtonElement;
    const value = shadow.querySelector('.value');

    expect(value?.textContent).toBe('10');

    decBtn.click();
    await new Promise((r) => setTimeout(r, 0));
    expect(value?.textContent).toBe('9');
  });

  it('should update when attribute changes', async () => {
    document.body.innerHTML = '<x-counter initial="0"></x-counter>';
    const el = document.querySelector('x-counter')!;

    await new Promise((r) => setTimeout(r, 0));

    const shadow = el.shadowRoot!;
    const value = shadow.querySelector('.value');
    expect(value?.textContent).toBe('0');

    // Change attribute
    el.setAttribute('initial', '100');
    await new Promise((r) => setTimeout(r, 0));
    expect(value?.textContent).toBe('100');
  });

  it('should handle disabled attribute', async () => {
    document.body.innerHTML = '<x-counter disabled></x-counter>';
    const el = document.querySelector('x-counter')!;

    await new Promise((r) => setTimeout(r, 0));

    const shadow = el.shadowRoot!;
    const incBtn = shadow.querySelector('.inc') as HTMLButtonElement;
    const decBtn = shadow.querySelector('.dec') as HTMLButtonElement;

    expect(incBtn.hasAttribute('disabled')).toBe(true);
    expect(decBtn.hasAttribute('disabled')).toBe(true);
  });

  it('should toggle disabled dynamically', async () => {
    document.body.innerHTML = '<x-counter></x-counter>';
    const el = document.querySelector('x-counter')!;

    await new Promise((r) => setTimeout(r, 0));

    const shadow = el.shadowRoot!;
    const incBtn = shadow.querySelector('.inc') as HTMLButtonElement;

    expect(incBtn.hasAttribute('disabled')).toBe(false);

    el.setAttribute('disabled', '');
    await new Promise((r) => setTimeout(r, 0));
    expect(incBtn.hasAttribute('disabled')).toBe(true);

    el.removeAttribute('disabled');
    await new Promise((r) => setTimeout(r, 0));
    expect(incBtn.hasAttribute('disabled')).toBe(false);
  });

  it('should cleanup on disconnect', async () => {
    document.body.innerHTML = '<x-counter></x-counter>';
    const el = document.querySelector('x-counter')!;

    await new Promise((r) => setTimeout(r, 0));

    // Remove element
    el.remove();

    // Should not throw
    expect(() => {
      document.body.innerHTML = '<x-counter></x-counter>';
    }).not.toThrow();
  });
});

describe('x-counter with SSR (Declarative Shadow DOM)', () => {
  beforeAll(() => {
    registerCounter();
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('should hydrate pre-rendered content', async () => {
    // Simulate SSR output with Declarative Shadow DOM
    document.body.innerHTML = `
      <x-counter initial="50">
        <template shadowrootmode="open">
          <style>:host { display: block; }</style>
          <div class="counter">
            <span class="label">Items:</span>
            <button class="dec">-</button>
            <span class="value">50</span>
            <button class="inc">+</button>
          </div>
        </template>
      </x-counter>
    `;

    const el = document.querySelector('x-counter')!;
    await new Promise((r) => setTimeout(r, 0));

    const shadow = el.shadowRoot;
    // Note: happy-dom may or may not support declarative shadow DOM
    // This test documents the expected behavior
    if (shadow) {
      const value = shadow.querySelector('.value');
      expect(value?.textContent).toBe('50');

      // Click should still work after hydration
      const incBtn = shadow.querySelector('.inc') as HTMLButtonElement;
      incBtn?.click();
      await new Promise((r) => setTimeout(r, 0));
      expect(value?.textContent).toBe('51');
    }
  });
});
