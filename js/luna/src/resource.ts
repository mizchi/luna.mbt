// @ts-nocheck
// Resource-focused entrypoint (raw MoonBit API, minimal wrapper cost)

export type Resource<T> = unknown;
export type AsyncState<T> = unknown;

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
} from "../../../_build/js/release/build/js/api_resource/api_resource.js";

export function createResource<T>(
  fetcher: (resolve: (value: T) => void, reject: (error: string) => void) => void,
) {
  return _createResource(fetcher);
}

export function createDeferred<T>() {
  const deferred = _createDeferred();
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
} from "../../../_build/js/release/build/js/api_resource/api_resource.js";
