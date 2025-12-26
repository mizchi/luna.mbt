/**
 * Web Component definition - wraps luna-wcr with additional utilities
 */

import {
  defineComponent as baseDefineComponent,
  register as baseRegister,
  type ComponentDef as BaseComponentDef,
  type AttrDef,
  type AttrType,
  type Context,
  type SignalProps,
} from '@mizchi/luna-wcr';

export type { AttrDef, AttrType, Context, SignalProps };

export interface ComponentDef<P extends Record<string, unknown>>
  extends BaseComponentDef<P> {
  // Future: additional stella-specific options
}

/**
 * Define a Web Component class
 */
export function defineComponent<P extends Record<string, unknown>>(
  def: ComponentDef<P>
): typeof HTMLElement {
  return baseDefineComponent(def);
}

/**
 * Define and register a Web Component
 */
export function register<P extends Record<string, unknown>>(
  def: ComponentDef<P>
): void {
  baseRegister(def);
}
