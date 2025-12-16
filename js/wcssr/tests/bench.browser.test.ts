/**
 * Performance Benchmarks: Web Components vs Plain DOM
 *
 * WC版（Shadow DOM）と通常のDOM操作のパフォーマンス比較
 * vitest bench --config vitest.bench.config.ts
 */

import { describe, bench } from 'vitest';
import { createSSRRenderer, renderComponentInline, escapeAttr, escapeJson } from '../src/server.js';
import { defineComponent } from '../src/client.js';
import { hydratePartsFromElement } from '../src/parts.js';

// ============================================
// Test Components Definition
// ============================================

const CounterComponent = defineComponent({
  name: 'bench-counter',
  styles: `
    :host { display: block; padding: 8px; }
    .count { font-size: 1.5rem; font-weight: bold; }
    button { padding: 4px 8px; margin: 0 4px; }
  `,
  initialState: { count: 0 },
  render: (state) => `
    <div class="count">${state.count}</div>
    <button data-on-click="decrement">-</button>
    <button data-on-click="increment">+</button>
  `,
  handlers: {
    increment: (state) => ({ count: state.count + 1 }),
    decrement: (state) => ({ count: state.count - 1 }),
  },
});

// ============================================
// Helper Functions
// ============================================

let uniqueId = 0;

function getUniqueTagName(prefix: string): string {
  return `${prefix}-${Date.now()}-${++uniqueId}`;
}

// ============================================
// SSR Rendering Benchmarks
// ============================================

describe('SSR Rendering Performance', () => {
  const renderer = createSSRRenderer({ cssStrategy: 'inline' });
  const iterations = 1000;

  // WC SSR - フル処理（エスケープ + Shadow DOM 構文）
  bench('WC SSR - Full (with escape)', () => {
    for (let i = 0; i < iterations; i++) {
      renderer.render(CounterComponent, { count: i });
    }
  });

  // WC SSR - 最小構成
  bench('WC SSR - renderComponentInline', () => {
    for (let i = 0; i < iterations; i++) {
      renderComponentInline(
        'bench-counter',
        ':host { display: block; }',
        JSON.stringify({ count: i }),
        `<div class="count">${i}</div>`
      );
    }
  });

  // Plain HTML - エスケープなし（不公平な比較）
  bench('Plain HTML - No escape (unfair)', () => {
    for (let i = 0; i < iterations; i++) {
      const html = `
        <div class="counter" data-state="${i}">
          <style>.counter { display: block; padding: 8px; }</style>
          <div class="count">${i}</div>
          <button data-action="decrement">-</button>
          <button data-action="increment">+</button>
        </div>
      `;
      html.length;
    }
  });

  // Plain HTML - エスケープあり（公平な比較）
  bench('Plain HTML - With escape (fair)', () => {
    for (let i = 0; i < iterations; i++) {
      const state = { count: i };
      const serialized = escapeAttr(escapeJson(JSON.stringify(state)));
      const html = `
        <div class="counter" data-state="${serialized}">
          <style>.counter { display: block; padding: 8px; }</style>
          <div class="count">${i}</div>
          <button data-action="decrement">-</button>
          <button data-action="increment">+</button>
        </div>
      `;
      html.length;
    }
  });

  // Plain HTML - 関数コンポーネント形式
  bench('Plain HTML - Function component', () => {
    const renderCounter = (state: { count: number }) => {
      const serialized = escapeAttr(escapeJson(JSON.stringify(state)));
      return `
        <div class="counter" data-state="${serialized}">
          <style>.counter { display: block; padding: 8px; }</style>
          <div class="count">${state.count}</div>
          <button data-action="decrement">-</button>
          <button data-action="increment">+</button>
        </div>
      `;
    };
    for (let i = 0; i < iterations; i++) {
      renderCounter({ count: i });
    }
  });
});

// ============================================
// SSR Overhead Breakdown
// ============================================

describe('SSR Overhead Breakdown', () => {
  const iterations = 10000;

  // 純粋な文字列結合
  bench('String concatenation only', () => {
    for (let i = 0; i < iterations; i++) {
      const html = `<div>${i}</div>`;
      html.length;
    }
  });

  // JSON.stringify のコスト
  bench('JSON.stringify', () => {
    for (let i = 0; i < iterations; i++) {
      JSON.stringify({ count: i, name: 'test', items: [1, 2, 3] });
    }
  });

  // escapeJson のコスト
  bench('escapeJson', () => {
    const json = '{"count":0,"script":"<script>alert(1)</script>"}';
    for (let i = 0; i < iterations; i++) {
      escapeJson(json);
    }
  });

  // escapeAttr のコスト
  bench('escapeAttr', () => {
    const attr = 'value with <special> "chars" & more';
    for (let i = 0; i < iterations; i++) {
      escapeAttr(attr);
    }
  });

  // escapeJson + escapeAttr 複合
  bench('escapeAttr(escapeJson(...))', () => {
    for (let i = 0; i < iterations; i++) {
      escapeAttr(escapeJson(JSON.stringify({ count: i })));
    }
  });

  // Shadow DOM テンプレート構文のコスト
  bench('Shadow DOM template syntax', () => {
    for (let i = 0; i < iterations; i++) {
      const html = `<my-component>
  <template shadowrootmode="open">
    <style>:host { display: block; }</style>
    <div>${i}</div>
  </template>
</my-component>`;
      html.length;
    }
  });

  // 通常の HTML 構文
  bench('Plain HTML syntax', () => {
    for (let i = 0; i < iterations; i++) {
      const html = `<div class="component">
  <style>.component { display: block; }</style>
  <div>${i}</div>
</div>`;
      html.length;
    }
  });
});

// ============================================
// DOM Creation Benchmarks
// ============================================

describe('DOM Creation Performance', () => {
  bench('WC - innerHTML with Declarative Shadow DOM', () => {
    const c = document.createElement('div');
    document.body.appendChild(c);
    const tagName = getUniqueTagName('wc-create');
    c.innerHTML = `
      <${tagName}>
        <template shadowrootmode="open">
          <style>:host { display: block; }</style>
          <div class="count">0</div>
        </template>
      </${tagName}>
    `;
    document.body.removeChild(c);
  });

  bench('Plain DOM - innerHTML', () => {
    const c = document.createElement('div');
    document.body.appendChild(c);
    c.innerHTML = `
      <div class="counter">
        <style>.counter { display: block; }</style>
        <div class="count">0</div>
      </div>
    `;
    document.body.removeChild(c);
  });

  bench('Plain DOM - createElement', () => {
    const c = document.createElement('div');
    document.body.appendChild(c);
    const div = document.createElement('div');
    div.className = 'counter';
    const style = document.createElement('style');
    style.textContent = '.counter { display: block; }';
    const count = document.createElement('div');
    count.className = 'count';
    count.textContent = '0';
    div.appendChild(style);
    div.appendChild(count);
    c.appendChild(div);
    document.body.removeChild(c);
  });

  bench('WC - attachShadow + innerHTML', () => {
    const c = document.createElement('div');
    document.body.appendChild(c);
    const el = document.createElement('div');
    const shadow = el.attachShadow({ mode: 'open' });
    shadow.innerHTML = `
      <style>:host { display: block; }</style>
      <div class="count">0</div>
    `;
    c.appendChild(el);
    document.body.removeChild(c);
  });
});

// ============================================
// Update Performance Benchmarks
// ============================================

describe('DOM Update Performance', () => {
  // Setup shared elements once
  const setupWC = () => {
    const wcElement = document.createElement('div');
    const shadowRoot = wcElement.attachShadow({ mode: 'open' });
    shadowRoot.innerHTML = `
      <style>:host { display: block; }</style>
      <div class="count">0</div>
    `;
    document.body.appendChild(wcElement);
    return { wcElement, shadowRoot };
  };

  const setupPlain = () => {
    const plainElement = document.createElement('div');
    plainElement.className = 'counter';
    plainElement.innerHTML = `
      <style>.counter { display: block; }</style>
      <div class="count">0</div>
    `;
    document.body.appendChild(plainElement);
    return plainElement;
  };

  bench('WC - Full innerHTML re-render', () => {
    const { wcElement, shadowRoot } = setupWC();
    for (let i = 0; i < 100; i++) {
      shadowRoot.innerHTML = `
        <style>:host { display: block; }</style>
        <div class="count">${i}</div>
      `;
    }
    document.body.removeChild(wcElement);
  });

  bench('WC - Partial textContent update', () => {
    const { wcElement, shadowRoot } = setupWC();
    const countEl = shadowRoot.querySelector('.count')!;
    for (let i = 0; i < 100; i++) {
      countEl.textContent = String(i);
    }
    document.body.removeChild(wcElement);
  });

  bench('Plain DOM - Full innerHTML re-render', () => {
    const plainElement = setupPlain();
    for (let i = 0; i < 100; i++) {
      plainElement.innerHTML = `
        <style>.counter { display: block; }</style>
        <div class="count">${i}</div>
      `;
    }
    document.body.removeChild(plainElement);
  });

  bench('Plain DOM - Partial textContent update', () => {
    const plainElement = setupPlain();
    const countEl = plainElement.querySelector('.count')!;
    for (let i = 0; i < 100; i++) {
      countEl.textContent = String(i);
    }
    document.body.removeChild(plainElement);
  });
});

// ============================================
// DOM Parts vs Direct Update
// ============================================

describe('DOM Parts vs Direct Update', () => {
  const setupParts = () => {
    const c = document.createElement('div');
    c.innerHTML = `<div class="count"><!--{{count}}-->0<!--/{{count}}--></div>`;
    document.body.appendChild(c);
    const parts = hydratePartsFromElement(c);
    return { container: c, part: parts.get('count') };
  };

  const setupDirect = () => {
    const c = document.createElement('div');
    c.innerHTML = `<div class="count"></div>`;
    const textNode = document.createTextNode('0');
    c.querySelector('.count')!.appendChild(textNode);
    document.body.appendChild(c);
    return { container: c, textNode };
  };

  bench('DOM Parts - value + commit', () => {
    const { container: c, part } = setupParts();
    if (part) {
      for (let i = 0; i < 100; i++) {
        part.value = String(i);
        part.commit();
      }
    }
    document.body.removeChild(c);
  });

  bench('Direct - textContent', () => {
    const { container: c, textNode } = setupDirect();
    for (let i = 0; i < 100; i++) {
      textNode.textContent = String(i);
    }
    document.body.removeChild(c);
  });

  bench('DOM Parts - batch updates (set then commit)', () => {
    const { container: c, part } = setupParts();
    if (part) {
      for (let i = 0; i < 100; i++) {
        part.value = String(i);
      }
      part.commit();
    }
    document.body.removeChild(c);
  });
});

// ============================================
// Event Binding Benchmarks
// ============================================

describe('Event Binding Performance', () => {
  bench('WC - querySelectorAll + addEventListener (in Shadow DOM)', () => {
    const c = document.createElement('div');
    document.body.appendChild(c);
    const el = document.createElement('div');
    const shadow = el.attachShadow({ mode: 'open' });
    shadow.innerHTML = `
      <button data-on-click="a">A</button>
      <button data-on-click="b">B</button>
      <button data-on-click="c">C</button>
      <button data-on-click="d">D</button>
      <button data-on-click="e">E</button>
    `;
    c.appendChild(el);

    const buttons = shadow.querySelectorAll('[data-on-click]');
    buttons.forEach((btn) => {
      btn.addEventListener('click', () => {});
    });

    document.body.removeChild(c);
  });

  bench('Plain DOM - querySelectorAll + addEventListener', () => {
    const c = document.createElement('div');
    document.body.appendChild(c);
    const el = document.createElement('div');
    el.innerHTML = `
      <button data-action="a">A</button>
      <button data-action="b">B</button>
      <button data-action="c">C</button>
      <button data-action="d">D</button>
      <button data-action="e">E</button>
    `;
    c.appendChild(el);

    const buttons = el.querySelectorAll('[data-action]');
    buttons.forEach((btn) => {
      btn.addEventListener('click', () => {});
    });

    document.body.removeChild(c);
  });

  bench('Event delegation (single listener)', () => {
    const c = document.createElement('div');
    document.body.appendChild(c);
    const el = document.createElement('div');
    el.innerHTML = `
      <button data-action="a">A</button>
      <button data-action="b">B</button>
      <button data-action="c">C</button>
      <button data-action="d">D</button>
      <button data-action="e">E</button>
    `;
    c.appendChild(el);

    el.addEventListener('click', (e) => {
      const target = e.target as HTMLElement;
      const action = target.dataset.action;
      if (action) {
        // handle action
      }
    });

    document.body.removeChild(c);
  });
});

// ============================================
// Hydration Simulation
// ============================================

describe('Hydration Performance', () => {
  bench('WC - Full hydration (5 components)', () => {
    const c = document.createElement('div');
    document.body.appendChild(c);

    c.innerHTML = `
      ${Array.from({ length: 5 }, (_, i) => `
        <div class="item-${i}">
          <template shadowrootmode="open">
            <style>:host { display: block; }</style>
            <div class="count">${i}</div>
            <button data-on-click="inc">+</button>
          </template>
        </div>
      `).join('')}
    `;

    c.querySelectorAll('[class^="item-"]').forEach((el) => {
      const shadow = (el as HTMLElement).shadowRoot;
      if (shadow) {
        shadow.querySelectorAll('[data-on-click]').forEach((btn) => {
          btn.addEventListener('click', () => {});
        });
      }
    });

    document.body.removeChild(c);
  });

  bench('Plain DOM - Hydration (5 components)', () => {
    const c = document.createElement('div');
    document.body.appendChild(c);

    c.innerHTML = `
      ${Array.from({ length: 5 }, (_, i) => `
        <div class="item item-${i}">
          <style>.item { display: block; }</style>
          <div class="count">${i}</div>
          <button data-action="inc">+</button>
        </div>
      `).join('')}
    `;

    c.querySelectorAll('.item').forEach((el) => {
      el.querySelectorAll('[data-action]').forEach((btn) => {
        btn.addEventListener('click', () => {});
      });
    });

    document.body.removeChild(c);
  });

  bench('DOM Parts - Hydration with parts (5 components)', () => {
    const c = document.createElement('div');
    document.body.appendChild(c);

    c.innerHTML = `
      ${Array.from({ length: 5 }, (_, i) => `
        <div class="item item-${i}">
          <div class="count"><!--{{count${i}}}-->${i}<!--/{{count${i}}}--></div>
          <button data-action="inc">+</button>
        </div>
      `).join('')}
    `;

    const parts = hydratePartsFromElement(c);

    c.querySelectorAll('.item').forEach((el) => {
      el.querySelectorAll('[data-action]').forEach((btn) => {
        btn.addEventListener('click', () => {});
      });
    });

    if (parts.size === 0) {
      throw new Error('No parts found');
    }

    document.body.removeChild(c);
  });
});

// ============================================
// Memory / GC Related (approximate)
// ============================================

describe('Style Handling Performance', () => {
  bench('Inline styles (10 components)', () => {
    const c = document.createElement('div');
    document.body.appendChild(c);

    const styles = ':host { display: block; padding: 8px; margin: 4px; }';
    c.innerHTML = Array.from({ length: 10 }, (_, i) => `
      <div class="item-${i}">
        <template shadowrootmode="open">
          <style>${styles}</style>
          <div>Content ${i}</div>
        </template>
      </div>
    `).join('');

    document.body.removeChild(c);
  });

  bench('Adoptable Stylesheets (10 components)', () => {
    const c = document.createElement('div');
    document.body.appendChild(c);

    const sheet = new CSSStyleSheet();
    sheet.replaceSync(':host { display: block; padding: 8px; margin: 4px; }');

    for (let i = 0; i < 10; i++) {
      const el = document.createElement('div');
      const shadow = el.attachShadow({ mode: 'open' });
      shadow.adoptedStyleSheets = [sheet];
      shadow.innerHTML = `<div>Content ${i}</div>`;
      c.appendChild(el);
    }

    document.body.removeChild(c);
  });
});
