'use client';

import Link from 'next/link';
import { LifeBuoy, Share2, ShieldAlert, ShieldCheck, type LucideIcon } from 'lucide-react';

import { PageHeader } from '@/components/layout/page-header';
import { FaqList } from '@/components/support/faq-list';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { useToast } from '@/components/ui/toast';
import { ROUTES } from '@/lib/config/routes';
import { safetyCopy } from '@/lib/domain/labels';

interface Guideline {
  id: string;
  icon: LucideIcon;
  title: string;
  description: string;
}

const GUIDELINES: readonly Guideline[] = [
  {
    id: 'verified-drivers',
    icon: ShieldCheck,
    title: safetyCopy.verifiedDrivers.title,
    description: safetyCopy.verifiedDrivers.description,
  },
  {
    id: 'share-trip',
    icon: Share2,
    title: safetyCopy.shareTrip.title,
    description: safetyCopy.shareTrip.description,
  },
  {
    id: 'helplines',
    icon: LifeBuoy,
    title: safetyCopy.helplines.title,
    description: safetyCopy.helplines.description,
  },
];

/** The safety tools: the SOS, the guidelines and the FAQ. */
export function SafetyScreen() {
  const { show } = useToast();

  return (
    <div className="mx-auto w-full max-w-2xl px-4 py-5 sm:px-6 lg:px-8">
      <PageHeader title="Safety" backHref={ROUTES.profile} className="mb-5" />

      <div className="flex flex-col gap-4">
        <Card padding="lg" className="border-danger bg-danger-soft/50 text-center">
          <span className="mx-auto flex size-14 items-center justify-center rounded-full bg-danger text-white">
            <ShieldAlert aria-hidden="true" className="size-7" />
          </span>

          <h2 className="mt-3 font-display text-xl font-bold text-navy">
            {safetyCopy.emergencyContacts.title}
          </h2>
          <p className="mt-1 text-sm text-muted">
            {safetyCopy.emergencyContacts.description}
          </p>

          <Button
            variant="danger"
            fullWidth
            className="mt-4 uppercase tracking-wide"
            onClick={() =>
              show({ message: safetyCopy.emergencyContacts.triggered, tone: 'warning' })
            }
          >
            {safetyCopy.emergencyContacts.cta}
          </Button>

          <p className="mt-3 text-xs text-muted">{safetyCopy.demoDisclaimer}</p>
        </Card>

        <h2 className="mt-2 font-display text-lg font-semibold text-navy">
          {safetyCopy.guidelinesTitle}
        </h2>

        <div className="flex flex-col gap-3">
          {GUIDELINES.map((guideline) => {
            const Icon = guideline.icon;

            return (
              <Card key={guideline.id} padding="lg">
                <div className="flex items-start gap-3">
                  <span className="flex size-11 shrink-0 items-center justify-center rounded-full bg-brand-soft text-navy">
                    <Icon aria-hidden="true" className="size-5" />
                  </span>

                  <div className="min-w-0 flex-1">
                    <h3 className="text-sm font-semibold text-navy">{guideline.title}</h3>
                    <p className="mt-1 text-sm leading-relaxed text-muted">
                      {guideline.description}
                    </p>

                    {guideline.id === 'share-trip' ? (
                      <Button
                        variant="secondary"
                        size="sm"
                        className="mt-3"
                        onClick={() =>
                          show({
                            message: 'Live ride sharing is simulated in this demo.',
                            tone: 'neutral',
                          })
                        }
                      >
                        {safetyCopy.shareTrip.cta}
                      </Button>
                    ) : null}

                    {guideline.id === 'helplines' ? (
                      <Link
                        href={ROUTES.helpSupport}
                        className="mt-3 inline-flex min-h-11 items-center rounded-pill px-3 text-sm font-semibold text-navy underline underline-offset-2 transition-colors hover:bg-navy-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2"
                      >
                        {safetyCopy.helplines.cta}
                      </Link>
                    ) : null}
                  </div>
                </div>
              </Card>
            );
          })}
        </div>

        <FaqList />

        <p className="text-center text-xs text-muted">{safetyCopy.demoDisclaimer}</p>
      </div>
    </div>
  );
}
