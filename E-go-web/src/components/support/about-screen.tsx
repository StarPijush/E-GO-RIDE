import Image from 'next/image';

import { PageHeader } from '@/components/layout/page-header';
import { Card } from '@/components/ui/card';
import { ROUTES } from '@/lib/config/routes';
import { authCopy } from '@/lib/domain/labels';

const MISSION =
  'E-GO is built specifically for Jhargram - connecting passengers with local Toto (E-Rickshaw) and Bike drivers through simple, transparent, and fair pricing. No hidden surge, no complicated apps.';

const REGION: readonly string[] = [
  'Jhargram Railway Station & Bus Terminus',
  'Jhargram Rajbari & Palace Grounds',
  'Jhargram Super Speciality Hospital',
  'Jhargram DM Office & Court Complex',
  'Ghoradhara & Jamda Localities',
];

const VEHICLES: readonly { id: string; name: string; description: string }[] = [
  {
    id: 'toto',
    name: 'Toto (E-Rickshaw)',
    description: 'Electric, eco-friendly 3-wheelers. Up to 3 passengers with light luggage.',
  },
  {
    id: 'bike',
    name: 'Bike Ride',
    description: 'Fast single-passenger motorbike rides for quick trips across town.',
  },
];

/** The story, the region and the vehicles of E-GO. */
export function AboutScreen() {
  return (
    <div className="mx-auto w-full max-w-2xl px-4 py-5 sm:px-6 lg:px-8">
      <PageHeader title="About E-GO" backHref={ROUTES.profile} className="mb-5" />

      <div className="flex flex-col items-center gap-3 text-center">
        <Image
          src="/branding/ego_logo_primary.png"
          alt="E-GO"
          width={440}
          height={391}
          className="h-24 w-auto object-contain"
        />

        <p className="text-sm font-medium text-navy">{authCopy.appTagline}</p>

        <span className="rounded-pill bg-brand-soft px-3 py-1 text-xs font-semibold text-navy">
          v0.1.0-alpha - Jhargram, WB
        </span>
      </div>

      <div className="mt-6 flex flex-col gap-4">
        <Card as="section" padding="lg">
          <h2 className="font-display text-lg font-semibold text-navy">Our mission</h2>
          <p className="mt-2 text-sm leading-relaxed text-muted">{MISSION}</p>
        </Card>

        <Card as="section" padding="lg">
          <h2 className="font-display text-lg font-semibold text-navy">Operating region</h2>
          <ul className="mt-2 list-disc space-y-1 pl-5 text-sm leading-relaxed text-muted">
            {REGION.map((place) => (
              <li key={place}>{place}</li>
            ))}
          </ul>
        </Card>

        <Card as="section" padding="lg">
          <h2 className="font-display text-lg font-semibold text-navy">Vehicle categories</h2>
          <ul className="mt-3 flex flex-col gap-4">
            {VEHICLES.map((vehicle) => (
              <li key={vehicle.id}>
                <p className="text-sm font-semibold text-navy">{vehicle.name}</p>
                <p className="mt-1 text-sm leading-relaxed text-muted">{vehicle.description}</p>
              </li>
            ))}
          </ul>
        </Card>
      </div>

      <footer className="mt-8 flex flex-col items-center gap-1 text-center">
        <p className="text-xs font-semibold text-muted">© 2026 E-GO. All rights reserved.</p>
        <p className="text-xs text-muted">Made for the people of Jhargram.</p>
        <p className="mt-2 text-xs text-muted">
          This is a browser demo - no real rides, payments or emergency services are provided.
        </p>
      </footer>
    </div>
  );
}
