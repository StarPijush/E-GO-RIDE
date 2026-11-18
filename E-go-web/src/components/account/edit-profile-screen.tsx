'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

import { PageHeader } from '@/components/layout/page-header';
import { Avatar } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { EmptyState } from '@/components/ui/empty-state';
import { Input } from '@/components/ui/input';
import { useToast } from '@/components/ui/toast';
import { ROUTES } from '@/lib/config/routes';
import { useAuthStore } from '@/stores/auth-store';

/** The pattern of a valid email address. */
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function EditProfileScreen() {
  const router = useRouter();
  const { show } = useToast();

  const user = useAuthStore((state) => state.user);
  const updateProfile = useAuthStore((state) => state.updateProfile);
  const pending = useAuthStore((state) => state.pending);

  // The store holds the values at the moment the screen was mounted.
  const [fullName, setFullName] = useState(() => useAuthStore.getState().user?.fullName ?? '');
  const [email, setEmail] = useState(() => useAuthStore.getState().user?.email ?? '');

  const [nameError, setNameError] = useState<string | null>(null);
  const [emailError, setEmailError] = useState<string | null>(null);
  const [formError, setFormError] = useState<string | null>(null);

  if (!user) {
    return (
      <div className="mx-auto w-full max-w-2xl px-4 py-5 sm:px-6 lg:px-8">
        <EmptyState
          title="Please sign in"
          description="Log in to edit your profile."
          action={
            <Link
              href={ROUTES.login}
              className="text-sm font-semibold text-navy underline underline-offset-2"
            >
              Log in
            </Link>
          }
        />
      </div>
    );
  }

  const handleSubmit = async () => {
    setNameError(null);
    setEmailError(null);
    setFormError(null);

    const name = fullName.trim();
    if (name.length === 0) {
      setNameError('Please enter your full name.');
      return;
    }
    if (name.length < 2) {
      setNameError('Name is too short.');
      return;
    }

    const trimmedEmail = email.trim();
    if (trimmedEmail.length > 0 && !EMAIL_PATTERN.test(trimmedEmail)) {
      setEmailError('Please enter a valid email address.');
      return;
    }

    const result = await updateProfile({
      fullName: name,
      email: trimmedEmail.length > 0 ? trimmedEmail : undefined,
    });

    if (!result.ok) {
      setFormError(result.error.message);
      return;
    }

    show({ message: 'Profile updated.', tone: 'success' });
    router.replace(ROUTES.profile);
  };

  return (
    <div className="mx-auto w-full max-w-2xl px-4 py-5 sm:px-6 lg:px-8">
      <PageHeader title="Edit profile" backHref={ROUTES.profile} className="mb-5" />

      <Card padding="lg" className="mb-4 flex flex-col items-center gap-2 text-center">
        <Avatar name={user.fullName || 'E-GO user'} size="lg" />
        <p className="text-xs text-muted">This demo uses your initials.</p>
      </Card>

      <form
        noValidate
        onSubmit={(event) => {
          event.preventDefault();
          void handleSubmit();
        }}
        className="flex flex-col gap-4"
      >
        <Input
          label="Full name"
          required
          value={fullName}
          disabled={pending !== null}
          error={nameError ?? undefined}
          onChange={(event) => {
            setFullName(event.target.value);
            setNameError(null);
          }}
        />

        <Input
          label="Email (optional)"
          type="email"
          value={email}
          disabled={pending !== null}
          error={emailError ?? undefined}
          onChange={(event) => {
            setEmail(event.target.value);
            setEmailError(null);
          }}
        />

        <Input
          label="Phone number"
          value={user.phone}
          disabled
          readOnly
          hint="Phone changes are not available in this demo."
        />

        {formError ? (
          <p role="alert" className="rounded-field bg-danger-soft px-3 py-2 text-sm text-danger">
            {formError}
          </p>
        ) : null}

        <Button type="submit" fullWidth loading={pending === 'profile'} disabled={pending !== null}>
          Save changes
        </Button>
      </form>
    </div>
  );
}
