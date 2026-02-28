// @ts-nocheck
// Resource-focused entrypoint (minimal TypeScript implementation)

export type PendingState = { $tag: 0 };
export type SuccessState<T> = { $tag: 1; _0: T };
export type FailureState = { $tag: 2; _0: string };
export type AsyncState<T> = PendingState | SuccessState<T> | FailureState;

export type ResourceFetcher<T> = (
  resolve: (value: T) => void,
  reject: (error: string) => void,
) => void;

export interface Resource<T> {
  _state: AsyncState<T>;
  _fetcher?: ResourceFetcher<T>;
}

const PENDING: PendingState = { $tag: 0 };

function success<T>(value: T): SuccessState<T> {
  return { $tag: 1, _0: value };
}

function failure(error: string): FailureState {
  return { $tag: 2, _0: error };
}

function runFetch<T>(resource: Resource<T>): void {
  const fetcher = resource._fetcher;
  if (!fetcher) {
    resource._state = PENDING;
    return;
  }

  resource._state = PENDING;
  fetcher(
    (value) => {
      resource._state = success(value);
    },
    (error) => {
      resource._state = failure(error);
    },
  );
}

export function createResource<T>(fetcher: ResourceFetcher<T>): Resource<T> {
  const resource: Resource<T> = {
    _state: PENDING,
    _fetcher: fetcher,
  };
  runFetch(resource);
  return resource;
}

export function createDeferred<T>() {
  const resource: Resource<T> = {
    _state: PENDING,
  };
  const resolve = (value: T) => {
    resource._state = success(value);
  };
  const reject = (error: string) => {
    resource._state = failure(error);
  };
  return [resource, resolve, reject] as const;
}

export function resourceGet<T>(resource: Resource<T>): AsyncState<T> {
  return resource._state;
}

export function resourcePeek<T>(resource: Resource<T>): AsyncState<T> {
  return resource._state;
}

export function resourceRefetch<T>(resource: Resource<T>): void {
  runFetch(resource);
}

export function stateIsPending<T>(state: AsyncState<T>): boolean {
  return state.$tag === 0;
}

export function stateIsSuccess<T>(state: AsyncState<T>): boolean {
  return state.$tag === 1;
}

export function stateIsFailure<T>(state: AsyncState<T>): boolean {
  return state.$tag === 2;
}

export function stateValue<T>(state: AsyncState<T>): T | undefined {
  return state.$tag === 1 ? state._0 : undefined;
}

export function stateError<T>(state: AsyncState<T>): string | undefined {
  return state.$tag === 2 ? state._0 : undefined;
}

export function resourceIsPending<T>(resource: Resource<T>): boolean {
  return stateIsPending(resource._state);
}

export function resourceIsSuccess<T>(resource: Resource<T>): boolean {
  return stateIsSuccess(resource._state);
}

export function resourceIsFailure<T>(resource: Resource<T>): boolean {
  return stateIsFailure(resource._state);
}

export function resourceValue<T>(resource: Resource<T>): T | undefined {
  return stateValue(resource._state);
}

export function resourceError<T>(resource: Resource<T>): string | undefined {
  return stateError(resource._state);
}
