/**
 * DOM Parts Polyfill
 *
 * WICG DOM Parts 仕様に基づいた実装
 * https://github.com/WICG/webcomponents/blob/gh-pages/proposals/DOM-Parts-Imperative.md
 *
 * ブラウザネイティブ実装が利用可能になったら置き換え可能な設計
 */

// ============================================
// Part Base Interface
// ============================================

/**
 * Part の基底インターフェース
 * value を設定し、commit() で DOM に反映
 */
export interface Part {
  value: unknown;
  commit(): void;
}

// ============================================
// NodePart
// ============================================

/**
 * 単一ノードを表す Part
 */
export class NodePart implements Part {
  private _node: Node;
  private _value: unknown;
  private _committed: unknown;

  constructor(node: Node) {
    this._node = node;
    this._value = node.textContent;
    this._committed = this._value;
  }

  get node(): Node {
    return this._node;
  }

  get value(): unknown {
    return this._value;
  }

  set value(v: unknown) {
    this._value = v;
  }

  commit(): void {
    if (this._value !== this._committed) {
      this._node.textContent = String(this._value ?? '');
      this._committed = this._value;
    }
  }
}

// ============================================
// AttributePart
// ============================================

/**
 * 要素の属性を表す Part
 */
export class AttributePart implements Part {
  private _element: Element;
  private _qualifiedName: string;
  private _namespace: string | null;
  private _value: unknown;
  private _committed: unknown;

  constructor(element: Element, qualifiedName: string, namespace?: string | null) {
    this._element = element;
    this._qualifiedName = qualifiedName;
    this._namespace = namespace ?? null;
    this._value = element.getAttribute(qualifiedName);
    this._committed = this._value;
  }

  get element(): Element {
    return this._element;
  }

  get localName(): string {
    const colonIndex = this._qualifiedName.indexOf(':');
    return colonIndex >= 0 ? this._qualifiedName.slice(colonIndex + 1) : this._qualifiedName;
  }

  get prefix(): string | null {
    const colonIndex = this._qualifiedName.indexOf(':');
    return colonIndex >= 0 ? this._qualifiedName.slice(0, colonIndex) : null;
  }

  get namespaceURI(): string | null {
    return this._namespace;
  }

  get value(): unknown {
    return this._value;
  }

  set value(v: unknown) {
    this._value = v;
  }

  commit(): void {
    if (this._value !== this._committed) {
      if (this._value == null || this._value === false) {
        if (this._namespace) {
          this._element.removeAttributeNS(this._namespace, this.localName);
        } else {
          this._element.removeAttribute(this._qualifiedName);
        }
      } else {
        const strValue = this._value === true ? '' : String(this._value);
        if (this._namespace) {
          this._element.setAttributeNS(this._namespace, this._qualifiedName, strValue);
        } else {
          this._element.setAttribute(this._qualifiedName, strValue);
        }
      }
      this._committed = this._value;
    }
  }
}

// ============================================
// ChildNodePart
// ============================================

/**
 * 子ノードの範囲を表す Part
 * previousSibling と nextSibling の間のノードを管理
 */
export class ChildNodePart implements Part {
  private _parent: Node;
  private _startMarker: Comment;
  private _endMarker: Comment;
  private _value: unknown;
  private _committed: unknown;

  constructor(parent: Node, previousSibling?: Node | null, nextSibling?: Node | null) {
    this._parent = parent;

    // マーカーコメントを作成（DOM Parts 仕様では境界ノードを使用）
    this._startMarker = document.createComment('');
    this._endMarker = document.createComment('');

    if (previousSibling) {
      parent.insertBefore(this._startMarker, previousSibling.nextSibling);
    } else if (nextSibling) {
      parent.insertBefore(this._startMarker, nextSibling);
    } else {
      parent.appendChild(this._startMarker);
    }

    if (nextSibling) {
      parent.insertBefore(this._endMarker, nextSibling);
    } else {
      parent.appendChild(this._endMarker);
    }

    this._value = this.getCurrentContent();
    this._committed = this._value;
  }

  get previousSibling(): Comment {
    return this._startMarker;
  }

  get nextSibling(): Comment {
    return this._endMarker;
  }

  get value(): unknown {
    return this._value;
  }

  set value(v: unknown) {
    this._value = v;
  }

  /**
   * 現在のマーカー間のコンテンツを取得
   */
  private getCurrentContent(): DocumentFragment {
    const fragment = document.createDocumentFragment();
    let node = this._startMarker.nextSibling;
    while (node && node !== this._endMarker) {
      const next = node.nextSibling;
      fragment.appendChild(node.cloneNode(true));
      node = next;
    }
    return fragment;
  }

  /**
   * マーカー間のノードを削除
   */
  private clearContent(): void {
    let node = this._startMarker.nextSibling;
    while (node && node !== this._endMarker) {
      const next = node.nextSibling;
      this._parent.removeChild(node);
      node = next;
    }
  }

  commit(): void {
    if (this._value === this._committed) return;

    this.clearContent();

    if (this._value == null) {
      // null/undefined は空にする
    } else if (this._value instanceof Node) {
      this._parent.insertBefore(this._value, this._endMarker);
    } else if (this._value instanceof DocumentFragment) {
      this._parent.insertBefore(this._value, this._endMarker);
    } else if (Array.isArray(this._value)) {
      for (const item of this._value) {
        if (item instanceof Node) {
          this._parent.insertBefore(item, this._endMarker);
        } else {
          this._parent.insertBefore(document.createTextNode(String(item)), this._endMarker);
        }
      }
    } else {
      // 文字列やプリミティブ
      this._parent.insertBefore(document.createTextNode(String(this._value)), this._endMarker);
    }

    this._committed = this._value;
  }
}

// ============================================
// PropertyPart (Extension)
// ============================================

/**
 * 要素のプロパティを表す Part
 * DOM Parts 仕様の拡張提案
 */
export class PropertyPart implements Part {
  private _element: Element;
  private _propertyName: string;
  private _value: unknown;
  private _committed: unknown;

  constructor(element: Element, propertyName: string) {
    this._element = element;
    this._propertyName = propertyName;
    this._value = (element as any)[propertyName];
    this._committed = this._value;
  }

  get element(): Element {
    return this._element;
  }

  get propertyName(): string {
    return this._propertyName;
  }

  get value(): unknown {
    return this._value;
  }

  set value(v: unknown) {
    this._value = v;
  }

  commit(): void {
    if (this._value !== this._committed) {
      (this._element as any)[this._propertyName] = this._value;
      this._committed = this._value;
    }
  }
}

// ============================================
// PartGroup
// ============================================

/**
 * 複数の Part をまとめて commit
 */
export class PartGroup {
  private _parts: Part[];

  constructor(parts: Part[] = []) {
    this._parts = parts;
  }

  get parts(): readonly Part[] {
    return this._parts;
  }

  add(part: Part): void {
    this._parts.push(part);
  }

  remove(part: Part): boolean {
    const index = this._parts.indexOf(part);
    if (index >= 0) {
      this._parts.splice(index, 1);
      return true;
    }
    return false;
  }

  commit(): void {
    for (const part of this._parts) {
      part.commit();
    }
  }
}

// ============================================
// Template Part Parsing (Declarative)
// ============================================

/**
 * テンプレートから Part 位置を解析
 * {{name}} 形式のプレースホルダーを検出
 */
export interface ParsedPart {
  type: 'text' | 'attribute';
  name: string;
  path: number[]; // ノードへのパス
  attributeName?: string; // attribute の場合
}

/**
 * テンプレート HTML を解析して Part 情報を抽出
 */
export function parseTemplate(html: string): {
  html: string;
  parts: ParsedPart[];
} {
  const parts: ParsedPart[] = [];

  // 属性内の {{}} を検出
  const attrPattern = /(\w+(?:-\w+)*)="([^"]*\{\{(\w+)(?:\s+[^}]*)?\}\}[^"]*)"/g;

  let processedHtml = html;
  let match: RegExpExecArray | null;

  // 属性パターンを処理
  const attrMatches: Array<{ attr: string; name: string; placeholder: string }> = [];
  while ((match = attrPattern.exec(html)) !== null) {
    const [, attrName, , partName] = match;
    attrMatches.push({
      attr: attrName,
      name: partName,
      placeholder: match[0],
    });
  }

  // テキストノード内の {{}} をコメントマーカーに置換
  processedHtml = processedHtml.replace(
    />([^<]*)\{\{(\w+)(?:\s+[^}]*)?\}\}([^<]*)</g,
    (_, before, name, after) => {
      parts.push({
        type: 'text',
        name,
        path: [], // パスは後で計算
      });
      return `>${before}<!--{{${name}}}--><!--/{{${name}}}-->${after}<`;
    }
  );

  return { html: processedHtml, parts };
}

// ============================================
// Hydration with Parts
// ============================================

/**
 * SSR された HTML から Part を復元
 * コメントマーカー <!--{{name}}--> を検出
 */
export function hydratePartsFromElement(root: Element | ShadowRoot): Map<string, Part> {
  const parts = new Map<string, Part>();

  // コメントマーカーを検索
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_COMMENT);
  const startMarkers: Comment[] = [];

  let node: Comment | null;
  while ((node = walker.nextNode() as Comment | null)) {
    if (node.data.startsWith('{{') && !node.data.startsWith('/{{')) {
      startMarkers.push(node);
    }
  }

  for (const startMarker of startMarkers) {
    const name = startMarker.data.slice(2, -2); // {{name}} -> name
    const endMarker = startMarker.nextSibling?.nextSibling;

    if (endMarker && endMarker.nodeType === Node.COMMENT_NODE) {
      const parent = startMarker.parentNode;
      if (parent) {
        // ChildNodePart 相当を作成
        const part = new ChildNodePartFromMarkers(parent, startMarker, endMarker as Comment);
        parts.set(name, part);
      }
    }
  }

  // data-part-* 属性を検索
  const attrElements = root.querySelectorAll('[data-part]');
  attrElements.forEach((el) => {
    const partDefs = el.getAttribute('data-part');
    if (partDefs) {
      // "attr:name,attr2:name2" 形式
      const defs = partDefs.split(',');
      for (const def of defs) {
        const [attrName, partName] = def.split(':');
        if (attrName && partName) {
          parts.set(partName, new AttributePart(el, attrName));
        }
      }
    }
  });

  return parts;
}

/**
 * 既存マーカーから ChildNodePart を作成
 */
class ChildNodePartFromMarkers implements Part {
  private _parent: Node;
  private _startMarker: Comment;
  private _endMarker: Comment;
  private _value: unknown;
  private _committed: unknown;

  constructor(parent: Node, startMarker: Comment, endMarker: Comment) {
    this._parent = parent;
    this._startMarker = startMarker;
    this._endMarker = endMarker;
    this._value = this.getCurrentTextContent();
    this._committed = this._value;
  }

  get previousSibling(): Comment {
    return this._startMarker;
  }

  get nextSibling(): Comment {
    return this._endMarker;
  }

  get value(): unknown {
    return this._value;
  }

  set value(v: unknown) {
    this._value = v;
  }

  private getCurrentTextContent(): string {
    let text = '';
    let node = this._startMarker.nextSibling;
    while (node && node !== this._endMarker) {
      if (node.nodeType === Node.TEXT_NODE) {
        text += node.textContent;
      }
      node = node.nextSibling;
    }
    return text;
  }

  private clearContent(): void {
    let node = this._startMarker.nextSibling;
    while (node && node !== this._endMarker) {
      const next = node.nextSibling;
      this._parent.removeChild(node);
      node = next;
    }
  }

  commit(): void {
    if (this._value === this._committed) return;

    this.clearContent();

    if (this._value == null) {
      // empty
    } else if (this._value instanceof Node) {
      this._parent.insertBefore(this._value, this._endMarker);
    } else {
      this._parent.insertBefore(document.createTextNode(String(this._value)), this._endMarker);
    }

    this._committed = this._value;
  }
}

// Part interface is already exported at line 18
