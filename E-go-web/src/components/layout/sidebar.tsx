'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { LifeBuoy, Plus, Settings, ShieldCheck, type LucideIcon } from 'lucide-react';

import { Logo } from '@/components/shared/logo';
import { NavIcon } from '@/components/shared/nav-icon';
import { Avatar } from '@/components/ui/avatar';
import { NAV_GROUPS, ROUTES, isActiveRoute } from '@/lib/config/routes';
import { useAuthStore } from '@/stores/auth-store';
import { cn } from '@/lib/utils/cn';

/** The navigation that is always visible. */
const PRIMARY_NAV = [
  { id: 'home', label: 'Home', icon: 'home', href: ROUTES.home },
  { id: 'my-rides', label: 'My rides', icon: 'route', href: ROUTES.myRides },
  { id: 'notifications', label: 'Notifications', icon: 'bell', href: ROUTES.notifications },
];

/**
 * The groups of the account navigation.
 *
 * "Rides" and "Activity" repeat the primary navigation, so only "Account"
 * and "Support" are rendered here.
 */
const SECONDARY_NAV = NAV_GROUPS.filter(
  (group) => group.id === 'account' || group.id === 'support',
);

/** The small links at the bottom of the sidebar. */
const FOOTER_LINKS: { id: string; label: string; href: string; icon: LucideIcon }[] = [
  { id: 'settings', label: 'Settings', href: ROUTES.settings, icon: Settings },
  { id: 'help-support', label: 'Help & Support', href: ROUTES.helpSupport, icon: LifeBuoy },
  { id: 'safety', label: 'Safety', href: ROUTES.safety, icon: ShieldCheck },
];

/** The desktop navigation of the app shell. */
export function Sidebar() {
  const pathname = usePathname();
  const user = useAuthStore((state) => state.user);
  const hasHydrated = useAuthStore((state) => state.hasHydrated);

  const itemClass = (active: boolean) =>
    cn(
      'flex min-h-11 items-center gap-3 rounded-card px-3 text-sm transition-colors',
      'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2',
      active
        ? 'bg-brand-soft font-semibold text-navy'
        : 'font-medium text-muted hover:bg-navy-soft hover:text-navy',
    );

  return (
    <aside className="fixed inset-y-0 left-0 z-40 hidden w-64 flex-col border-r border-line bg-white lg:flex">
      <div className="flex items-center px-4 py-4">
        <Logo href={ROUTES.home} showTagline />
      </div>

      <div className="px-4 pb-4">
        <Link
          href={ROUTES.destinationSelection}
          className={cn(
            'inline-flex h-12 w-full items-center justify-center gap-2 rounded-pill bg-brand font-semibold text-navy',
            'transition-colors hover:bg-brand-strong',
            'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2',
          )}
        >
          <Plus aria-hidden="true" className="size-5" />
          Book a ride
        </Link>
      </div>

      <nav aria-label="Main navigation" className="flex-1 overflow-y-auto px-2 pb-4">
        <ul className="flex flex-col gap-1">
          {PRIMARY_NAV.map((item) => {
            const active = isActiveRoute(pathname, item.href);
            return (
              <li key={item.id}>
                <Link
                  href={item.href}
                  aria-current={active ? 'page' : undefined}
                  className={itemClass(active)}
                >
                  <NavIcon name={item.icon} />
                  {item.label}
                </Link>
              </li>
            );
          })}
        </ul>

        <div className="my-3 h-px bg-line" aria-hidden="true" />

        <ul className="flex flex-col gap-1">
          {SECONDARY_NAV.map((group) => {
            const active = isActiveRoute(pathname, group.href);
            return (
              <li key={group.id}>
                <Link
                  href={group.href}
                  aria-current={active ? 'page' : undefined}
                  className={itemClass(active)}
                >
                  <NavIcon name={group.icon} />
                  {group.label}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>

      <div className="border-t border-line p-3">
        {hasHydrated && user ? (
          <Link
            href={ROUTES.profile}
            className={cn(
              'flex items-center gap-3 rounded-card p-2 transition-colors hover:bg-navy-soft',
              'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2',
            )}
          >
            <Avatar name={user.fullName} size="md" />
            <span className="flex min-w-0 flex-col">
              <span className="truncate text-sm font-semibold text-navy">{user.fullName}</span>
              <span className="truncate text-xs text-muted">{user.phone}</span>
            </span>
          </Link>
        ) : null}

        <ul className="mt-2 flex flex-col gap-0.5">
          {FOOTER_LINKS.map((link) => {
            const active = isActiveRoute(pathname, link.href);
            const Icon = link.icon;
            return (
              <li key={link.id}>
                <Link
                  href={link.href}
                  aria-current={active ? 'page' : undefined}
                  className={itemClass(active)}
                >
                  <Icon aria-hidden="true" className="size-5" />
                  {link.label}
                </Link>
              </li>
            );
          })}
        </ul>
      </div>
    </aside>
  );
}
