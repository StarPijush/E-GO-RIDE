'use client';

/**
 * The client providers of the app.
 *
 * This is the only client boundary of the root layout: the toasts, the
 * hydration of the stores and the ride clock live here, so every screen can
 * stay a server component.
 */

import type { ReactNode } from 'react';

import { RideClock } from '@/components/shared/ride-clock';
import { ToastHost, ToastProvider } from '@/components/ui/toast';
import { StoreHydrator } from '@/stores/store-hydrator';

export interface ProvidersProps {
  children: ReactNode;
}

export function Providers({ children }: ProvidersProps) {
  return (
    <ToastProvider>
      <StoreHydrator />
      <RideClock />
      {children}
      <ToastHost />
    </ToastProvider>
  );
}
