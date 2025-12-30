/**
 * Signal interface for reactive bindings
 */
export interface Signal<T> {
  get(): T;
  set(value: T): void;
  update(fn: (value: T) => T): void;
  subscribe(fn: (value: T) => void): () => void;
}

/**
 * Base props for all Shoelace components
 */
export interface BaseProps {
  className?: string;
}

/**
 * Size variants
 */
export type Size = 'small' | 'medium' | 'large';

/**
 * Button variants
 */
export type ButtonVariant = 'default' | 'primary' | 'success' | 'neutral' | 'warning' | 'danger';

/**
 * Input types
 */
export type InputType = 'text' | 'email' | 'password' | 'number' | 'tel' | 'url' | 'search' | 'date';
