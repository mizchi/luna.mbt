/**
 * Signal unit tests
 */

import { describe, it, expect } from 'vitest';
import { Signal, effect } from '@mizchi/luna-wcr';

describe('Signal', () => {
  it('should store and retrieve value', () => {
    const sig = new Signal(42);
    expect(sig.get()).toBe(42);
  });

  it('should update value', () => {
    const sig = new Signal(0);
    sig.set(10);
    expect(sig.get()).toBe(10);
  });

  it('should update with function', () => {
    const sig = new Signal(5);
    sig.update((n) => n + 1);
    expect(sig.get()).toBe(6);
  });
});

describe('effect', () => {
  it('should run immediately', () => {
    let ran = false;
    effect(() => {
      ran = true;
    });
    expect(ran).toBe(true);
  });

  it('should auto-track signal dependencies', () => {
    const sig = new Signal(0);
    let value = -1;

    effect(() => {
      value = sig.get();
    });

    expect(value).toBe(0);

    sig.set(10);
    expect(value).toBe(10);

    sig.update((n) => n + 5);
    expect(value).toBe(15);
  });

  it('should track multiple signals', () => {
    const a = new Signal(1);
    const b = new Signal(2);
    let sum = 0;

    effect(() => {
      sum = a.get() + b.get();
    });

    expect(sum).toBe(3);

    a.set(10);
    expect(sum).toBe(12);

    b.set(20);
    expect(sum).toBe(30);
  });

  it('should cleanup on dispose', () => {
    const sig = new Signal(0);
    let value = -1;

    const dispose = effect(() => {
      value = sig.get();
    });

    expect(value).toBe(0);
    sig.set(10);
    expect(value).toBe(10);

    dispose();

    sig.set(20);
    expect(value).toBe(10); // Should not update after dispose
  });
});

describe('subscribe', () => {
  it('should run callback on change', () => {
    const sig = new Signal(0);
    let value = -1;

    sig.subscribe(() => {
      value = sig.peek();
    });

    expect(value).toBe(0); // Runs immediately

    sig.set(10);
    expect(value).toBe(10);
  });
});
