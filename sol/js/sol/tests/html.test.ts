import { describe, it, expect } from 'vitest';
import {
  h,
  text,
  fragment,
  renderToString,
  escapeHtml,
  raw,
  div,
  span,
  h1,
  h2,
  p,
  a,
  ul,
  li,
  input,
  br,
  hr,
  img,
} from '../html';

describe('html helpers', () => {
  describe('h()', () => {
    it('creates an element node', () => {
      const node = h('div', { class: 'foo' }, []);
      expect(node).toEqual({
        tag: 'div',
        attrs: { class: 'foo' },
        children: [],
      });
    });

    it('handles null attrs', () => {
      const node = h('span', null, []);
      expect(node.attrs).toEqual({});
    });

    it('accepts children', () => {
      const node = h('div', null, ['hello', h('span', null, ['world'])]);
      expect(node.children).toHaveLength(2);
      expect(node.children[0]).toBe('hello');
    });
  });

  describe('text()', () => {
    it('converts string to string', () => {
      expect(text('hello')).toBe('hello');
    });

    it('converts number to string', () => {
      expect(text(42)).toBe('42');
    });
  });

  describe('fragment()', () => {
    it('returns the array as-is', () => {
      const children = ['a', 'b', 'c'];
      expect(fragment(children)).toBe(children);
    });
  });

  describe('escapeHtml()', () => {
    it('escapes special characters', () => {
      expect(escapeHtml('<div>')).toBe('&lt;div&gt;');
      expect(escapeHtml('"quoted"')).toBe('&quot;quoted&quot;');
      expect(escapeHtml("it's")).toBe('it&#39;s');
      expect(escapeHtml('a & b')).toBe('a &amp; b');
    });

    it('handles empty string', () => {
      expect(escapeHtml('')).toBe('');
    });
  });

  describe('renderToString()', () => {
    it('renders text nodes with escaping', () => {
      expect(renderToString('<script>')).toBe('&lt;script&gt;');
    });

    it('renders simple element', () => {
      const node = div(null, []);
      expect(renderToString(node)).toBe('<div></div>');
    });

    it('renders element with attributes', () => {
      const node = div({ class: 'foo', id: 'bar' }, []);
      expect(renderToString(node)).toBe('<div class="foo" id="bar"></div>');
    });

    it('renders boolean attributes', () => {
      const node = input({ disabled: true, readonly: false });
      expect(renderToString(node)).toBe('<input disabled>');
    });

    it('renders nested elements', () => {
      const node = div(null, [
        h1(null, ['Title']),
        p(null, ['Content']),
      ]);
      expect(renderToString(node)).toBe(
        '<div><h1>Title</h1><p>Content</p></div>'
      );
    });

    it('renders void elements without closing tag', () => {
      expect(renderToString(br())).toBe('<br>');
      expect(renderToString(hr())).toBe('<hr>');
      expect(renderToString(img({ src: 'a.png', alt: 'test' }))).toBe(
        '<img src="a.png" alt="test">'
      );
    });

    it('escapes attribute values', () => {
      const node = div({ 'data-value': '<script>"alert"</script>' }, []);
      expect(renderToString(node)).toBe(
        '<div data-value="&lt;script&gt;&quot;alert&quot;&lt;/script&gt;"></div>'
      );
    });

    it('renders array of nodes', () => {
      const nodes = [span(null, ['a']), span(null, ['b'])];
      expect(renderToString(nodes)).toBe('<span>a</span><span>b</span>');
    });
  });

  describe('raw()', () => {
    it('creates a raw HTML node', () => {
      const node = raw('<b>bold</b>');
      expect(node.tag).toBe('__raw__');
      expect(node.attrs).toEqual({ html: '<b>bold</b>' });
    });
  });

  describe('tag helpers', () => {
    it('div() creates a div element', () => {
      expect(div({ class: 'container' }, ['text']).tag).toBe('div');
    });

    it('h1() creates an h1 element', () => {
      expect(h1(null, ['Title']).tag).toBe('h1');
    });

    it('a() creates an anchor element', () => {
      const node = a({ href: '/page' }, ['Link']);
      expect(node.tag).toBe('a');
      expect(node.attrs).toEqual({ href: '/page' });
    });

    it('ul/li creates list elements', () => {
      const list = ul(null, [
        li(null, ['Item 1']),
        li(null, ['Item 2']),
      ]);
      expect(list.tag).toBe('ul');
      expect(list.children).toHaveLength(2);
    });

    it('input creates void element', () => {
      const node = input({ type: 'text', name: 'email' });
      expect(node.tag).toBe('input');
      expect(node.children).toEqual([]);
    });
  });
});
