'use client';

import { useEffect, useState } from 'react';
import { Bell, Car, CreditCard, Tag, type LucideIcon } from 'lucide-react';

import { PageHeader } from '@/components/layout/page-header';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { EmptyState } from '@/components/ui/empty-state';
import { ErrorState } from '@/components/ui/error-state';
import { Skeleton } from '@/components/ui/skeleton';
import { useToast } from '@/components/ui/toast';
import { ROUTES } from '@/lib/config/routes';
import type { AppNotification } from '@/lib/domain/types';
import { useAsyncData } from '@/lib/hooks/use-async-data';
import { getRepositories } from '@/lib/repositories';
import { cn } from '@/lib/utils/cn';
import { formatDate, formatRelativeTime } from '@/lib/utils/format';
import { useAuthStore } from '@/stores/auth-store';

/** The icon chip of each notification kind. */
const KIND_ICONS: Record<AppNotification['kind'], LucideIcon> = {
  ride: Car,
  payment: CreditCard,
  promo: Tag,
  system: Bell,
};

/** The inbox of the passenger. */
export function NotificationsScreen() {
  const { show } = useToast();

  const user = useAuthStore((state) => state.user);
  const userId = user?.id ?? '';

  const notifications = useAsyncData(
    () => getRepositories().notifications.list(userId),
    [userId],
    { enabled: Boolean(user) },
  );

  // Relative labels depend on the clock, so they are rendered only after the
  // mount - the first client render matches the server render.
  const [now, setNow] = useState<number | null>(null);
  const [markingAll, setMarkingAll] = useState(false);
  const [pendingId, setPendingId] = useState<string | null>(null);

  useEffect(() => {
    // Mount-only clock read: the first client render must match the server
    // render, so the cascading-render concern of the rule does not apply.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setNow(Date.now());
  }, []);

  const unreadCount = (notifications.data ?? []).filter((notification) => !notification.read).length;

  const handleMarkAllRead = async () => {
    if (unreadCount === 0) return;

    setMarkingAll(true);
    try {
      const result = await getRepositories().notifications.markAllRead(userId);
      if (!result.ok) {
        show({ message: result.error.message, tone: 'danger' });
        return;
      }

      show({ message: 'All notifications marked as read.', tone: 'success' });
      notifications.reload();
    } finally {
      setMarkingAll(false);
    }
  };

  const handleOpen = async (notification: AppNotification) => {
    // A read notification stays read - opening it is a no-op.
    if (notification.read) return;

    setPendingId(notification.id);
    try {
      const result = await getRepositories().notifications.markRead(userId, notification.id);
      if (!result.ok) {
        show({ message: result.error.message, tone: 'danger' });
        return;
      }

      notifications.reload();
    } finally {
      setPendingId(null);
    }
  };

  return (
    <div className="mx-auto w-full max-w-2xl px-4 py-5 sm:px-6 lg:px-8">
      <PageHeader
        title="Notifications"
        backHref={ROUTES.home}
        className="mb-5"
        action={
          unreadCount > 0 ? (
            <Button
              variant="ghost"
              size="sm"
              loading={markingAll}
              disabled={markingAll}
              onClick={handleMarkAllRead}
            >
              Mark all read
            </Button>
          ) : null
        }
      />

      {notifications.loading ? (
        <div className="flex flex-col gap-3">
          <Skeleton className="h-[88px] w-full rounded-card" />
          <Skeleton className="h-[88px] w-full rounded-card" />
          <Skeleton className="h-[88px] w-full rounded-card" />
        </div>
      ) : notifications.error ? (
        <ErrorState
          title="Notifications could not be loaded"
          message="Please try again."
          onRetry={notifications.reload}
        />
      ) : notifications.data && notifications.data.length > 0 ? (
        <div className="flex flex-col gap-3">
          {notifications.data.map((notification) => {
            const Icon = KIND_ICONS[notification.kind];
            const pending = pendingId === notification.id;

            return (
              <button
                key={notification.id}
                type="button"
                disabled={pending}
                onClick={() => handleOpen(notification)}
                className={cn(
                  'flex min-h-[72px] w-full items-start gap-3 rounded-card border p-4 text-left transition-colors',
                  'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2',
                  'disabled:cursor-not-allowed disabled:opacity-60',
                  notification.read
                    ? 'border-line bg-white hover:bg-navy-soft'
                    : 'border-brand bg-brand-soft/60 hover:bg-brand-soft',
                )}
              >
                <span
                  className={cn(
                    'flex size-10 shrink-0 items-center justify-center rounded-full text-navy',
                    notification.read ? 'bg-brand-soft' : 'bg-white',
                  )}
                >
                  <Icon aria-hidden="true" className="size-5" />
                </span>

                <span className="flex min-w-0 flex-1 flex-col gap-0.5">
                  <span
                    className={cn(
                      'text-sm text-navy',
                      notification.read ? 'font-semibold' : 'font-bold',
                    )}
                  >
                    {notification.title}
                  </span>
                  <span className="text-sm text-muted">{notification.body}</span>
                  <time dateTime={notification.createdAt} className="text-xs text-muted">
                    {now !== null
                      ? formatRelativeTime(notification.createdAt, now)
                      : formatDate(notification.createdAt)}
                  </time>
                </span>

                {notification.read ? null : (
                  <span className="mt-1 flex shrink-0 items-center gap-1">
                    <span aria-hidden="true" className="size-2 rounded-full bg-brand" />
                    <span className="sr-only">Unread</span>
                  </span>
                )}
              </button>
            );
          })}
        </div>
      ) : (
        <EmptyState
          title="No notifications"
          description="We'll notify you about your rides and offers here."
        />
      )}

      <Card padding="lg" className="mt-4 border-warning bg-warning-soft/40">
        <p className="text-xs text-navy/80">
          Notifications are local to this demo - no push or SMS is sent.
        </p>
      </Card>
    </div>
  );
}
