// @ts-nocheck
// Signals entrypoint that shares the same MoonBit backend module as index.ts
// Use this when importing both "@luna_ui/luna" and "@luna_ui/luna/signals*"

export type Accessor<T> = () => T;
export type Setter<T> = (value: T | ((prev: T) => T)) => void;
export type Signal<T> = [Accessor<T>, Setter<T>];

import {
  createSignal as _createSignal,
  get as _get,
  set as _set,
  update as _update,
  peek as _peek,
  subscribe as _subscribe,
  map as _map,
  createMemo as _createMemo,
  combine as _combine,
  effect as _effect,
  renderEffect as _renderEffect,
  batchStart,
  batchEnd,
  runUntracked,
  batch,
  onCleanup,
  createRoot,
  getOwner,
  runWithOwner,
  hasOwner,
  onMount,
} from "../../../_build/js/release/build/js/api/api.js";

export function createSignal<T>(initialValue: T): Signal<T> {
  const signal = _createSignal(initialValue);
  const getter: Accessor<T> = () => _get(signal);
  const setter: Setter<T> = (valueOrUpdater) => {
    if (typeof valueOrUpdater === "function") {
      _update(signal, valueOrUpdater);
    } else {
      _set(signal, valueOrUpdater);
    }
  };
  return [getter, setter];
}

export function createEffect(fn: () => void): () => void {
  return _effect(fn);
}

export function createRenderEffect(fn: () => void): () => void {
  return _renderEffect(fn);
}

export function createMemo<T>(fn: () => T): Accessor<T> {
  return _createMemo(fn);
}

export { runUntracked as untrack };

export {
  batchStart,
  batchEnd,
  batch,
  onCleanup,
  createRoot,
  getOwner,
  runWithOwner,
  hasOwner,
  onMount,
};

export {
  _get as get,
  _set as set,
  _update as update,
  _peek as peek,
  _subscribe as subscribe,
  _map as map,
  _combine as combine,
  _effect as effect,
  _renderEffect as renderEffect,
  runUntracked,
};
