/**
 * Web Components SSR Framework v2
 *
 * CSS配信戦略を選択可能にした設計
 */

// ============================================
// CSS Strategy Types
// ============================================

/**
 * @typedef {'inline' | 'link' | 'link-preload' | 'adoptable'} CSSStrategy
 *
 * inline:       Shadow DOM内にインラインCSS
 *               - 自己完結、外部配信向き
 *               - コンポーネントごとに重複
 *
 * link:         Shadow DOM内に<link rel="stylesheet">
 *               - ブラウザキャッシュ効く
 *               - レンダリングブロッキング
 *
 * link-preload: <head>にpreload + Shadow内はlink
 *               - 並列ロード、ブロッキング軽減
 *               - 親ページのコントロールが必要
 *
 * adoptable:    SSR時はインライン、Hydration時にAdoptable Sheets
 *               - 最もメモリ効率が良い
 *               - Hydration必須
 */

// ============================================
// 1. コンポーネント定義
// ============================================

/**
 * @typedef {Object} ComponentDef
 * @property {string} name - カスタム要素名
 * @property {string} styles - CSS文字列
 * @property {string} [stylesUrl] - 外部CSSのURL (link/link-preload用)
 * @property {function} render - テンプレート関数
 * @property {Object} initialState - 初期状態
 * @property {Object} handlers - イベントハンドラ
 */

function defineComponent(options) {
  return {
    ...options,
    serialize: options.serialize || JSON.stringify,
    deserialize: options.deserialize || JSON.parse,
  };
}

// ============================================
// 2. サーバーサイド API
// ============================================

/**
 * SSRレンダラーを作成
 * @param {Object} options
 * @param {CSSStrategy} options.cssStrategy - CSS配信戦略
 * @param {string} [options.baseUrl] - CSSのベースURL
 */
function createSSRRenderer(options = {}) {
  const {
    cssStrategy = 'inline',
    baseUrl = '',
  } = options;

  // preload用のCSS URLを収集
  const collectedStyleUrls = new Set();

  /**
   * コンポーネントをHTML文字列に変換
   */
  function renderToString(component, state, children = '') {
    const { name, styles, stylesUrl, render, serialize } = component;
    const serializedState = escapeAttr(serialize(state));
    const html = render(state, () => {});

    // CSS出力を戦略に応じて変更
    let styleOutput = '';

    switch (cssStrategy) {
      case 'inline':
        styleOutput = `<style>${styles}</style>`;
        break;

      case 'link':
        if (stylesUrl) {
          styleOutput = `<link rel="stylesheet" href="${baseUrl}${stylesUrl}">`;
        } else {
          styleOutput = `<style>${styles}</style>`;
        }
        break;

      case 'link-preload':
        if (stylesUrl) {
          collectedStyleUrls.add(`${baseUrl}${stylesUrl}`);
          styleOutput = `<link rel="stylesheet" href="${baseUrl}${stylesUrl}">`;
        } else {
          styleOutput = `<style>${styles}</style>`;
        }
        break;

      case 'adoptable':
        // Hydration時にJSで適用するため、最小限のスタイルのみ
        // FOUCを防ぐための critical CSS をインラインで出力
        styleOutput = `<style>:host{display:block}</style>`;
        break;
    }

    return `<${name} data-state="${serializedState}" data-css-strategy="${cssStrategy}">
  <template shadowrootmode="open">
    ${styleOutput}
    ${html}
  </template>
  ${children}
</${name}>`;
  }

  /**
   * 収集したCSSのpreloadタグを生成
   * link-preload戦略の場合、<head>に挿入する
   */
  function getPreloadTags() {
    if (cssStrategy !== 'link-preload') return '';

    return Array.from(collectedStyleUrls)
      .map(url => `<link rel="preload" href="${url}" as="style">`)
      .join('\n');
  }

  /**
   * 収集をリセット
   */
  function reset() {
    collectedStyleUrls.clear();
  }

  return {
    renderToString,
    getPreloadTags,
    reset,
  };
}

/**
 * 完全なHTMLドキュメントを生成
 */
function renderDocument(options) {
  const {
    title = '',
    head = '',
    body = '',
    preloadTags = '',
    scripts = [],
  } = options;

  return `<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escapeHtml(title)}</title>
  ${preloadTags}
  ${head}
</head>
<body>
  ${body}
  ${scripts.map(src => `<script src="${src}"></script>`).join('\n  ')}
</body>
</html>`;
}

// ============================================
// 3. クライアントサイド API
// ============================================

/**
 * Adoptable Stylesheets用のキャッシュ
 */
const sheetCache = new Map();

/**
 * CSSStyleSheetを取得または作成
 */
function getOrCreateStyleSheet(key, css) {
  if (sheetCache.has(key)) {
    return sheetCache.get(key);
  }
  const sheet = new CSSStyleSheet();
  sheet.replaceSync(css);
  sheetCache.set(key, sheet);
  return sheet;
}

/**
 * コンポーネントをカスタム要素として登録
 */
function registerComponent(component) {
  const { name, styles, render, initialState, handlers, deserialize } = component;

  class ComponentElement extends HTMLElement {
    constructor() {
      super();
      this._isSSR = !!this.shadowRoot;
      this._cssStrategy = this.dataset.cssStrategy || 'inline';

      if (!this._isSSR) {
        this.attachShadow({ mode: 'open' });
      }

      // 状態の復元
      if (this.dataset.state) {
        try {
          this._state = deserialize(this.dataset.state);
        } catch (e) {
          this._state = { ...initialState };
        }
      } else {
        this._state = { ...initialState };
      }
    }

    connectedCallback() {
      // Adoptable Stylesheets戦略の場合、スタイルを適用
      if (this._cssStrategy === 'adoptable') {
        const sheet = getOrCreateStyleSheet(name, styles);
        this.shadowRoot.adoptedStyleSheets = [sheet];
      }

      if (this._isSSR) {
        this._hydrate();
      } else {
        this._render();
      }
    }

    _hydrate() {
      this._attachEventListeners();
    }

    _render() {
      const html = render(this._state, this._emit.bind(this));

      // CSR時のスタイル出力
      let styleHtml = '';
      if (this._cssStrategy !== 'adoptable') {
        styleHtml = `<style>${styles}</style>`;
      }

      this.shadowRoot.innerHTML = `${styleHtml}${html}`;
      this._attachEventListeners();
    }

    _setState(newState) {
      this._state = newState;
      this.dataset.state = component.serialize(newState);
      this._render();
    }

    _emit(eventName, event) {
      if (handlers && handlers[eventName]) {
        const newState = handlers[eventName](this._state, event);
        if (newState !== this._state) {
          this._setState(newState);
        }
      }
    }

    _attachEventListeners() {
      // data-on-* 属性を探索
      const eventTypes = ['click', 'input', 'change', 'keypress', 'submit'];
      eventTypes.forEach(type => {
        const attr = `data-on-${type}`;
        this.shadowRoot.querySelectorAll(`[${attr}]`).forEach(el => {
          const handlerName = el.getAttribute(attr);
          el.addEventListener(type, (e) => this._emit(handlerName, e));
        });
      });
    }
  }

  customElements.define(name, ComponentElement);
  return ComponentElement;
}

// ============================================
// 4. ユーティリティ
// ============================================

function escapeAttr(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function escapeHtml(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

// ============================================
// 5. 使用例
// ============================================

const Counter = defineComponent({
  name: 'x-counter',
  stylesUrl: 'components/counter.css',  // 外部CSS (link戦略用)
  styles: `
    :host { display: block; padding: 16px; border: 2px solid #4a90d9; border-radius: 8px; }
    .display { font-size: 2rem; text-align: center; margin: 10px 0; }
    .buttons { display: flex; gap: 10px; justify-content: center; }
    button { padding: 8px 20px; font-size: 1.2rem; border: none; border-radius: 4px; cursor: pointer; }
    .dec { background: #ff6b6b; color: white; }
    .inc { background: #51cf66; color: white; }
  `,
  initialState: { count: 0 },
  render(state) {
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
// Export
// ============================================

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    defineComponent,
    createSSRRenderer,
    renderDocument,
    escapeHtml,
    escapeAttr,
    Counter,
  };
} else if (typeof window !== 'undefined') {
  window.WCFramework = {
    defineComponent,
    registerComponent,
    getOrCreateStyleSheet,
    escapeHtml,
    escapeAttr,
    Counter,
  };
}
