import { describe, it, expect, beforeEach } from 'vitest';
import { setupCard } from '../src/card';

describe('Card', () => {
  let el: HTMLDivElement;

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-card', '');

    const header = document.createElement('div');
    header.setAttribute('data-card-header', '');

    const title = document.createElement('h3');
    title.setAttribute('data-card-title', '');
    title.textContent = 'Card Title';
    header.appendChild(title);

    const content = document.createElement('div');
    content.setAttribute('data-card-content', '');
    content.textContent = 'Card content';

    el.appendChild(header);
    el.appendChild(content);
    document.body.appendChild(el);
  });

  it('should not modify non-clickable card', () => {
    const cleanup = setupCard(el);

    expect(el.hasAttribute('data-clickable')).toBe(false);
    expect(el.hasAttribute('tabindex')).toBe(false);
    expect(el.hasAttribute('role')).toBe(false);

    cleanup();
  });

  it('should not modify card without onClick', () => {
    const cleanup = setupCard(el, { clickable: true });

    expect(el.hasAttribute('data-clickable')).toBe(false);

    cleanup();
  });

  it('should make card clickable with onClick', () => {
    const clicks: number[] = [];
    const cleanup = setupCard(el, {
      clickable: true,
      onClick: () => clicks.push(1),
    });

    expect(el.getAttribute('data-clickable')).toBe('true');
    expect(el.getAttribute('tabindex')).toBe('0');
    expect(el.getAttribute('role')).toBe('button');

    cleanup();
  });

  it('should handle click events', () => {
    const clicks: number[] = [];
    const cleanup = setupCard(el, {
      clickable: true,
      onClick: () => clicks.push(1),
    });

    el.click();
    expect(clicks).toHaveLength(1);

    cleanup();
  });

  it('should handle Enter key', () => {
    const clicks: number[] = [];
    const cleanup = setupCard(el, {
      clickable: true,
      onClick: () => clicks.push(1),
    });

    el.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
    expect(clicks).toHaveLength(1);

    cleanup();
  });

  it('should handle Space key', () => {
    const clicks: number[] = [];
    const cleanup = setupCard(el, {
      clickable: true,
      onClick: () => clicks.push(1),
    });

    el.dispatchEvent(new KeyboardEvent('keydown', { key: ' ', bubbles: true }));
    expect(clicks).toHaveLength(1);

    cleanup();
  });

  it('should cleanup attributes on destroy', () => {
    const cleanup = setupCard(el, {
      clickable: true,
      onClick: () => {},
    });

    expect(el.getAttribute('data-clickable')).toBe('true');

    cleanup();

    expect(el.hasAttribute('data-clickable')).toBe(false);
    expect(el.hasAttribute('tabindex')).toBe(false);
    expect(el.hasAttribute('role')).toBe(false);
  });
});
