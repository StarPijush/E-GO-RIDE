'use client';

import { useRouter } from 'next/navigation';
import { Banknote, QrCode } from 'lucide-react';

import { PageHeader } from '@/components/layout/page-header';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { EmptyState } from '@/components/ui/empty-state';
import { ErrorState } from '@/components/ui/error-state';
import { Skeleton } from '@/components/ui/skeleton';
import { useToast } from '@/components/ui/toast';
import { ROUTES } from '@/lib/config/routes';
import { useAsyncData } from '@/lib/hooks/use-async-data';
import { getRepositories } from '@/lib/repositories';
import { useAuthStore } from '@/stores/auth-store';

/**
 * The payment methods of the passenger.
 *
 * Only cash is selectable (A9): UPI is shown as "coming soon" and no payment
 * data is ever collected.
 */
export function PaymentMethodsScreen() {
  const router = useRouter();
  const { show } = useToast();

  const user = useAuthStore((state) => state.user);
  const userId = user?.id ?? '';

  const methods = useAsyncData(
    () => getRepositories().payments.list(userId),
    [userId],
    { enabled: Boolean(user) },
  );

  const cash = methods.data?.find((method) => method.type === 'cash');
  const isDefault = cash?.isDefault ?? false;

  const handleSelectCash = async () => {
    if (!cash) return;

    const result = await getRepositories().payments.setDefault(userId, cash.id);
    if (!result.ok) {
      show({ message: result.error.message, tone: 'danger' });
      return;
    }

    show({ message: 'Payment set to Cash.', tone: 'success' });
    methods.reload();
  };

  return (
    <div className="mx-auto w-full max-w-2xl px-4 py-5 sm:px-6 lg:px-8">
      <PageHeader title="Payment methods" backHref={ROUTES.profile} className="mb-5" />

      <h2 className="mb-3 text-sm font-semibold text-navy">Preferred payment</h2>

      {methods.loading ? (
        <div className="flex flex-col gap-3">
          <Skeleton className="h-20 w-full rounded-card" />
          <Skeleton className="h-20 w-full rounded-card" />
        </div>
      ) : methods.error ? (
        <ErrorState
          title="The payment methods could not be loaded"
          message="Please try again."
          onRetry={methods.reload}
        />
      ) : (
        <div className="flex flex-col gap-3">
          <button
            type="button"
            onClick={handleSelectCash}
            aria-pressed={isDefault}
            className="flex min-h-[72px] w-full items-center gap-3 rounded-card border-2 border-line bg-white p-4 text-left transition-colors hover:bg-navy-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2"
          >
            <span className="flex size-10 shrink-0 items-center justify-center rounded-full bg-success-soft text-success">
              <Banknote aria-hidden="true" className="size-5" />
            </span>

            <span className="flex min-w-0 flex-1 flex-col">
              <span className="text-sm font-semibold text-navy">Cash</span>
              <span className="text-xs text-muted">Pay directly to your rider or toto driver</span>
            </span>

            <Badge tone={isDefault ? 'success' : 'neutral'}>{isDefault ? 'Active' : 'Default'}</Badge>
          </button>

          <button
            type="button"
            disabled
            aria-disabled="true"
            className="flex min-h-[72px] w-full cursor-not-allowed items-center gap-3 rounded-card border-2 border-line bg-white p-4 text-left opacity-60"
          >
            <span className="flex size-10 shrink-0 items-center justify-center rounded-full bg-navy-soft text-navy">
              <QrCode aria-hidden="true" className="size-5" />
            </span>

            <span className="flex min-w-0 flex-1 flex-col">
              <span className="text-sm font-semibold text-navy">UPI (GPay, PhonePe, Paytm)</span>
              <span className="text-xs text-muted">Pay via UPI QR code upon arrival</span>
            </span>

            <Badge tone="warning">Coming soon</Badge>
          </button>
        </div>
      )}

      <Card padding="lg" className="mt-4 border-warning bg-warning-soft/40">
        <p className="text-sm font-semibold text-navy">Payment Notice</p>
        <p className="mt-1 text-xs text-navy/80">
          In this preview release of E-GO, payments are simulated. No real monetary transactions or
          banking APIs are connected.
        </p>
      </Card>

      <Button fullWidth className="mt-4" onClick={() => router.replace(ROUTES.profile)}>
        Done
      </Button>
    </div>
  );
}

/** The empty state is used when the passenger has no method at all. */
export function PaymentMethodsEmpty() {
  return (
    <EmptyState
      title="No payment methods"
      description="Cash is the default method of this demo."
    />
  );
}
