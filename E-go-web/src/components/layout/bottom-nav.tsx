'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

import { NavIcon } from '@/components/shared/nav-icon';
import { BOTTOM_NAV, isActiveRoute } from '@/lib/config/routes';
import { cn } from '@/lib/utils/cn';

/**
 * The bottom navigation of the mobile shell.
 *
 * Five entries, the "Book" button raised above the bar. The labels are kept
 * (the active state is readable without the icon alone) and truncated on a
 * 320 px screen.
 */
export function BottomNav() {
  const pathname = usePathname();

  return (
    <nav
      aria-label="Main navigation"
      className="fixed inset-x-0 bottom-0 z-40 border-t border-line bg-white/95 pb-[env(safe-area-inset-bottom)] backdrop-blur lg:hidden"
    >
      <div className="grid h-16 grid-cols-5 items-center">
        {BOTTOM_NAV.map((item) => {
          const active = isActiveRoute(pathname, item.href);
          const raised = item.id === 'book';

          return (
            <Link
              key={item.id}
              href={item.href}
              aria-label={raised ? 'Book a ride' : item.label}
              aria-current={active ? 'page' : undefined}
              className={cn(
                'flex min-h-11 min-w-0 flex-col items-center justify-center gap-1 px-0.5',
                'text-[11px] font-medium',
                active ? 'font-semibold text-navy' : 'text-muted',
              )}
            >
              <span
                className={cn(
                  'relative flex items-center justify-center',
                  raised &&
                    '-mt-6 size-14 rounded-full border-4 border-surface bg-brand text-navy shadow-card',
                )}
              >
                <NavIcon name={item.icon} className={raised ? 'size-6' : undefined} />
                {active && !raised ? (
                  <span
                    aria-hidden="true"
                    className="absolute -bottom-1 h-1 w-1 rounded-full bg-brand"
                  />
                ) : null}
              </span>

              <span className={cn('w-full truncate text-center', raised && 'font-semibold text-navy')}>
                {item.label}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
