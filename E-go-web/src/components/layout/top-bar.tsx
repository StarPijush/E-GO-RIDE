'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

import { Container } from '@/components/layout/container';
import { Logo } from '@/components/shared/logo';
import { NavIcon } from '@/components/shared/nav-icon';
import { ROUTES, ROUTE_TITLES } from '@/lib/config/routes';
import { cn } from '@/lib/utils/cn';

/** The title of the page the passenger is on. */
function titleFor(pathname: string): string {
  // An exact match wins.
  for (const route of Object.keys(ROUTE_TITLES) as Array<keyof typeof ROUTE_TITLES>) {
    if (ROUTES[route] === pathname) return ROUTE_TITLES[route];
  }

  // The longest matching prefix (e.g. `/ride-details/abc` -> `/ride-details`).
  let match: { path: string; title: string } | null = null;
  for (const route of Object.keys(ROUTE_TITLES) as Array<keyof typeof ROUTE_TITLES>) {
    const path = ROUTES[route];
    if (path === '/') continue;
    if (!pathname.startsWith(`${path}/`)) continue;
    if (!match || path.length > match.path.length) match = { path, title: ROUTE_TITLES[route] };
  }

  return match?.title ?? 'E-GO';
}

export interface TopBarProps {
  /** The number of unread notifications (a badge is shown when it is above zero). */
  unreadCount?: number;
}

/** The bar at the top of the app shell. */
export function TopBar({ unreadCount = 0 }: TopBarProps) {
  const pathname = usePathname();
  const title = titleFor(pathname);
  const hasUnread = unreadCount > 0;

  return (
    <header className="sticky top-0 z-30 border-b border-line bg-surface/95 backdrop-blur">
      <Container className="flex h-16 items-center justify-between gap-3">
        <div className="flex min-w-0 items-center gap-3">
          <Logo href={ROUTES.home} size="sm" className="lg:hidden" />
          <h1 className="hidden truncate font-display text-lg font-semibold text-navy lg:block">
            {title}
          </h1>
        </div>

        <div className="flex items-center gap-2">
          <Link
            href={ROUTES.notifications}
            aria-label="Notifications"
            className={cn(
              'relative inline-flex size-11 items-center justify-center rounded-full bg-white text-navy',
              'transition-colors hover:bg-navy-soft',
              'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2',
            )}
          >
            <NavIcon name="bell" />

            {hasUnread ? (
              <>
                <span className="sr-only">{unreadCount} unread notifications</span>
                <span
                  aria-hidden="true"
                  className="absolute -right-0.5 -top-0.5 inline-flex min-w-5 items-center justify-center rounded-full bg-danger px-1 text-[10px] font-semibold text-white"
                >
                  {unreadCount > 9 ? '9+' : unreadCount}
                </span>
              </>
            ) : null}
          </Link>
        </div>
      </Container>
    </header>
  );
}
