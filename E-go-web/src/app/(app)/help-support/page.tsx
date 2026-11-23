import type { Metadata } from 'next';

import { HelpSupportScreen } from '@/components/support/help-support-screen';
import { ROUTE_METADATA } from '@/lib/config/routes';

const meta = ROUTE_METADATA.helpSupport;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function HelpSupportPage() {
  return <HelpSupportScreen />;
}
