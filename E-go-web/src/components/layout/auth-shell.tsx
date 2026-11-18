import type { ReactNode } from 'react';

import { Container } from '@/components/layout/container';
import { Logo } from '@/components/shared/logo';
import { Card } from '@/components/ui/card';

export interface AuthShellProps {
  /** The headline of the page (a node, so a line break may be included). */
  title: ReactNode;
  description?: string;
  children: ReactNode;
  /** A line under the card (the legal text, a link to the login, ...). */
  footer?: ReactNode;
}

/**
 * The frame of the public pages (login, registration, OTP, onboarding).
 *
 * The shell owns the brand band, the logo and the white card - the page
 * owns everything inside the card.
 */
export function AuthShell({ title, description, children, footer }: AuthShellProps) {
  return (
    <main id="main" className="relative flex min-h-dvh flex-col bg-surface">
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-x-0 top-0 h-72 bg-linear-to-b from-brand-soft to-surface"
      />

      <Container size="narrow" className="relative flex flex-1 flex-col items-center justify-center py-10">
        <div className="mb-6 flex justify-center">
          <Logo href={null} showTagline />
        </div>

        <Card padding="none" className="w-full p-6 sm:p-8">
          <div className="space-y-1">
            <h1 className="font-display text-2xl font-bold text-navy">{title}</h1>
            {description ? <p className="text-sm text-muted">{description}</p> : null}
          </div>

          <div className="mt-6">{children}</div>
        </Card>

        {footer ? <div className="mt-6 text-center text-sm text-muted">{footer}</div> : null}
      </Container>
    </main>
  );
}
