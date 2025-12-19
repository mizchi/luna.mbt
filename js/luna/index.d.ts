/**
 * SolidJS-compatible TypeScript definitions for Luna
 */

// MoonBit tuple type - exported as object with _0 and _1 properties
export type MoonBitTuple<A, B> = { _0: A; _1: B };

// ============================================================================
// Signal API (SolidJS-style)
// ============================================================================

/** Signal getter function */
export type Accessor<T> = () => T;

/** Signal setter function - accepts value or updater function */
export type Setter<T> = (value: T | ((prev: T) => T)) => void;

/** Signal tuple [getter, setter] */
export type Signal<T> = [Accessor<T>, Setter<T>];

/**
 * Creates a reactive signal (SolidJS-style)
 * @example
 * const [count, setCount] = createSignal(0);
 * count(); // 0
 * setCount(1);
 * setCount(c => c + 1);
 */
export function createSignal<T>(initialValue: T): Signal<T>;

/**
 * Creates a reactive effect (SolidJS-style)
 * @example
 * createEffect(() => console.log(count()));
 */
export function createEffect(fn: () => void): () => void;

/**
 * Creates a memoized computed value (SolidJS-style)
 * @example
 * const doubled = createMemo(() => count() * 2);
 */
export function createMemo<T>(compute: () => T): Accessor<T>;

/** Start a batch update */
export function batchStart(): void;

/** End a batch update and run pending effects */
export function batchEnd(): void;

/** Run a function in a batch - all signal updates are batched */
export function batch<T>(fn: () => T): T;

/** Run a function without tracking dependencies (SolidJS: untrack) */
export function untrack<T>(fn: () => T): T;

/** Register a cleanup function inside an effect */
export function onCleanup(cleanup: () => void): void;

// ============================================================================
// Utility functions (SolidJS-style)
// ============================================================================

/**
 * Explicit dependency tracking helper (SolidJS-style)
 * Wraps a function to explicitly specify which signals to track
 * @example
 * createEffect(on(count, (value, prev) => console.log(value, prev)));
 * createEffect(on([a, b], ([a, b]) => console.log(a, b)));
 */
export function on<T, U>(
  deps: Accessor<T>,
  fn: (input: T, prevInput: T | undefined, prevValue: U | undefined) => U,
  options?: { defer?: boolean }
): () => U | undefined;
export function on<T extends readonly Accessor<any>[], U>(
  deps: T,
  fn: (
    input: { [K in keyof T]: T[K] extends Accessor<infer V> ? V : never },
    prevInput: { [K in keyof T]: T[K] extends Accessor<infer V> ? V : never } | undefined,
    prevValue: U | undefined
  ) => U,
  options?: { defer?: boolean }
): () => U | undefined;

/**
 * Merge multiple props objects (SolidJS-style)
 * Event handlers and refs are merged, other props are overwritten
 * @example
 * const merged = mergeProps(defaultProps, props);
 */
export function mergeProps<T extends object>(...sources: (Partial<T> | undefined)[]): T;

/**
 * Split props into multiple objects based on key lists (SolidJS-style)
 * @example
 * const [local, others] = splitProps(props, ["class", "style"]);
 */
export function splitProps<T extends object, K extends (keyof T)[]>(
  props: T,
  ...keys: K[]
): [...{ [I in keyof K]: Pick<T, K[I] extends (keyof T)[] ? K[I][number] : never> }, Omit<T, K[number][number]>];

// ============================================================================
// Owner-based scope management
// ============================================================================

/** Opaque Owner type */
export interface Owner {
  readonly __brand: unique symbol;
}

/** Create a new reactive root scope */
export function createRoot<T>(fn: (dispose: () => void) => T): T;

/** Get the current owner (if any) */
export function getOwner(): Owner | undefined;

/** Run a function with a specific owner as current */
export function runWithOwner<T>(owner: Owner, fn: () => T): T;

/** Check if currently inside an owner scope */
export function hasOwner(): boolean;

/** Run a function once (SolidJS-style onMount) */
export function onMount(fn: () => void): void;

// ============================================================================
// DOM API
// ============================================================================

/** Opaque DOM Node type */
export interface Node {
  readonly __brand: unique symbol;
}

/** Event handler types */
export type MouseEventHandler = (event: MouseEvent) => void;
export type InputEventHandler = (event: InputEvent) => void;
export type KeyboardEventHandler = (event: KeyboardEvent) => void;
export type FocusEventHandler = (event: FocusEvent) => void;
export type FormEventHandler = (event: Event) => void;
export type ChangeEventHandler = (event: Event) => void;

/** HandlerMap builder for event handlers (method chaining) */
export interface HandlerMap {
  click(handler: MouseEventHandler): HandlerMap;
  dblclick(handler: MouseEventHandler): HandlerMap;
  input(handler: InputEventHandler): HandlerMap;
  change(handler: ChangeEventHandler): HandlerMap;
  submit(handler: FormEventHandler): HandlerMap;
  keydown(handler: KeyboardEventHandler): HandlerMap;
  keyup(handler: KeyboardEventHandler): HandlerMap;
  keypress(handler: KeyboardEventHandler): HandlerMap;
  focus(handler: FocusEventHandler): HandlerMap;
  blur(handler: FocusEventHandler): HandlerMap;
  mouseenter(handler: MouseEventHandler): HandlerMap;
  mouseleave(handler: MouseEventHandler): HandlerMap;
  mouseover(handler: MouseEventHandler): HandlerMap;
  mouseout(handler: MouseEventHandler): HandlerMap;
  mousedown(handler: MouseEventHandler): HandlerMap;
  mouseup(handler: MouseEventHandler): HandlerMap;
}

/** Create event handler map builder */
export function events(): HandlerMap;

// Text
export function text(content: string): Node;
export function textDyn(getter: () => string): Node;

// Rendering
export function render(container: Element, node: Node): void;
export function mount(container: Element, node: Node): void;
export function show(condition: () => boolean, render: () => Node): Node;

// List rendering (low-level)
export function forEach<T>(
  items: () => T[],
  renderItem: (item: T, index: number) => Node
): Node;

// ============================================================================
// SolidJS-compatible Components
// ============================================================================

/** For component props */
export interface ForProps<T, U extends Node> {
  each: Accessor<T[]> | T[];
  fallback?: Node;
  children: (item: T, index: Accessor<number>) => U;
}

/**
 * For component for list rendering (SolidJS-style)
 * @example
 * <For each={items}>{(item, index) => <div>{item}</div>}</For>
 */
export function For<T, U extends Node>(props: ForProps<T, U>): Node;

/** Show component props */
export interface ShowProps<T> {
  when: T | Accessor<T>;
  fallback?: Node;
  children: Node | ((item: NonNullable<T>) => Node);
}

/**
 * Show component for conditional rendering (SolidJS-style)
 * Note: fallback prop is not yet supported (Luna limitation)
 * @example
 * <Show when={isVisible}><div>Visible!</div></Show>
 */
export function Show<T>(props: ShowProps<T>): Node;

/** Index component props */
export interface IndexProps<T, U extends Node> {
  each: Accessor<T[]> | T[];
  fallback?: Node;
  children: (item: Accessor<T>, index: number) => U;
}

/**
 * Index component for index-based list rendering (SolidJS-style)
 * Unlike For which tracks items by reference, Index tracks by index position
 * @example
 * <Index each={items}>{(item, index) => <div>{item()}</div>}</Index>
 */
export function Index<T, U extends Node>(props: IndexProps<T, U>): Node;

/** Provider component props */
export interface ProviderProps<T> {
  context: Context<T>;
  value: T;
  children: Node | (() => Node);
}

/**
 * Provider component for Context (SolidJS-style)
 * @example
 * <Provider context={ThemeContext} value="dark"><App /></Provider>
 */
export function Provider<T>(props: ProviderProps<T>): Node;

/** Match component result (internal) */
export interface MatchResult<T> {
  readonly __isMatch: true;
  when: () => boolean;
  children: T | (() => T);
}

/** Switch component props */
export interface SwitchProps {
  fallback?: Node;
  children: MatchResult<Node>[];
}

/**
 * Switch component for conditional rendering with multiple branches (SolidJS-style)
 * @example
 * <Switch fallback={<div>Not found</div>}>
 *   <Match when={isA}><A /></Match>
 *   <Match when={isB}><B /></Match>
 * </Switch>
 */
export function Switch(props: SwitchProps): Node;

/** Match component props */
export interface MatchProps<T> {
  when: T | Accessor<T>;
  children: Node | ((item: NonNullable<T>) => Node);
}

/**
 * Match component for use inside Switch (SolidJS-style)
 */
export function Match<T>(props: MatchProps<T>): MatchResult<Node>;

// ============================================================================
// Portal API (SolidJS-style)
// ============================================================================

/** Portal component props */
export interface PortalProps {
  /** Target element or CSS selector to mount to (defaults to document.body) */
  mount?: Element | string;
  /** Whether to use Shadow DOM for encapsulation */
  useShadow?: boolean;
  /** Children to render in the portal */
  children: Node | Node[] | (() => Node);
}

/**
 * Portal component for rendering outside the component tree (SolidJS-style)
 * Teleports children to a different DOM location
 * @example
 * Portal({ children: modal() }) // renders to body
 * Portal({ mount: "#modal-root", children: modal() }) // renders to #modal-root
 * Portal({ useShadow: true, children: modal() }) // renders with Shadow DOM
 */
export function Portal(props: PortalProps): Node;

/** Low-level portal to body */
export function portalToBody(children: Node[]): Node;

/** Low-level portal to CSS selector */
export function portalToSelector(selector: string, children: Node[]): Node;

/** Low-level portal with Shadow DOM */
export function portalWithShadow(children: Node[]): Node;

/** Low-level portal to element with Shadow DOM */
export function portalToElementWithShadow(mount: Element, children: Node[]): Node;

// Low-level element creation (MoonBit API)
export function jsx(
  tag: string,
  attrs: MoonBitTuple<string, unknown>[],
  children: Node[]
): Node;
export function jsxs(
  tag: string,
  attrs: MoonBitTuple<string, unknown>[],
  children: Node[]
): Node;
/** Fragment function - returns children wrapped in a DocumentFragment */
export function Fragment(children: Node[]): Node;

/** Fragment symbol for JSX */
export const FragmentSymbol: unique symbol;

// Element creation (low-level)
export function createElement(
  tag: string,
  attrs: MoonBitTuple<string, unknown>[],
  children: Node[]
): Node;

// ============================================================================
// Context API
// ============================================================================

/** Opaque Context type */
export interface Context<T> {
  readonly __brand: unique symbol;
  readonly __type: T;
}

/** Create a new context with a default value */
export function createContext<T>(defaultValue: T): Context<T>;

/**
 * Provide a context value for the current Owner scope and its descendants.
 * Context values are Owner-based (component-tree-scoped), similar to SolidJS.
 */
export function provide<T, R>(ctx: Context<T>, value: T, fn: () => R): R;

/** Use a context value - returns the current provided value or default */
export function useContext<T>(ctx: Context<T>): T;

// ============================================================================
// Resource API (SolidJS-style)
// ============================================================================

/** Resource state */
export type ResourceState = "unresolved" | "pending" | "ready" | "errored";

/** Resource accessor with properties */
export interface ResourceAccessor<T> {
  (): T | undefined;
  readonly loading: boolean;
  readonly error: string | undefined;
  readonly state: ResourceState;
  readonly latest: T | undefined;
}

/** Resource actions */
export interface ResourceActions {
  refetch: () => void;
}

/**
 * Create a Resource from a callback-based fetcher (SolidJS-style)
 * @example
 * const [data, { refetch }] = createResource((resolve, reject) => {
 *   fetch('/api').then(r => r.json()).then(resolve).catch(e => reject(e.message));
 * });
 * data(); // value or undefined
 * data.loading; // boolean
 * data.error; // string or undefined
 */
export function createResource<T>(
  fetcher: (resolve: (value: T) => void, reject: (error: string) => void) => void
): [ResourceAccessor<T>, ResourceActions];

/**
 * Create a deferred Resource (SolidJS-style)
 * Returns [accessor, resolve, reject]
 */
export function createDeferred<T>(): [
  ResourceAccessor<T>,
  (value: T) => void,
  (error: string) => void
];

// Low-level resource helpers
export function resourceGet<T>(resource: any): any;
export function resourcePeek<T>(resource: any): any;
export function resourceRefetch<T>(resource: any): void;
export function resourceIsPending<T>(resource: any): boolean;
export function resourceIsSuccess<T>(resource: any): boolean;
export function resourceIsFailure<T>(resource: any): boolean;
export function resourceValue<T>(resource: any): T | undefined;
export function resourceError<T>(resource: any): string | undefined;
export function stateIsPending<T>(state: any): boolean;
export function stateIsSuccess<T>(state: any): boolean;
export function stateIsFailure<T>(state: any): boolean;
export function stateValue<T>(state: any): T | undefined;
export function stateError<T>(state: any): string | undefined;

// ============================================================================
// Timer utilities
// ============================================================================

/** Debounce a signal */
export function debounced<T>(signal: Signal<T>, delayMs: number): Signal<T>;

// ============================================================================
// Store API (SolidJS-style)
// ============================================================================

/** Path segment type for setState */
type PathSegment = string | number;

/** Store setter function type */
export interface SetStoreFunction<T> {
  /** Update value at path */
  <K1 extends keyof T>(key1: K1, value: T[K1] | ((prev: T[K1]) => T[K1])): void;
  <K1 extends keyof T, K2 extends keyof T[K1]>(
    key1: K1,
    key2: K2,
    value: T[K1][K2] | ((prev: T[K1][K2]) => T[K1][K2])
  ): void;
  <K1 extends keyof T, K2 extends keyof T[K1], K3 extends keyof T[K1][K2]>(
    key1: K1,
    key2: K2,
    key3: K3,
    value: T[K1][K2][K3] | ((prev: T[K1][K2][K3]) => T[K1][K2][K3])
  ): void;
  /** Merge object at root */
  (value: Partial<T>): void;
  /** Generic path-based update */
  (...args: [...PathSegment[], unknown]): void;
}

/** Store tuple type */
export type Store<T> = [T, SetStoreFunction<T>];

/**
 * Creates a reactive store with nested property tracking (SolidJS-style)
 * @example
 * const [state, setState] = createStore({ count: 0, user: { name: "John" } });
 *
 * // Read (reactive - tracks dependencies)
 * state.count
 * state.user.name
 *
 * // Update by path
 * setState("count", 1);
 * setState("user", "name", "Jane");
 *
 * // Functional update
 * setState("count", c => c + 1);
 *
 * // Object merge at path
 * setState("user", { name: "Jane", age: 30 });
 */
export function createStore<T extends object>(initialValue: T): Store<T>;

/**
 * Produce helper for immer-style mutations (SolidJS-style)
 * @example
 * setState("user", produce(user => { user.name = "Jane"; }));
 */
export function produce<T>(fn: (draft: T) => void): (state: T) => T;

/**
 * Reconcile helper for efficient array/object updates (SolidJS-style)
 * Replaces the entire value at the path
 * @example
 * setState("items", reconcile(newItems));
 */
export function reconcile<T>(value: T): (state: T) => T;

// ============================================================================
// Router API
// ============================================================================

/** Route definition - Page route */
export interface PageRoute {
  readonly $tag: 0;
  readonly path: string;
  readonly component: string;
  readonly title: string;
  readonly meta: MoonBitTuple<string, string>[];
}

/** Route definition union type */
export type Routes = PageRoute;

export function routePage(path: string, component: string): Routes;
export function routePageTitled(path: string, component: string, title: string): Routes;
export function routePageFull(path: string, component: string, title: string, meta: MoonBitTuple<string, string>[]): Routes;

/** Opaque BrowserRouter type */
export interface BrowserRouter {
  readonly __brand: unique symbol;
}

/** Compiled route info */
export interface CompiledRoute {
  readonly pattern: string;
  readonly param_names: string[];
  readonly component: string;
  readonly layouts: string[];
}

/** Route match result */
export interface RoutesMatch {
  readonly route: CompiledRoute;
  readonly params: MoonBitTuple<string, string>[];
  readonly query: MoonBitTuple<string, string>[];
  readonly path: string;
}

export function createRouter(routes: Routes[], base?: string): BrowserRouter;
export function routerNavigate(router: BrowserRouter, path: string): void;
export function routerReplace(router: BrowserRouter, path: string): void;
export function routerGetPath(router: BrowserRouter): string;
export function routerGetMatch(router: BrowserRouter): RoutesMatch | undefined;
export function routerGetBase(router: BrowserRouter): string;

// ============================================================================
// Legacy API (for backwards compatibility)
// ============================================================================

/** @deprecated Use createSignal()[0] instead */
export function get<T>(signal: any): T;
/** @deprecated Use createSignal()[1] instead */
export function set<T>(signal: any, value: T): void;
/** @deprecated Use createSignal()[1] with function instead */
export function update<T>(signal: any, fn: (current: T) => T): void;
/** @deprecated */
export function peek<T>(signal: any): T;
/** @deprecated */
export function subscribe<T>(signal: any, callback: (value: T) => void): () => void;
/** @deprecated */
export function map<T, U>(signal: any, fn: (value: T) => U): () => U;
/** @deprecated */
export function combine<A, B, R>(a: any, b: any, fn: (a: A, b: B) => R): () => R;
/** @deprecated Use createEffect instead */
export function effect(fn: () => void): () => void;
/** @deprecated Use untrack instead */
export function runUntracked<T>(fn: () => T): T;
