'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState, type FormEvent } from 'react';

import { PasswordInput } from '@/components/auth/password-input';
import { AuthShell } from '@/components/layout/auth-shell';
import { Badge, Button, Input, useToast } from '@/components/ui';
import { ROUTES } from '@/lib/config/routes';
import { authCopy } from '@/lib/domain/labels';
import { normalizePhoneDigits } from '@/lib/utils/phone';
import { useAuthStore } from '@/stores/auth-store';

/** The pattern of a valid email address. */
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const linkClass =
  'font-semibold text-navy underline underline-offset-2 transition-colors hover:text-navy/80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2';

export function CreateAccountForm() {
  const router = useRouter();
  const { show } = useToast();

  const register = useAuthStore((state) => state.register);
  const pending = useAuthStore((state) => state.pending);

  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [localError, setLocalError] = useState<string | null>(null);

  const submitting = pending === 'register';

  const clearError = () => setLocalError(null);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    clearError();

    const name = fullName.trim();
    if (name.length < 2) {
      setLocalError(authCopy.errors.invalidName);
      return;
    }

    const digits = normalizePhoneDigits(phone);
    if (!digits) {
      setLocalError(authCopy.errors.invalidPhone);
      return;
    }

    const trimmedEmail = email.trim();
    if (trimmedEmail.length > 0 && !EMAIL_PATTERN.test(trimmedEmail)) {
      setLocalError(authCopy.errors.invalidEmail);
      return;
    }

    if (password.length < 8) {
      setLocalError(authCopy.errors.weakPassword);
      return;
    }

    const result = await register({
      fullName: name,
      phone: digits,
      email: trimmedEmail.length > 0 ? trimmedEmail : undefined,
      password,
    });

    if (!result.ok) {
      // The adapter knows the reason best (the account exists, the hashing
      // failed, ...).
      setLocalError(result.error.message);
      return;
    }

    show({ message: 'Account created. Verify your number.', tone: 'success' });
    router.push(
      `${ROUTES.otp}?phone=${digits}&mode=register&returnTo=${encodeURIComponent(ROUTES.home)}`,
    );
  };

  return (
    <AuthShell
      title={authCopy.createAccount.title}
      description={authCopy.createAccount.subtitle}
      footer={
        <p>
          Already have an account?{' '}
          <Link href={ROUTES.login} className={linkClass}>
            Log in
          </Link>
        </p>
      }
    >
      <div className="mb-4 flex justify-center">
        <Badge tone="neutral">Step 1 of 2</Badge>
      </div>

      <form noValidate onSubmit={handleSubmit} className="flex flex-col gap-4">
        <Input
          label="Full name"
          autoComplete="name"
          placeholder={authCopy.createAccount.fullNamePlaceholder}
          value={fullName}
          disabled={submitting}
          onChange={(event) => {
            setFullName(event.target.value);
            clearError();
          }}
        />

        <Input
          label="Phone number"
          type="tel"
          inputMode="tel"
          autoComplete="tel"
          placeholder={authCopy.createAccount.phonePlaceholder}
          maxLength={16}
          value={phone}
          disabled={submitting}
          onChange={(event) => {
            setPhone(event.target.value);
            clearError();
          }}
        />

        <Input
          label={
            <span className="inline-flex items-center gap-2">
              Email address
              <Badge tone="neutral">Optional</Badge>
            </span>
          }
          type="email"
          autoComplete="email"
          placeholder={authCopy.createAccount.emailPlaceholder}
          value={email}
          disabled={submitting}
          onChange={(event) => {
            setEmail(event.target.value);
            clearError();
          }}
        />

        <PasswordInput
          label="Password"
          autoComplete="new-password"
          placeholder={authCopy.createAccount.passwordPlaceholder}
          value={password}
          disabled={submitting}
          onChange={(event) => {
            setPassword(event.target.value);
            clearError();
          }}
        />

        {localError ? (
          <p role="alert" className="rounded-field bg-danger-soft px-3 py-2 text-sm text-danger">
            {localError}
          </p>
        ) : null}

        <Button type="submit" fullWidth loading={submitting} disabled={submitting}>
          Create account
        </Button>
      </form>
    </AuthShell>
  );
}
