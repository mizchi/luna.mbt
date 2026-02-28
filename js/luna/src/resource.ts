// @ts-nocheck
// Resource-focused entrypoint bound from MoonBit api_resource_lite

export type PendingState = { $tag: 0 };
export type SuccessState<T> = { $tag: 1; _0: T };
export type FailureState = { $tag: 2; _0: string };
export type AsyncState<T> = PendingState | SuccessState<T> | FailureState;

export type ResourceFetcher<T> = (
  resolve: (value: T) => void,
  reject: (error: string) => void,
) => void;

export interface Resource<T> {
  _state?: AsyncState<T>;
  _fetcher?: ResourceFetcher<T>;
}

import {
  createResource as _createResource,
  createDeferred as _createDeferred,
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
} from "../../../_build/js/release/build/js/api_resource_lite/api_resource_lite.js";

export function createResource<T>(fetcher: ResourceFetcher<T>): Resource<T> {
  return _createResource(fetcher);
}

export function createDeferred<T>() {
  const deferred = _createDeferred();
  if (Array.isArray(deferred)) {
    return [deferred[0], deferred[1], deferred[2]] as const;
  }
  return [deferred._0, deferred._1, deferred._2] as const;
}

export {
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
};
