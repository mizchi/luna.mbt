/**
 * Web Components SSR Framework - 設計案
 *
 * サーバー/クライアント両方で動作する統一的なコンポーネント定義と
 * SSR/Hydrationのための抽象化レイヤー
 */

// ============================================
// 1. コンポーネント定義API
// ============================================

/**
 * コンポーネントを定義する
 * @template S - 状態の型
 * @param {Object} options
 * @param {string} options.name - カスタム要素のタグ名
 * @param {string} options.styles - Scoped CSS
 * @param {(state: S, emit: Function) => string} options.render - テンプレート関数
 * @param {S} options.initialState - 初期状態
 * @param {Object.<string, (state: S, event: Event) => S>} options.handlers - イベントハンドラ
 * @param {(state: S) => string} options.serialize - 状態のシリアライズ
 * @param {(str: string) => S} options.deserialize - 状態のデシリアライズ
 */
function defineComponent(options) {
  return {
    ...options,
    // デフォルトのシリアライザ
    serialize: options.serialize || JSON.stringify,
    deserialize: options.deserialize || JSON.parse,
  };
}

// ============================================
// 2. サーバーサイドAPI (SSR)
// ============================================

/**
 * コンポーネントをSSR用HTML文字列に変換
 * @param {Object} component - defineComponent()の戻り値
 * @param {Object} state - 初期状態
 * @param {string} [children] - Light DOMコンテンツ (slots用)
 * @returns {string} HTML文字列
 */
function renderToString(component, state, children = '') {
  const { name, styles, render, serialize } = component;

  // 状態をシリアライズ
  const serializedState = escapeAttr(serialize(state));

  // テンプレートをレンダリング (emit はSSR時は何もしない)
  const html = render(state, () => { });

  return `<${name} data-state="${serializedState}">
  <template shadowrootmode="open">
    <style>${styles}</style>
    ${html}
  </template>
  ${children}
</${name}>`;
}

/**
 * HTML属性用エスケープ
 */
function escapeAttr(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

/**
 * HTMLコンテンツ用エスケープ
 */
function escapeHtml(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

// ============================================
// 3. クライアントサイドAPI (Hydration)
// ============================================

/**
 * コンポーネントをカスタム要素として登録
 * @param {Object} component - defineComponent()の戻り値
 */
function registerComponent(component) {
  const { name, styles, render, initialState, handlers, deserialize } = component;

  class ComponentElement extends HTMLElement {
    constructor() {
      super();

      // Declarative Shadow DOMが既にあるかチェック
      this._isSSR = !!this.shadowRoot;

      if (!this._isSSR) {
        // CSR: Shadow DOMを作成
        this.attachShadow({ mode: 'open' });
      }

      // 状態の復元
      if (this.dataset.state) {
        try {
          this._state = deserialize(this.dataset.state);
        } catch (e) {
          console.warn(`[${name}] Failed to deserialize state:`, e);
          this._state = { ...initialState };
        }
      } else {
        this._state = { ...initialState };
      }
    }

    connectedCallback() {
      if (this._isSSR) {
        // SSR: Hydration (イベントリスナーを接続)
        this._hydrate();
      } else {
        // CSR: 初回レンダリング
        this._render();
      }
    }

    /**
     * Hydration: SSR済みDOMにイベントリスナーを接続
     */
    _hydrate() {
      this._attachEventListeners();
      console.log(`[${name}] Hydrated with state:`, this._state);
    }

    /**
     * CSR: DOMを生成
     */
    _render() {
      const html = render(this._state, this._emit.bind(this));
      this.shadowRoot.innerHTML = `<style>${styles}</style>${html}`;
      this._attachEventListeners();
    }

    /**
     * 状態を更新して再レンダリング
     */
    _setState(newState) {
      this._state = newState;
      // data属性も更新（状態の永続化）
      this.dataset.state = component.serialize(newState);
      this._render();
    }

    /**
     * イベントを発行（ハンドラを呼び出す）
     */
    _emit(eventName, event) {
      if (handlers && handlers[eventName]) {
        const newState = handlers[eventName](this._state, event);
        if (newState !== this._state) {
          this._setState(newState);
        }
      }
    }

    /**
     * data-on-* 属性を持つ要素にイベントリスナーを接続
     */
    _attachEventListeners() {
      // data-on-click, data-on-input などを探索
      const elements = this.shadowRoot.querySelectorAll('[data-on-click]');
      elements.forEach(el => {
        const handlerName = el.dataset.onClick;
        el.addEventListener('click', (e) => this._emit(handlerName, e));
      });

      const inputElements = this.shadowRoot.querySelectorAll('[data-on-input]');
      inputElements.forEach(el => {
        const handlerName = el.dataset.onInput;
        el.addEventListener('input', (e) => this._emit(handlerName, e));
      });

      const keyElements = this.shadowRoot.querySelectorAll('[data-on-keypress]');
      keyElements.forEach(el => {
        const handlerName = el.dataset.onKeypress;
        el.addEventListener('keypress', (e) => this._emit(handlerName, e));
      });
    }
  }

  customElements.define(name, ComponentElement);
  return ComponentElement;
}

// ============================================
// 4. 使用例: カウンターコンポーネント
// ============================================

const Counter = defineComponent({
  name: 'my-counter',

  styles: `
    :host { display: block; padding: 16px; border: 2px solid #4a90d9; border-radius: 8px; }
    .display { font-size: 2rem; text-align: center; margin: 10px 0; }
    .buttons { display: flex; gap: 10px; justify-content: center; }
    button { padding: 8px 20px; font-size: 1.2rem; border: none; border-radius: 4px; cursor: pointer; }
    .dec { background: #ff6b6b; color: white; }
    .inc { background: #51cf66; color: white; }
  `,

  initialState: { count: 0 },

  render(state, emit) {
    return `
      <div class="display">Count: ${state.count}</div>
      <div class="buttons">
        <button class="dec" data-on-click="decrement">-</button>
        <button class="inc" data-on-click="increment">+</button>
      </div>
    `;
  },

  handlers: {
    decrement: (state) => ({ count: state.count - 1 }),
    increment: (state) => ({ count: state.count + 1 }),
  },
});

// ============================================
// 5. 使用例: TODOリストコンポーネント
// ============================================

const TodoList = defineComponent({
  name: 'my-todo',

  styles: `
    :host { display: block; }
    .add-form { display: flex; gap: 8px; margin-bottom: 12px; }
    input { flex: 1; padding: 8px; border: 1px solid #ddd; border-radius: 4px; }
    .add-btn { background: #4caf50; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer; }
    ul { list-style: none; padding: 0; margin: 0; }
    li { padding: 8px; border-bottom: 1px solid #eee; display: flex; justify-content: space-between; }
    .del-btn { background: #ff5252; color: white; border: none; padding: 4px 8px; border-radius: 4px; cursor: pointer; }
  `,

  initialState: { items: [], inputValue: '' },

  render(state, emit) {
    const itemsHtml = state.items.map((item, i) => `
      <li>
        <span>${escapeHtml(item)}</span>
        <button class="del-btn" data-on-click="delete" data-index="${i}">削除</button>
      </li>
    `).join('');

    return `
      <div class="add-form">
        <input type="text" placeholder="新しいタスク..." value="${escapeAttr(state.inputValue)}" data-on-input="updateInput" data-on-keypress="handleKeypress" />
        <button class="add-btn" data-on-click="add">追加</button>
      </div>
      <ul>${itemsHtml}</ul>
    `;
  },

  handlers: {
    updateInput: (state, e) => ({ ...state, inputValue: e.target.value }),
    add: (state) => {
      if (!state.inputValue.trim()) return state;
      return {
        items: [...state.items, state.inputValue.trim()],
        inputValue: ''
      };
    },
    handleKeypress: (state, e) => {
      if (e.key !== 'Enter' || !state.inputValue.trim()) return state;
      return {
        items: [...state.items, state.inputValue.trim()],
        inputValue: ''
      };
    },
    delete: (state, e) => {
      const index = parseInt(e.target.dataset.index, 10);
      return {
        ...state,
        items: state.items.filter((_, i) => i !== index)
      };
    },
  },
});

// ============================================
// Export (Node.js / Browser 両対応)
// ============================================

if (typeof module !== 'undefined' && module.exports) {
  // Node.js (SSR)
  module.exports = {
    defineComponent,
    renderToString,
    escapeHtml,
    escapeAttr,
    // Example components
    Counter,
    TodoList,
  };
} else if (typeof window !== 'undefined') {
  // Browser (Hydration)
  window.WCFramework = {
    defineComponent,
    registerComponent,
    renderToString,
    escapeHtml,
    escapeAttr,
    Counter,
    TodoList,
  };
}
