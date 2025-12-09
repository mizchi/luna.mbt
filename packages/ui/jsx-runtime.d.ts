/**
 * JSX Runtime types for @mizchi/ui
 */

import type { Node, AttrValue } from "./dom";

export namespace JSX {
  type Element = Node;

  interface IntrinsicElements {
    // Block elements
    div: HTMLAttributes;
    p: HTMLAttributes;
    form: HTMLAttributes & FormAttributes;

    // Heading elements
    h1: HTMLAttributes;
    h2: HTMLAttributes;
    h3: HTMLAttributes;

    // List elements
    ul: HTMLAttributes;
    ol: HTMLAttributes;
    li: HTMLAttributes;

    // Inline elements
    span: HTMLAttributes;
    a: HTMLAttributes & AnchorAttributes;
    button: HTMLAttributes & ButtonAttributes;
    label: HTMLAttributes & LabelAttributes;

    // Form elements
    input: HTMLAttributes & InputAttributes;
    textarea: HTMLAttributes & TextareaAttributes;

    // Media elements
    img: HTMLAttributes & ImageAttributes;

    // Other elements
    br: {};
    hr: HTMLAttributes;
  }

  interface HTMLAttributes {
    // Core attributes
    id?: string;
    className?: string | (() => string);
    class?: string | (() => string);
    style?: Record<string, string> | (() => [string, string][]);

    // Event handlers
    onClick?: (event: MouseEvent) => void;
    onInput?: (event: InputEvent) => void;
    onChange?: (event: Event) => void;
    onSubmit?: (event: Event) => void;
    onKeyDown?: (event: KeyboardEvent) => void;
    onKeyUp?: (event: KeyboardEvent) => void;
    onFocus?: (event: FocusEvent) => void;
    onBlur?: (event: FocusEvent) => void;
    onMouseEnter?: (event: MouseEvent) => void;
    onMouseLeave?: (event: MouseEvent) => void;

    // Children
    children?: Node | Node[] | string | number | (Node | string | number)[];

    // Allow any other attributes
    [key: string]: unknown;
  }

  interface InputAttributes {
    type?: string;
    placeholder?: string;
    value?: string | (() => string);
    disabled?: boolean | (() => boolean);
  }

  interface TextareaAttributes {
    placeholder?: string;
    value?: string | (() => string);
    disabled?: boolean | (() => boolean);
  }

  interface AnchorAttributes {
    href?: string;
  }

  interface ImageAttributes {
    src?: string;
    alt?: string;
  }

  interface ButtonAttributes {
    type?: string;
    disabled?: boolean | (() => boolean);
  }

  interface FormAttributes {
    action?: string;
    method?: string;
  }

  interface LabelAttributes {
    htmlFor?: string;
  }

  interface ElementChildrenAttribute {
    children: {};
  }
}

export function jsx(
  type: string | ((props: any) => Node),
  props: Record<string, unknown> | null
): Node;

export function jsxs(
  type: string | ((props: any) => Node),
  props: Record<string, unknown> | null
): Node;

export function Fragment(props: { children?: Node | Node[] }): Node[];

export const jsxDEV: typeof jsx;
