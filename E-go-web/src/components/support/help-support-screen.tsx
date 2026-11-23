'use client';

import Link from 'next/link';
import { Headphones, ShieldAlert } from 'lucide-react';
import { useState } from 'react';

import { PageHeader } from '@/components/layout/page-header';
import { FaqList } from '@/components/support/faq-list';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Dialog } from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import { useToast } from '@/components/ui/toast';
import { ROUTES } from '@/lib/config/routes';
import { safetyCopy } from '@/lib/domain/labels';

const REPORT_DESCRIPTION =
  'Describe your concern or feedback regarding your ride experience in Jhargram:';

const REPORT_NOTE = 'Reports are simulated in this demo.';

/** The help hub: the support desk, the FAQ and the safety shortcut. */
export function HelpSupportScreen() {
  const { show } = useToast();

  const [reportOpen, setReportOpen] = useState(false);
  const [report, setReport] = useState('');

  const canSubmit = report.trim().length > 0;

  const handleSubmit = () => {
    if (!canSubmit) return;

    setReportOpen(false);
    setReport('');
    show({
      message: 'Issue report submitted! Our support team will review it.',
      tone: 'success',
    });
  };

  return (
    <div className="mx-auto w-full max-w-2xl px-4 py-5 sm:px-6 lg:px-8">
      <PageHeader title="Help & Support" backHref={ROUTES.profile} className="mb-5" />

      <div className="flex flex-col gap-4">
        <section className="rounded-card bg-linear-to-br from-brand to-brand-strong p-5 text-navy">
          <span className="flex size-12 items-center justify-center rounded-full bg-white/30">
            <Headphones aria-hidden="true" className="size-6" />
          </span>

          <h2 className="mt-3 font-display text-xl font-bold">{safetyCopy.supportTitle}</h2>
          <p className="mt-1 text-sm text-navy/80">{safetyCopy.supportDescription}</p>

          <Button
            variant="secondary"
            className="mt-4"
            onClick={() => setReportOpen(true)}
          >
            {safetyCopy.reportIssue}
          </Button>
        </section>

        <FaqList />

        <Card padding="lg" className="border-danger bg-danger-soft/50">
          <span className="flex size-12 items-center justify-center rounded-full bg-danger-soft text-danger">
            <ShieldAlert aria-hidden="true" className="size-6" />
          </span>

          <h2 className="mt-3 font-display text-xl font-bold text-navy">Emergency & Safety</h2>
          <p className="mt-1 text-sm text-muted">
            Your safety is our highest priority during every ride.
          </p>

          <div className="mt-4 flex flex-col gap-2 sm:flex-row sm:items-center">
            <Button
              variant="secondary"
              className="border-danger text-danger hover:bg-danger-soft"
              onClick={() =>
                show({
                  message: 'Emergency alert triggered (Simulated in demo).',
                  tone: 'warning',
                })
              }
            >
              Emergency SOS (Mock)
            </Button>

            <Link
              href={ROUTES.safety}
              className="inline-flex min-h-11 items-center justify-center rounded-pill px-3 text-sm font-semibold text-navy underline underline-offset-2 transition-colors hover:bg-navy-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2"
            >
              Open safety tools
            </Link>
          </div>
        </Card>

        <p className="text-center text-xs text-muted">{safetyCopy.demoDisclaimer}</p>
      </div>

      <Dialog
        open={reportOpen}
        onClose={() => setReportOpen(false)}
        title="Report an Issue"
        description={REPORT_DESCRIPTION}
        footer={
          <>
            <Button variant="secondary" onClick={() => setReportOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleSubmit} disabled={!canSubmit}>
              Submit
            </Button>
          </>
        }
      >
        <Textarea
          label="Your report"
          rows={4}
          placeholder="e.g. Driver requested excess cash, app map issue, etc."
          maxLength={500}
          value={report}
          onChange={(event) => setReport(event.target.value)}
        />

        <p className="mt-2 text-xs text-muted">{REPORT_NOTE}</p>
      </Dialog>
    </div>
  );
}
