'use client';

import { useState, type ReactNode } from 'react';
import { useRouter } from 'next/navigation';
import { Check, ChevronRight, ExternalLink, Languages, LogOut, Trash2 } from 'lucide-react';

import { PageHeader } from '@/components/layout/page-header';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Dialog } from '@/components/ui/dialog';
import { Sheet } from '@/components/ui/sheet';
import { useToast } from '@/components/ui/toast';
import { ROUTES } from '@/lib/config/routes';
import { cn } from '@/lib/utils/cn';
import { useAuthStore } from '@/stores/auth-store';
import { clearEgoPersistence } from '@/stores/persist-storage';

/** The languages the demo offers. */
const LANGUAGES = [
  { value: 'en', label: 'English' },
  { value: 'bn', label: 'বাংলা (Bengali)' },
] as const;

type LanguageValue = (typeof LANGUAGES)[number]['value'];

/** The notification preferences of the demo (ephemeral, never persisted). */
interface NotificationPreference {
  id: string;
  label: string;
  description: string;
  enabled: boolean;
}

const INITIAL_PREFERENCES: readonly NotificationPreference[] = [
  {
    id: 'ride-status-alerts',
    label: 'Ride Status Alerts',
    description: 'Notifications when driver arrives or begins trip',
    enabled: true,
  },
  {
    id: 'sms-updates',
    label: 'SMS Updates',
    description: 'Receive important ride notifications via SMS',
    enabled: true,
  },
  {
    id: 'offers-discounts',
    label: 'Offers & Discounts',
    description: 'Special discounts and coupons for Jhargram rides',
    enabled: false,
  },
];

/** A card with a section heading. */
function SectionCard({ title, children }: { title: string; children: ReactNode }) {
  return (
    <Card padding="none" className="overflow-hidden">
      <h2 className="border-b border-line px-4 py-3 text-xs font-semibold uppercase tracking-wider text-muted">
        {title}
      </h2>
      {children}
    </Card>
  );
}

interface SwitchRowProps {
  id: string;
  label: string;
  description: string;
  checked: boolean;
  onToggle: () => void;
}

/** A labelled switch with a 44px hit target. */
function SwitchRow({ id, label, description, checked, onToggle }: SwitchRowProps) {
  const labelId = `${id}-label`;
  const descriptionId = `${id}-description`;

  return (
    <div className="flex items-start justify-between gap-4 px-4 py-3">
      <span className="flex min-w-0 flex-col gap-0.5">
        <span id={labelId} className="text-sm font-medium text-navy">
          {label}
        </span>
        <span id={descriptionId} className="text-xs text-muted">
          {description}
        </span>
      </span>

      <button
        type="button"
        role="switch"
        aria-checked={checked}
        aria-labelledby={labelId}
        aria-describedby={descriptionId}
        onClick={onToggle}
        className="inline-flex size-11 shrink-0 items-center justify-center rounded-full focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2"
      >
        <span
          aria-hidden="true"
          className={cn(
            'relative inline-flex h-6 w-11 items-center rounded-full transition-colors',
            checked ? 'bg-brand' : 'bg-navy-soft',
          )}
        >
          <span
            className={cn(
              'absolute left-0.5 size-5 rounded-full bg-white shadow-sm transition-transform',
              checked ? 'translate-x-5' : 'translate-x-0',
            )}
          />
        </span>
      </button>
    </div>
  );
}

/** The settings of the demo. */
export function SettingsScreen() {
  const router = useRouter();
  const { show } = useToast();

  const logout = useAuthStore((state) => state.logout);

  const [language, setLanguage] = useState<LanguageValue>('en');
  const [languageOpen, setLanguageOpen] = useState(false);
  const [preferences, setPreferences] = useState<NotificationPreference[]>(() =>
    INITIAL_PREFERENCES.map((preference) => ({ ...preference })),
  );
  const [clearDialogOpen, setClearDialogOpen] = useState(false);
  const [logoutDialogOpen, setLogoutDialogOpen] = useState(false);
  const [loggingOut, setLoggingOut] = useState(false);

  const currentLanguage = LANGUAGES.find((option) => option.value === language) ?? LANGUAGES[0];

  const togglePreference = (id: string) => {
    setPreferences((current) =>
      current.map((preference) =>
        preference.id === id ? { ...preference, enabled: !preference.enabled } : preference,
      ),
    );
  };

  const selectLanguage = (value: LanguageValue) => {
    setLanguage(value);
    setLanguageOpen(false);
  };

  const handleClearData = () => {
    // A full reload is intended: the stores and the mock database start fresh.
    clearEgoPersistence();
    window.location.assign(ROUTES.splash);
  };

  const handleLogout = async () => {
    setLoggingOut(true);
    try {
      const result = await logout();
      if (!result.ok) {
        show({ message: result.error.message, tone: 'danger' });
        return;
      }

      setLogoutDialogOpen(false);
      router.replace(ROUTES.login);
    } finally {
      setLoggingOut(false);
    }
  };

  return (
    <div className="mx-auto w-full max-w-2xl px-4 py-5 sm:px-6 lg:px-8">
      <PageHeader title="Settings" backHref={ROUTES.profile} className="mb-5" />

      <div className="flex flex-col gap-4">
        <SectionCard title="Preferences">
          <button
            type="button"
            onClick={() => setLanguageOpen(true)}
            className="flex min-h-[60px] w-full items-center gap-3 px-4 py-3 text-left transition-colors hover:bg-navy-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2"
          >
            <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-navy-soft text-navy">
              <Languages aria-hidden="true" className="size-4" />
            </span>

            <span className="flex min-w-0 flex-1 flex-col">
              <span className="text-sm font-medium text-navy">App Language</span>
              <span className="text-xs text-muted">{currentLanguage.label}</span>
            </span>

            <ChevronRight aria-hidden="true" className="size-5 shrink-0 text-muted" />
          </button>

          <p className="px-4 pb-3 text-xs text-muted">Language is not persisted in this demo.</p>
        </SectionCard>

        <SectionCard title="Notifications">
          <div className="divide-y divide-line">
            {preferences.map((preference) => (
              <SwitchRow
                key={preference.id}
                id={preference.id}
                label={preference.label}
                description={preference.description}
                checked={preference.enabled}
                onToggle={() => togglePreference(preference.id)}
              />
            ))}
          </div>
        </SectionCard>

        <SectionCard title="Privacy & Legal">
          <div className="divide-y divide-line">
            <button
              type="button"
              onClick={() => show({ message: 'E-GO Privacy Policy (Demo)' })}
              className="flex min-h-[60px] w-full items-center gap-3 px-4 py-3 text-left transition-colors hover:bg-navy-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2"
            >
              <span className="flex-1 text-sm font-medium text-navy">Privacy Policy</span>
              <ExternalLink aria-hidden="true" className="size-4 shrink-0 text-muted" />
            </button>

            <button
              type="button"
              onClick={() => show({ message: 'E-GO Terms of Service (Demo)' })}
              className="flex min-h-[60px] w-full items-center gap-3 px-4 py-3 text-left transition-colors hover:bg-navy-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2"
            >
              <span className="flex-1 text-sm font-medium text-navy">Terms of Service</span>
              <ExternalLink aria-hidden="true" className="size-4 shrink-0 text-muted" />
            </button>
          </div>
        </SectionCard>

        <SectionCard title="Demo data">
          <div className="p-4">
            <Button
              variant="secondary"
              fullWidth
              className="border-danger text-danger hover:bg-danger-soft"
              leftIcon={<Trash2 aria-hidden="true" className="size-4" />}
              onClick={() => setClearDialogOpen(true)}
            >
              Clear demo data
            </Button>
          </div>
        </SectionCard>

        <Button
          variant="secondary"
          fullWidth
          className="border-danger text-danger hover:bg-danger-soft"
          leftIcon={<LogOut aria-hidden="true" className="size-4" />}
          onClick={() => setLogoutDialogOpen(true)}
        >
          Log out
        </Button>
      </div>

      <div className="mt-8 flex flex-col items-center gap-1 text-center">
        <span className="text-xs font-semibold text-muted">v0.1.0-alpha - Jhargram, WB</span>
        <span className="text-xs text-muted">
          All settings are simulated and stored in this browser only.
        </span>
      </div>

      {languageOpen ? (
        <Sheet
          open
          side="bottom"
          title="Choose Language"
          onClose={() => setLanguageOpen(false)}
        >
          <div className="flex flex-col gap-2">
            {LANGUAGES.map((option) => (
              <label
                key={option.value}
                className={cn(
                  'flex min-h-[52px] cursor-pointer items-center gap-3 rounded-card border px-3 transition-colors',
                  'focus-within:ring-2 focus-within:ring-navy focus-within:ring-offset-2',
                  language === option.value
                    ? 'border-brand bg-brand-soft/60'
                    : 'border-line bg-white hover:bg-navy-soft',
                )}
              >
                <input
                  type="radio"
                  name="app-language"
                  value={option.value}
                  checked={language === option.value}
                  onChange={() => selectLanguage(option.value)}
                  className="sr-only"
                />
                <span className="flex-1 text-sm font-medium text-navy">{option.label}</span>
                {language === option.value ? (
                  <Check aria-hidden="true" className="size-5 shrink-0 text-navy" />
                ) : null}
              </label>
            ))}
          </div>
        </Sheet>
      ) : null}

      <Dialog
        open={clearDialogOpen}
        onClose={() => setClearDialogOpen(false)}
        title="Clear demo data?"
        description="This removes your local demo rides, saved places, notifications and session. The demo account is seeded again after you log in."
        footer={
          <>
            <Button variant="secondary" onClick={() => setClearDialogOpen(false)}>
              Cancel
            </Button>
            <Button variant="danger" onClick={handleClearData}>
              Clear data
            </Button>
          </>
        }
      />

      <Dialog
        open={logoutDialogOpen}
        onClose={() => setLogoutDialogOpen(false)}
        title="Log out?"
        description="Are you sure you want to log out of E-GO?"
        footer={
          <>
            <Button
              variant="secondary"
              onClick={() => setLogoutDialogOpen(false)}
              disabled={loggingOut}
            >
              Cancel
            </Button>
            <Button
              variant="danger"
              onClick={handleLogout}
              loading={loggingOut}
              disabled={loggingOut}
            >
              Log Out
            </Button>
          </>
        }
      />
    </div>
  );
}
