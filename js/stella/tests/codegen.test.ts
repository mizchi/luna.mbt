/**
 * Code generation tests
 */

import { describe, it, expect } from 'vitest';
import { generateComponentJS, type ComponentConfig } from '../src/codegen.js';

describe('generateComponentJS', () => {
  it('should generate basic component', () => {
    const config: ComponentConfig = {
      tag: 'x-test',
      module: './test.mbt.js',
      attributes: [
        { name: 'value', type: 'string', default: '' },
      ],
    };

    const js = generateComponentJS(config);

    expect(js).toContain('class XTest extends HTMLElement');
    expect(js).toContain("static observedAttributes = ['value']");
    expect(js).toContain("customElements.define('x-test', XTest)");
    expect(js).toContain("import * as mod from './test.mbt.js'");
  });

  it('should handle multiple attributes', () => {
    const config: ComponentConfig = {
      tag: 'x-counter',
      module: './counter.js',
      attributes: [
        { name: 'initial', type: 'int', default: 0 },
        { name: 'label', type: 'string', default: 'Count' },
        { name: 'disabled', type: 'bool', default: false },
      ],
    };

    const js = generateComponentJS(config);

    expect(js).toContain("static observedAttributes = ['initial', 'label', 'disabled']");
    expect(js).toContain('initial: new Signal(0)');
    expect(js).toContain("label: new Signal('Count')");
    expect(js).toContain('disabled: new Signal(false)');
  });

  it('should include styles when provided', () => {
    const config: ComponentConfig = {
      tag: 'x-styled',
      module: './styled.js',
      attributes: [],
      styles: ':host { display: block; }',
    };

    const js = generateComponentJS(config);

    expect(js).toContain('const sheet = new CSSStyleSheet()');
    expect(js).toContain(':host { display: block; }');
    expect(js).toContain('shadow.adoptedStyleSheets = [sheet]');
  });

  it('should handle no shadow DOM', () => {
    const config: ComponentConfig = {
      tag: 'x-light',
      module: './light.js',
      attributes: [],
      shadow: 'none',
    };

    const js = generateComponentJS(config);

    expect(js).toContain('const shadow = this;');
    expect(js).not.toContain('CSSStyleSheet');
  });

  it('should handle kebab-case attribute names', () => {
    const config: ComponentConfig = {
      tag: 'x-kebab',
      module: './kebab.js',
      attributes: [
        { name: 'my-value', type: 'string', default: '' },
      ],
    };

    const js = generateComponentJS(config);

    // Should convert to camelCase in JS
    expect(js).toContain('myValue: new Signal');
    expect(js).toContain("case 'my-value':");
  });

  it('should escape special characters in styles', () => {
    const config: ComponentConfig = {
      tag: 'x-escaped',
      module: './escaped.js',
      attributes: [],
      styles: ':host { content: "$test" }',
    };

    const js = generateComponentJS(config);

    // $ should be escaped in template literal
    expect(js).toContain('\\$test');
  });
});
