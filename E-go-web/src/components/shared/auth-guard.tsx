'use client';

/**
 * The guard of the protected routes.
 *
 * Without a session the passenger is sent to the login page (with the page
 * they wanted in `returnTo`). An expired session is closed first, a user
 * without a complete profile goes to the profile setup.
 *
 * The guard never throws: every broken state ends in a redirect.
 */

import { usePathname, useRouter } from 'next/navigation';
import { useEffect, useRef, type ReactNode } from 'react';

import { AppSkeleton } from '@/components/shared/app-skeleton';
import { useToast } from '@/components/ui/toast';
import { ROUTES } from '@/lib/config/routes';
import { useAuthStore } from '@/stores/auth-store';

export interface AuthGuardProps {
  children: ReactNode;
}

export function AuthGuard({ children }: AuthGuardProps) {
  const router = useRouter();
  const pathname = usePathname();
  const { show } = useToast();

  const user = useAuthStore((state) => state.user);
  const session = useAuthStore((state) => state.session);
  const hasHydrated = useAuthStore((state) => state.hasHydrated);

  /** The redirect happens once - the effect must not replace again. */
  const redirecting = useRef(false);

  useEffect(() => {
    if (!hasHydrated || redirecting.current) return;

    const search = typeof window === 'undefined' ? '' : window.location.search;
    const returnTo = encodeURIComponent(`${pathname}${search}`);

    if (!session) {
      redirecting.current = true;
      router.replace(`${ROUTES.login}?returnTo=${returnTo}`);
      return;
    }

    if (Date.parse(session.expiresAt) <= Date.now()) {
      redirecting.current = true;
      useAuthStore.getState().expireSession();
      show({ message: 'Session expired. Please log in again.', tone: 'warning' });
      router.replace(`${ROUTES.login}?returnTo=${returnTo}`);
      return;
    }

    if (user && !user.profileComplete) {
      redirecting.current = true;
      router.replace(ROUTES.profileSetup);
    }
  }, [hasHydrated, pathname, router, session, show, user]);

  if (!hasHydrated) return <AppSkeleton />;
  if (!session || !user || !user.profileComplete) return <AppSkeleton />;

  return <>{children}</>;
}
