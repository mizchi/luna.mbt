/**
 * @mizchi/luna-wcr - Web Components Runtime for Luna UI
 */

export { Signal, effect } from './signal.js';
export {
  defineComponent,
  register,
  type AttrType,
  type AttrDef,
  type ComponentDef,
  type Context,
  type SignalProps,
} from './define.js';

// Attribute definition helpers
export function attrString(name: string, defaultValue = ''): AttrDef {
  return { name, type: 'string', default: defaultValue };
}

export function attrInt(name: string, defaultValue = 0): AttrDef {
  return { name, type: 'int', default: defaultValue };
}

export function attrFloat(name: string, defaultValue = 0): AttrDef {
  return { name, type: 'float', default: defaultValue };
}

export function attrBool(name: string, defaultValue = false): AttrDef {
  return { name, type: 'bool', default: defaultValue };
}

// Re-export types
import type { AttrDef } from './define.js';
