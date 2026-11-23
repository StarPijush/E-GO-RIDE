import type { Metadata } from 'next';

import { SafetyScreen } from '@/components/support/safety-screen';
import { ROUTE_METADATA } from '@/lib/config/routes';

const meta = ROUTE_METADATA.safety;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function SafetyPage() {
  return <SafetyScreen />;
}
