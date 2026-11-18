import type { ReactNode } from 'react';

import { BottomNav } from '@/components/layout/bottom-nav';
import { Container } from '@/components/layout/container';
import { Sidebar } from '@/components/layout/sidebar';
import { TopBar } from '@/components/layout/top-bar';
import { DemoBanner } from '@/components/shared/demo-banner';

export interface AppShellProps {
  children: ReactNode;
  /** The number of unread notifications (the badge of the top bar). */
  unreadCount?: number;
}

/**
 * The frame of the protected screens.
 *
 * The sidebar is the navigation on a desktop, the bottom bar on a phone.
 * The component itself holds no state, so it may render on the server.
 */
export function AppShell({ children, unreadCount }: AppShellProps) {
  return (
    <>
      <Sidebar />

      <div className="lg:pl-64">
        <TopBar unreadCount={unreadCount} />

        <Container className="mt-3">
          <DemoBanner />
        </Container>

        <main id="main" className="pb-28 lg:pb-10">
          <Container className="py-5 lg:py-8">{children}</Container>
        </main>
      </div>

      <BottomNav />
    </>
  );
}
