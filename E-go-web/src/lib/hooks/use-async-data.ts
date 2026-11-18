'use client';

/**
 * Loading of repository data in a component.
 *
 * The hook keeps three rules:
 * - a response of an outdated request is ignored (no state update after a
 *   newer request started),
 * - the component may unmount while a request is running (no state update
 *   after unmount),
 * - an inline loader (`() => repo.list(id)`) must not restart the request on
 *   every render - the loader lives in a ref, the effect is keyed on the
 *   dependencies the caller passes.
 */

import { useCallback, useEffect, useRef, useState } from 'react';

import type { AppError, Result } from '@/lib/domain/types';

/** The state of an asynchronously loaded resource. */
export interface AsyncDataState<T> {
  data: T | null;
  loading: boolean;
  error: AppError | null;
  /** Starts the request again. */
  reload: () => void;
}

/** A stable key of the dependencies, so the effect may depend on it. */
function depsKeyOf(deps: readonly unknown[]): string {
  return deps
    .map((value) => {
      if (value === null || value === undefined) return String(value);
      if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
        return String(value);
      }
      try {
        return JSON.stringify(value) ?? String(value);
      } catch {
        return String(value);
      }
    })
    .join('|');
}

/**
 * Load data from a repository.
 *
 * @param loader the request (must return a `Result`)
 * @param deps the values the request depends on (a change reloads the data)
 * @param options `enabled: false` skips the request
 */
export function useAsyncData<T>(
  loader: () => Promise<Result<T>>,
  deps: readonly unknown[] = [],
  options: { enabled?: boolean } = {},
): AsyncDataState<T> {
  const enabled = options.enabled ?? true;

  const [reloadCounter, setReloadCounter] = useState(0);
  const [result, setResult] = useState<{
    token: string;
    data: T | null;
    error: AppError | null;
  }>({ token: '', data: null, error: null });

  // The key of the current request: it changes with the dependencies and with
  // every reload, so the effect below only restarts when it has to.
  const token = enabled ? `${depsKeyOf(deps)}#${reloadCounter}` : '';

  // The loader is kept in a ref, so an inline arrow never restarts the effect.
  const loaderRef = useRef(loader);
  const requestId = useRef(0);
  const mounted = useRef(true);

  useEffect(() => {
    loaderRef.current = loader;
  }, [loader]);

  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);

  useEffect(() => {
    if (!enabled) return;

    const id = requestId.current + 1;
    requestId.current = id;
    let cancelled = false;

    loaderRef
      .current()
      .then((response) => {
        if (cancelled || !mounted.current || requestId.current !== id) return;
        setResult({
          token,
          data: response.ok ? response.data : null,
          error: response.ok ? null : response.error,
        });
      })
      .catch(() => {
        if (cancelled || !mounted.current || requestId.current !== id) return;
        setResult({
          token,
          data: null,
          error: { code: 'unknown', message: 'Something went wrong. Please try again.' },
        });
      });

    return () => {
      cancelled = true;
    };
  }, [enabled, token]);

  const reload = useCallback(() => {
    setReloadCounter((counter) => counter + 1);
  }, []);

  // The result belongs to the current request only while its token matches.
  const loading = enabled && result.token !== token;
  const error = result.token === token ? result.error : null;

  return { data: result.data, loading, error, reload };
}
