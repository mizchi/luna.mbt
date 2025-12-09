// Re-export from MoonBit build output
// This file exists to apply TypeScript types from index.d.ts
export {
  createSignal,
  get,
  set,
  update,
  peek,
  subscribe,
  map,
  createMemo,
  combine,
  effect,
  batchStart,
  batchEnd,
  runUntracked,
} from "../../target/js/release/build/signals/signals.js";
