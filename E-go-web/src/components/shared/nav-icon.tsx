import { Bell, Circle, Home, LifeBuoy, Plus, Route, UserRound, type LucideIcon } from 'lucide-react';

import { cn } from '@/lib/utils/cn';

/** The icons of the navigation. */
export type NavIconName = 'home' | 'route' | 'bell' | 'plus' | 'user-round' | 'life-buoy';

/** The icon of every navigation entry. */
const NAV_ICONS: Record<NavIconName, LucideIcon> = {
  home: Home,
  route: Route,
  bell: Bell,
  plus: Plus,
  'user-round': UserRound,
  'life-buoy': LifeBuoy,
};

export interface NavIconProps {
  /** The name of the icon - an unknown name falls back to a circle. */
  name: string;
  className?: string;
}

/** The icon of a navigation entry (always decorative). */
export function NavIcon({ name, className }: NavIconProps) {
  const Icon = (NAV_ICONS as Record<string, LucideIcon>)[name] ?? Circle;

  return <Icon aria-hidden="true" className={cn('size-5', className)} />;
}
