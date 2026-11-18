'use client';

/**
 * The clock of the ride.
 *
 * It is the only timer of the app: every second the session is checked and
 * the booking advances (the orchestrator decides what happens next). The
 * component renders nothing.
 */

import { useEffect } from 'react';

import { useAuthStore } from '@/stores/auth-store';
import { useBookingStore } from '@/stores/booking-store';

/** How often the booking advances. */
const TICK_INTERVAL_MS = 1000;

export function RideClock() {
  useEffect(() => {
    const tick = async () => {
      await useAuthStore.getState().expireIfNeeded();
      await useBookingStore.getState().tick(new Date().toISOString());
    };

    const handleVisibilityChange = () => {
      if (document.visibilityState !== 'visible') return;
      void (async () => {
        await useBookingStore.getState().resume();
        await tick();
      })();
    };

    void tick();

    const timer = setInterval(() => {
      void tick();
    }, TICK_INTERVAL_MS);

    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      clearInterval(timer);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, []);

  return null;
}
