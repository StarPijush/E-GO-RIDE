'use client';

/**
 * Reactive CSS media query.
 *
 * SSR safe: the first render always reports `false`, the real value arrives
 * after the component mounted in the browser.
 */

import { useEffect, useState } from 'react';

export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(false);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (typeof window.matchMedia !== 'function') return;

    const list = window.matchMedia(query);
    const update = () => setMatches(list.matches);

    update();

    if (typeof list.addEventListener === 'function') {
      list.addEventListener('change', update);
      return () => list.removeEventListener('change', update);
    }

    // Legacy Safari (< 14) only knows the deprecated listener API.
    list.addListener(update);
    return () => list.removeListener(update);
  }, [query]);

  return matches;
}
