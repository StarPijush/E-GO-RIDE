import type { Metadata } from 'next';

import { AboutScreen } from '@/components/support/about-screen';
import { ROUTE_METADATA } from '@/lib/config/routes';

const meta = ROUTE_METADATA.about;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function AboutPage() {
  return <AboutScreen />;
}
