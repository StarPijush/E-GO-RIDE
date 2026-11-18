"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { Eye, EyeOff } from "lucide-react";

import { AuthShell } from "@/components/layout/auth-shell";
import { Button, Card, IconButton, Input, useToast } from "@/components/ui";
import { ROUTES } from "@/lib/config/routes";
import { authCopy, errorMessage } from "@/lib/domain/labels";
import { getDemoCredentials } from "@/lib/repositories";
import { normalizePhoneDigits } from "@/lib/utils/phone";
import { useAuthStore } from "@/stores/auth-store";

export interface LoginFormProps {
  /** Where the passenger goes after a successful login. */
  returnTo: string;
}

/** The link class of the footer links. */
const linkClass =
  'font-semibold text-navy underline underline-offset-2 transition-colors hover:text-navy/80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2';

export function LoginForm({ returnTo }: LoginFormProps) {
  const router = useRouter();
  const { show } = useToast();

  const login = useAuthStore((state) => state.login);
  const requestOtp = useAuthStore((state) => state.requestOtp);
  const pending = useAuthStore((state) => state.pending);

  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [passwordVisible, setPasswordVisible] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  const submitting = pending === 'login';
  const otpSubmitting = pending === 'requestOtp';
  const busy = submitting || otpSubmitting;

  // The demo credentials only exist while demo mode is enabled.
  const demo = getDemoCredentials();

  const clearError = () => setLocalError(null);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    clearError();

    const digits = normalizePhoneDigits(phone);
    if (!digits) {
      setLocalError(authCopy.errors.invalidPhone);
      return;
    }
    if (password.length === 0) {
      setLocalError(authCopy.errors.invalidPassword);
      return;
    }

    const result = await login(phone, password);
    if (!result.ok) {
      setLocalError(errorMessage(result.error));
      return;
    }

    show({ message: 'Welcome back.', tone: 'success' });
    router.replace(returnTo);
  };

  const handleOtpLogin = async () => {
    clearError();

    const digits = normalizePhoneDigits(phone);
    if (!digits) {
      setLocalError(authCopy.errors.invalidPhone);
      return;
    }

    const result = await requestOtp(digits);
    if (!result.ok) {
      setLocalError(errorMessage(result.error));
      return;
    }

    // The code was already requested here - the OTP page must not ask again.
    router.push(
      `${ROUTES.otp}?phone=${digits}&mode=login&sent=1&returnTo=${encodeURIComponent(returnTo)}`,
    );
  };

  const handleDemoLogin = async () => {
    if (!demo) return;
    clearError();

    const result = await login(demo.phone, demo.password);
    if (!result.ok) {
      setLocalError(errorMessage(result.error));
      return;
    }

    show({ message: 'Welcome back.', tone: 'success' });
    router.replace(returnTo);
  };

  return (
    <AuthShell
      title="Log in"
      description="Welcome back. Use your phone and password to continue."
      footer={
        <div className="flex flex-col items-center gap-2">
          <p>
            New to E-GO?{' '}
            <Link href={ROUTES.createAccount} className={linkClass}>
              Create account
            </Link>
          </p>
          <Link href={ROUTES.helpSupport} className={linkClass}>
            Help
          </Link>
        </div>
      }
    >
      <form noValidate onSubmit={handleSubmit} className="flex flex-col gap-4">
        <Input
          label="Phone number"
          type="tel"
          inputMode="tel"
          autoComplete="tel"
          placeholder={authCopy.login.phoneHint}
          maxLength={16}
          value={phone}
          disabled={busy}
          onChange={(event) => {
            setPhone(event.target.value);
            clearError();
          }}
        />

        <div className="relative">
          <Input
            label="Password"
            type={passwordVisible ? 'text' : 'password'}
            autoComplete="current-password"
            placeholder={authCopy.login.passwordPlaceholder}
            value={password}
            disabled={busy}
            className="pr-14"
            onChange={(event) => {
              setPassword(event.target.value);
              clearError();
            }}
          />

          <IconButton
            label={passwordVisible ? 'Hide password' : 'Show password'}
            size="sm"
            disabled={busy}
            onClick={() => setPasswordVisible((visible) => !visible)}
            className="absolute right-2 top-8"
          >
            {passwordVisible ? (
              <EyeOff aria-hidden="true" className="size-4" />
            ) : (
              <Eye aria-hidden="true" className="size-4" />
            )}
          </IconButton>
        </div>

        {localError ? (
          <p role="alert" className="rounded-field bg-danger-soft px-3 py-2 text-sm text-danger">
            {localError}
          </p>
        ) : null}

        <Button type="submit" fullWidth loading={submitting} disabled={busy}>
          Log in
        </Button>

        <Button
          type="button"
          variant="secondary"
          fullWidth
          loading={otpSubmitting}
          disabled={busy}
          onClick={handleOtpLogin}
        >
          Log in with OTP
        </Button>
      </form>

      {demo ? (
        <Card className="mt-6 border-dashed border-brand" padding="md">
          <div className="flex flex-col gap-3">
            <h2 className="font-display text-sm font-semibold text-navy">
              {authCopy.demoCard.title}
            </h2>
            <p className="text-xs text-muted">{authCopy.demoCard.description}</p>

            <dl className="flex flex-col gap-1 text-xs">
              <div className="flex items-center justify-between gap-2">
                <dt className="text-muted">Phone</dt>
                <dd>
                  <code className="rounded bg-navy-soft px-2 py-0.5 font-mono text-navy">
                    {demo.phone}
                  </code>
                </dd>
              </div>
              <div className="flex items-center justify-between gap-2">
                <dt className="text-muted">Password</dt>
                <dd>
                  <code className="rounded bg-navy-soft px-2 py-0.5 font-mono text-navy">
                    {demo.password}
                  </code>
                </dd>
              </div>
            </dl>

            <Button
              type="button"
              variant="secondary"
              fullWidth
              loading={submitting}
              disabled={busy}
              onClick={handleDemoLogin}
            >
              {authCopy.demoCard.cta}
            </Button>
          </div>
        </Card>
      ) : null}
    </AuthShell>
  );
}
