'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import {
  Bell,
  ChevronRight,
  CreditCard,
  Info,
  LifeBuoy,
  LogOut,
  MapPin,
  Pencil,
  Route as RouteIcon,
  Settings,
  type LucideIcon,
} from 'lucide-react';

import { PageHeader } from '@/components/layout/page-header';
import { Avatar } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Dialog } from '@/components/ui/dialog';
import { EmptyState } from '@/components/ui/empty-state';
import { useToast } from '@/components/ui/toast';
import { ROUTES } from '@/lib/config/routes';
import { useAuthStore } from '@/stores/auth-store';

/** One entry of the account menu. */
interface MenuEntry {
  id: string;
  label: string;
  href: string;
  icon: LucideIcon;
}

/** The sections of the account menu. */
const MENU_SECTIONS: readonly { id: string; title: string; entries: readonly MenuEntry[] }[] = [
  {
    id: 'rides',
    title: 'Rides',
    entries: [
      { id: 'my-rides', label: 'My rides', href: ROUTES.myRides, icon: RouteIcon },
      { id: 'saved-places', label: 'Saved places', href: ROUTES.savedPlaces, icon: MapPin },
    ],
  },
  {
    id: 'payments',
    title: 'Payments',
    entries: [
      {
        id: 'payment-methods',
        label: 'Payment methods',
        href: ROUTES.paymentMethods,
        icon: CreditCard,
      },
    ],
  },
  {
    id: 'help',
    title: 'Help',
    entries: [
      { id: 'help-support', label: 'Help & Support', href: ROUTES.helpSupport, icon: LifeBuoy },
      { id: 'notifications', label: 'Notifications', href: ROUTES.notifications, icon: Bell },
    ],
  },
  {
    id: 'app',
    title: 'App',
    entries: [
      { id: 'settings', label: 'Settings', href: ROUTES.settings, icon: Settings },
      { id: 'about', label: 'About E-GO', href: ROUTES.about, icon: Info },
    ],
  },
];

/** One row of the account menu. */
function MenuRow({ entry }: { entry: MenuEntry }) {
  const Icon = entry.icon;

  return (
    <Link
      href={entry.href}
      className="flex min-h-[60px] items-center gap-3 px-2 transition-colors hover:bg-navy-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2"
    >
      <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-navy-soft text-navy">
        <Icon aria-hidden="true" className="size-4" />
      </span>

      <span className="flex-1 text-sm font-medium text-navy">{entry.label}</span>

      <ChevronRight aria-hidden="true" className="size-5 shrink-0 text-muted" />
    </Link>
  );
}

/** The account hub of the passenger. */
export function ProfileScreen() {
  const router = useRouter();
  const { show } = useToast();

  const user = useAuthStore((state) => state.user);
  const logout = useAuthStore((state) => state.logout);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [loggingOut, setLoggingOut] = useState(false);

  if (!user) {
    return (
      <div className="mx-auto w-full max-w-2xl px-4 py-5 sm:px-6 lg:px-8">
        <EmptyState
          title="Please sign in"
          description="Log in to see your account."
          action={
            <Link
              href={ROUTES.login}
              className="text-sm font-semibold text-navy underline underline-offset-2"
            >
              Log in
            </Link>
          }
        />
      </div>
    );
  }

  const handleLogout = async () => {
    setLoggingOut(true);
    try {
      const result = await logout();
      if (!result.ok) {
        show({ message: result.error.message, tone: 'danger' });
        return;
      }

      setDialogOpen(false);
      router.replace(ROUTES.login);
    } finally {
      setLoggingOut(false);
    }
  };

  return (
    <div className="mx-auto w-full max-w-2xl px-4 py-5 sm:px-6 lg:px-8">
      <PageHeader
        title="Account"
        className="mb-5"
        action={
          <Link
            href={ROUTES.editProfile}
            className="inline-flex min-h-11 items-center gap-2 rounded-pill px-3 text-sm font-semibold text-navy transition-colors hover:bg-navy-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2"
          >
            <Pencil aria-hidden="true" className="size-4" />
            Edit
          </Link>
        }
      />

      <Card padding="lg" className="flex items-center gap-4">
        <Avatar name={user.fullName || 'E-GO user'} size="lg" />

        <div className="flex min-w-0 flex-1 flex-col">
          <span className="truncate font-display text-base font-semibold text-navy">
            {user.fullName || 'Set up profile'}
          </span>
          <span className="truncate text-sm text-muted">{user.phone}</span>
          {user.email ? (
            <span className="truncate text-sm text-muted">{user.email}</span>
          ) : null}
        </div>
      </Card>

      <div className="mt-4 flex flex-col gap-4">
        {MENU_SECTIONS.map((section) => (
          <Card key={section.id} padding="none" className="divide-y divide-line overflow-hidden">
            <p className="px-4 pt-4 text-xs font-semibold uppercase tracking-wider text-muted">
              {section.title}
            </p>

            <div className="py-1">
              {section.entries.map((entry) => (
                <MenuRow key={entry.id} entry={entry} />
              ))}
            </div>
          </Card>
        ))}

        <Button
          variant="secondary"
          fullWidth
          onClick={() => setDialogOpen(true)}
          className="justify-center"
        >
          <LogOut aria-hidden="true" className="size-4" />
          Log out
        </Button>
      </div>

      <div className="mt-8 flex flex-col items-center gap-1 text-center">
        <span className="font-display text-lg font-bold text-muted">E-GO</span>
        <span className="text-xs text-muted">Move your way - Jhargram</span>
      </div>

      <Dialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        title="Log out?"
        description="Are you sure you want to log out?"
        footer={
          <>
            <Button variant="secondary" onClick={() => setDialogOpen(false)} disabled={loggingOut}>
              Cancel
            </Button>
            <Button variant="danger" onClick={handleLogout} loading={loggingOut} disabled={loggingOut}>
              Log out
            </Button>
          </>
        }
      >
        <p className="text-sm text-muted">
          Your rides stay on this device - the demo keeps them in the browser.
        </p>
      </Dialog>
    </div>
  );
}

/** The menu entries (exported for the tests). */
export type { MenuEntry };
