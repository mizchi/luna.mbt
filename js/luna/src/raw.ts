// @ts-nocheck
// Direct low-level re-exports from MoonBit JS API.
//
// These are the unwrapped MoonBit functions: `render`/`mount` here take a
// built node only, where their "@luna_ui/luna" counterparts also accept a
// thunk. `events()` is deliberately absent — its chaining methods are MoonBit
// externs that never attach to the returned object, so it is unusable from JS.

export {
  // Signals
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
  renderEffect,
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
  // DOM
  text,
  textDyn,
  render,
  mount,
  show,
  jsx,
  jsxs,
  Fragment,
  createElement,
  createElementNs,
  svgNs,
  mathmlNs,
  forEach,
  // Utilities
  debounced,
  // Router
  routePage,
  routePageTitled,
  routePageFull,
  createRouter,
  routerNavigate,
  routerReplace,
  routerGetPath,
  routerGetMatch,
  routerGetBase,
  // Context
  createContext,
  provide,
  useContext,
  // Resource
  createResource,
  createDeferred,
  resourceGet,
  resourcePeek,
  resourceRefetch,
  resourceIsPending,
  resourceIsSuccess,
  resourceIsFailure,
  resourceValue,
  resourceError,
  stateIsPending,
  stateIsSuccess,
  stateIsFailure,
  stateValue,
  stateError,
  // Portal
  portalToBody,
  portalToSelector,
  portalWithShadow,
  portalToElementWithShadow,
} from "../../../_build/js/release/build/mizchi/luna/js/api/api.js";
